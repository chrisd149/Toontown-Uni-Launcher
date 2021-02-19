# This is my first Ruby project, please be nice :)
require 'httparty'
require 'json'

CLASH_DIR = "../Local/Corporate Clash"
REWRITTEN_DIR = "c:/Program Files (x86)/Toontown Rewritten"

puts "Welcome to the universal Toontown launcher!"

def post_request (url, status, post_body = {})
    response = HTTParty.post(url, body: post_body)
    response_json = JSON.parse(response.body)
    response_status = response_json[status]
    return response_status, response_json
end

def login (game, user, pwsd)
    # Logins to user specifed game with username and password
    if game == 1
        url = "https://www.toontownrewritten.com/api/login?format=json"
        status = 'success'
    elsif game == 2
        url = "https://corporateclash.net/api/v1/login/"
        status = 'status'
    end

    puts url, status

    # Sends intial POST request
    response = post_request(url, status, username: user.to_s, password: pwsd.to_s )
    response_status, response_json = response[0], response[1]

    # Rewritten
    if game == 1
        loop{
            # Updates response varriables
            response_status, response_json = response[0], response[1]

            # Runs game if request comes back successful
            if response_status.to_s == "true"
                run_game 1, response_json['gameserver'], response_json['cookie']
                break
            # Sends another request with queueToken
            elsif response_status.to_s == "delayed"
                response = post_request(url, status, queueToken: response_json['queueToken'])
            # Sends another request with 3rd party authentication token
            elsif response_status.to_s == "partial"
                print response_json['banner']  # Instructs user to enter authentication token
                app_token = gets.chomp
                response = post_request(url, status, appToken: app_token, authToken: response_json['responseToken'])
            # Alerts user if the request was not successful
            elsif response_status.to_s == "false"
                print response_json['banner']  # Instructs user on the failure
                login  # Returns back to login
            end
        }
    # Clash
    elsif game == 2
        puts response_json.to_s
        # Runs game if request is successful
        if response_status.to_s == "true"
            puts response_json['friendlyreason'].to_s
            run_game 2, "gs.corporateclash.net", response_json['token']
        # Informs user if request is unsuccessful
        else 
            puts response_json['friendlyreason'].to_s
            puts "Returning back to login..."
            get_user
        end
    end
end

def run_game (game, gameserver, token)
    # Change working directory to game folder, and sets ENV vars
    if game == 1
        Dir.chdir(REWRITTEN_DIR)
        ENV['TTR_GAMESERVER'] = gameserver.to_s
        ENV['TTR_PLAYCOOKIE'] = token.to_s
        puts "Changed directory to Rewritten game directory"
    elsif game == 2
        Dir.chdir(ENV['APPDATA'])
        Dir.chdir(CLASH_DIR)
        ENV['TT_GAMESERVER'] = gameserver.to_s
        ENV['TT_PLAYCOOKIE'] = token.to_s
        puts "Changed directory to Clash game directory"
    end

    # Start game
    puts "Starting game..."
    if game == 1
        exec("TTREngine.exe")
    elsif game == 2
        exec("CorporateClash.exe")
    end
end


def get_user
    # User inputs
    puts "Choose your game:"
    puts "1 = TTR"
    puts "2 = TTCC"
    print "Enter: "
    game = gets.to_i
    print "Enter username: "
    username = gets.chomp
    print "Enter password: "
    password = gets.chomp

    # Logins into game
    login game, username, password
end

get_user