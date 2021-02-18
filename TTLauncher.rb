require 'httparty'
require 'json'

puts "Welcome to the universal Toontown launcher!"

def login_clash (user, pwsd)
    response = HTTParty.post("https://corporateclash.net/api/v1/login/", body: { username: user.to_s, password: pwsd.to_s })
    response_json = JSON.parse(response.body)
    response_status = response_json['status']

    if response_status.to_s == "true"
        puts response_json['friendlyreason'].to_s
        run_clash response_json['token']
    else 
        puts response_json['friendlyreason'].to_s
        puts "Returning back to login..."
        get_user
    end
end

def run_clash (token)
    # Change working directory to Clash folder
    Dir.chdir(ENV['APPDATA'])
    Dir.chdir("..")
    Dir.chdir("Local/Corporate Clash")
    puts "Changed directory to Clash game directory"

    # Setting env varriables for game to run
    ENV['TT_GAMESERVER'] = "gs.corporateclash.net"
    ENV['TT_PLAYCOOKIE'] = token.to_s
    puts "Starting game..."

    # Start game
    exec('CorporateClash.exe')
end


def get_user
    # User inputs
    puts "Choose your game:"
    puts "1 = TTR"
    puts "2 = TTCC"
    print "Enter: "
    game = gets.chomp
    print "Enter username: "
    username = gets.chomp
    print "Enter password: "
    password = gets.chomp

    # Selects game to login into
    if game == '1'
        login_rewritten username, password
    elsif game == '2'
        login_clash username, password
    end
end

get_user