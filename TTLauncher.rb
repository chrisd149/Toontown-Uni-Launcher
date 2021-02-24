=begin
Project: Toontown Unilauncher
Author: Christian Diaz
Description: An universal command-line launcher for several Toontown servers
Version: v1.0
License: Unilicense

This is my first Ruby project, please be nice :)
=end

require 'httparty'
require 'json'
require 'rbconfig'
require 'io/console'

puts "Welcome to the Universal Toontown launcher!"
puts "Ruby version: #{RUBY_VERSION}"

@os = RbConfig::CONFIG['host_os']
puts "OS: #{@os}"

case @os
when 'mingw32'  # Windows
    $clash_dir = ENV['APPDATA'] + "/../Local/Corporate Clash"
    $rewritten_dir = "c:/Program Files (x86)/Toontown Rewritten"
    $rewritten_start_file = "TTREngine.exe"
    $clash_start_file = "CorporateClash.exe"
  else          # Not Windows lol
    puts 'You are not on a supported platform. exiting...'
    exit_program
  end

class StartGame
    def start_login (user, pwsd)
        # Logins to user specifed game with username and password
        # 1 = TTR
        # 2 = TTCC
        case $GAME
        when 1
            url = "https://www.toontownrewritten.com/api/login?format=json"
            status = 'success'
        when 2
            url = "https://corporateclash.net/api/v1/login/"
            status = 'status'
        end

        # Sends intial POST request
        response = post_request(url, status, username: user.to_s, password: pwsd.to_s )
        response_status, response_json = response[0], response[1]
        
        case $GAME
        # Rewritten
        when 1
            # Rewritten's login sequence requires several POST requests, requiring a loop
            loop{
                # Updates response varriables
                response_status, response_json = response[0], response[1]

                case response_status.to_s
                # Runs game if request comes back successful
                when "true"
                    run_game response_json['gameserver'].to_s, response_json['cookie'].to_s
                    break

                # Sends another request with queueToken
                when "delayed"
                    response = post_request(url, status, queueToken: response_json['queueToken'])

                # Sends another request with 3rd party authentication token
                when "partial"
                    puts response_json['banner']  # Instructs user to enter authentication token
                    print "Enter: "
                    app_token = gets.chomp
                    response = post_request(url, status, appToken: app_token, authToken: response_json['responseToken'])

                # Alerts user if the request was not successful
                when "false"
                    puts response_json['banner']  # Instructs user on the failure
                    retry_login  # Returns back to login
                end
            }
        # Clash
        when 2
            # Runs game if request is successful
            if response_status.to_s == "true"
                puts response_json['friendlyreason'].to_s
                run_game "gs.corporateclash.net", response_json['token'].to_s

            # Informs user if request is unsuccessful
            else 
                puts response_json['friendlyreason'].to_s
                retry_login
            end
        end
    end

    def post_request (url, status, post_body = {})
        # POST request object
        response = HTTParty.post(url, body: post_body)

        case response.code
        # Success!
         when 200
            response_json = JSON.parse(response.body)
            response_status = response_json[status]
            return response_status, response_json

        # API can't be found
         when 404
            puts "The login API endpoint is unavailable at this time.  Steps to check:"
            puts "1. Check you are connected to the internet."
            puts "2. Test if the login endpoint is up, such as logging in with the offical launcher."
            puts "3. Determine if the specific API url is blocked by a DNS or router configuration."
            puts "If all steps above fail, create an issue on the Github repo (https://github.com/chrisd149/Toontown-Uni-Launcher)
            or contact me directly at https://github.com/chrisd149/Toontown-Uni-Launcher#contact"

        # Server is borked
           when 500...600
            puts "Login server had an internal failure, try logging in later."
            puts "ERROR CODE: #{response.code}"
            exit_program
        end
    end

    def run_game (gameserver, token)
        # Change working directory to game folder, and sets ENV vars
        case $GAME
        when 1
            Dir.chdir($rewritten_dir)
            ENV['TTR_GAMESERVER'] = gameserver
            ENV['TTR_PLAYCOOKIE'] = token
            puts "Changed directory to Rewritten game directory"
            start_file = $rewritten_start_file
            
        when 2
            Dir.chdir($clash_dir)
            ENV['TT_GAMESERVER'] = gameserver
            ENV['TT_PLAYCOOKIE'] = token
            puts "Changed directory to Clash game directory"
            start_file = $clash_start_file
        end

        # Starts game
        puts "Starting game..."
        system(start_file)
        retry_login
    end
end

def retry_login
    print "\nDo you want to retry logging in? (Y/N): "
    loop {
        case gets.chomp.upcase
        when "Y"
            get_user
            break
        when "N"
            exit_program
        else
            print "Wrong input, enter 'Y' to return to login or 'N' to exit the program: "
        end
    }
end

def get_user
    # User inputs
    puts "\nChoose your game:"
    puts "1 = TTR"
    puts "2 = TTCC"
    print "Enter: "
    $GAME = gets.to_i
    print "Enter username: "
    username = gets.chomp
    print "Enter password: "
    password = STDIN.noecho(&:gets).chomp
    print "\n"

    # Logins into game
    login = StartGame.new
    login.start_login(username, password)
end

def exit_program 
    # Exits program
    puts "\nSend any comments or concerns to me at https://github.com/chrisd149/Toontown-Uni-Launcher#contact or open an issue at https://github.com/chrisd149/Toontown-Uni-Launcher/issues/new."
    puts "Exiting now..."
    exit
end

get_user  # Starts program