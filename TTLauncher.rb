# This is my first Ruby project, please be nice :)
require 'httparty'
require 'json'
require 'rbconfig'

@os = RbConfig::CONFIG['host_os']

# Global vars
$GAME

case @os
when 'mingw32'
    $CLASH_DIR = ENV['APPDATA'] + "/../Local/Corporate Clash"
    $REWRITTEN_DIR = "c:/Program Files (x86)/Toontown Rewritten"
    $REWRITTEN_START_FILE = "TTREngine.exe"
    $CLASH_START_FILE = "CorporateClash.exe"
  else
    puts 'You are not on a supported platform. exiting...'
    exit
  end

puts "Welcome to the universal Toontown launcher!"

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

                # Runs game if request comes back successful
                if response_status.to_s == "true"
                    run_game response_json['gameserver'], response_json['cookie']
                    break
                # Sends another request with queueToken
                elsif response_status.to_s == "delayed"
                    response = post_request(url, status, queueToken: response_json['queueToken'])
                # Sends another request with 3rd party authentication token
                elsif response_status.to_s == "partial"
                    puts response_json['banner']  # Instructs user to enter authentication token
                    app_token = gets.chomp
                    response = post_request(url, status, appToken: app_token, authToken: response_json['responseToken'])
                # Alerts user if the request was not successful
                elsif response_status.to_s == "false"
                    puts response_json['banner']  # Instructs user on the failure
                    retry_login  # Returns back to login
                end
            }
        # Clash
        when 2
            # Runs game if request is successful
            if response_status.to_s == "true"
                puts response_json['friendlyreason'].to_s
                run_game "gs.corporateclash.net", response_json['token']
            # Informs user if request is unsuccessful
            else 
                puts response_json['friendlyreason'].to_s
                retry_login
            end
        end
    end

    def post_request (url, status, post_body = {})
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
            or contact me directly at https://github.com/chrisd149/Toontown-Uni-Launche#contact"
        # Server is borked
           when 500...600
            puts "Login server had an internal failure, try logging in later."
            puts "ERROR CODE: #{response.code}"
        end
    end

    def run_game (gameserver, token)
        # Change working directory to game folder, and sets ENV vars
        case $GAME
        when 1
            Dir.chdir($REWRITTEN_DIR)
            ENV['TTR_GAMESERVER'] = gameserver.to_s
            ENV['TTR_PLAYCOOKIE'] = token.to_s
            puts "Changed directory to Rewritten game directory"
            
            # Start game
            puts "Starting game..."
            exec($REWRITTEN_START_FILE)
        when 2
            Dir.chdir($CLASH_DIR)
            ENV['TT_GAMESERVER'] = gameserver.to_s
            ENV['TT_PLAYCOOKIE'] = token.to_s
            puts "Changed directory to Clash game directory"
            
            # Start game
            puts "Starting game..."
            exec($CLASH_START_FILE)
        end
    end
end

def retry_login
    print "Do you want to retry logging in? (Y/N): "
    loop {
        case gets.chomp.upcase
        when "Y"
            get_user
            break
        when "N"
            exit
        else
            puts "Wrong input, enter 'Y' to return to login or 'N' to exit the program: "
        end
    }
end

def get_user
    # User inputs
    puts "Choose your game:"
    puts "1 = TTR"
    puts "2 = TTCC"
    print "Enter: "
    $GAME = gets.to_i
    print "Enter username: "
    username = gets.chomp
    print "Enter password: "
    password = gets.chomp

    # Logins into game
    login = StartGame.new
    login.start_login(username, password)
end

get_user