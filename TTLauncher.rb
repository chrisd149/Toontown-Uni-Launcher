require 'httparty'
require 'json'

CLASH_DIR = ENV['APPDATA'] + "../Local/Corporate Clash"
REWRITTEN_DIR = "c:/Program Files (x86)/Toontown Rewritten"

puts "Welcome to the universal Toontown launcher!"

def post_request (post_body = {})
    response = HTTParty.post(url, body: post_body)
    response_json = JSON.parse(response.body)
    response_status = response_json[status]
    return response_status
end

def login (game, user, pwsd)
    if game == 1
        url = "https://www.toontownrewritten.com/api/login?format=json"
        status = 'success'
    if game == 2
        url = "https://corporateclash.net/api/v1/login/"
        status = 'status'
    end

    response_status = post_request(username: user.to_s, password: pwsd.to_s )
    
    if game = 2
        if response_status.to_s == "true"
            puts response_json['friendlyreason'].to_s
            run_game 2, "gs.corporateclash.net", response_json['token']
        else 
            puts response_json['friendlyreason'].to_s
            puts "Returning back to login..."
            get_user
        end
    elsif game = 1
        loop{
            if response_status.to_s == "true"
                run_game 1, response_json['gameserver'], response_json['cookie']
                break
            elsif response_status.to_s == "delayed"
                response_status =post_request(queueToken: response_json['queueToken'])
            elsif response_status.to_s == "partial"
                puts "lol you screwed lol"
            end
        }
    end
end

def run_game (game, gameserver, token)
    # Change working directory to game folder
    if game == 1
        GAME_EXE = "TTREngine.exe"
        Dir.chdir(REWRITTEN_DIR)
        puts "Changed directory to Rewritten game directory"
    elsif game == 2
        GAME_EXE = "CorporateClash.exe"
        Dir.chdir(CLASH_DIR)
        puts "Changed directory to Clash game directory"
    end
    # Setting env varriables for game to run
    ENV['TT_GAMESERVER'] = game.to_s
    ENV['TT_PLAYCOOKIE'] = token.to_s
    puts "Starting game..."

    # Start game
    exec(GAME_EXE)
end


def get_user
    # User inputs
    puts "Choose your game:"
    puts "1 = TTR"
    puts "2 = TTCC"
    print "Enter: "
    game = gets.to_i
    print "Enter username: "
    username = gets.to_i
    print "Enter password: "
    password = gets.chomp

    # Logins into game
    login game, username, password
end

get_user