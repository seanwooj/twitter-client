require 'oauth'
require 'addressable/uri'
require 'launchy'
require 'json'

class TwitterClient
  attr_reader :access_token
  CONSUMER_KEY = "GtlvQRLPpp5L5siC7p7tVw"
  CONSUMER_SECRET = "37yzEyZiRM7fAMbIKuaNbN9bbnOV3ID5jxdgoMbs"
  CONSUMER = OAuth::Consumer.new( CONSUMER_KEY, CONSUMER_SECRET, {
    :site               => "https://api.twitter.com",
    :scheme             => :header,
    :http_method        => :post,
    :request_token_path => "/oauth/request_token",
    :access_token_path  => "/oauth/access_token",
    :authorize_path     => "/oauth/authorize"
  })

  def initialize
    ## Let's assume that all of our methods will just implicitly call
    ## this access token (without being passed as an argument)
    @access_token = load_token("access.token")
    run_loop
  end

  def load_token(token_file)
    # We can serialize token to a file, so that future requests don't need
    # to be reauthorized.

    if File.exist?(token_file)
      File.open(token_file) { |f| YAML.load(f) }
    else
      access_token = get_access_token
      File.open(token_file, "w") { |f| YAML.dump(access_token, f) }

      access_token
    end
  end

  def get_access_token
    request_token = CONSUMER.get_request_token
    puts "Go to this URL #{request_token.authorize_url}"
    puts "Login, and type your verification code in"
    Launchy.open(request_token.authorize_url)
    oauth_verifier = gets.chomp
    access_token = request_token.get_access_token( :oauth_verifier => oauth_verifier )
  end

  def run_loop
    help
    while true
      print "Enter your command > "
      user_input = get_user_input
      case user_input[:command]
      when "t"
        send_tweet(user_input[:message])
      when "dm"
        send_tweet("d "+user_input[:message])
      when "tl"
        print_timeline(get_timeline)
      when "f"
        print_timeline(get_friend_statuses(user_input[:message]))
      when "q"
        puts "Thanks for using me!"
        return
      when "help" || "h"
        help
      else
        puts "Gimme valid input... or cookies"
        next
      end
    end
  end

  def help
    100.times { puts }
    puts "Welcome to SUPER MEGA TWITTER CLIENT MONDO THING"
    puts "(t)weet [message]"
    puts "(dm) [user] [message]"
    puts "(tl) - displays your timeline"
    puts "(f)riend's status [username]"
    puts "(q)uit"
  end

  def make_address(endpoint, query_values=nil)
    address = Addressable::URI.new( # file with the data you requested and assigns it to @results
      :scheme => "https",
      :host => "api.twitter.com",
      :path => "1.1/statuses/#{endpoint}.json",
      :query_values => query_values
    ).to_s
    puts address
    address
  end

  def get_user_input
    input = gets.chomp
    command = input.split[0].downcase
    message = input.split[1..-1].join(" ")
    user_input = {
      :command => command, 
      :message => message
    }
  end

  def send_tweet(message)
    @access_token.post(make_address("update"), { :status => message })
    puts "Yo tweet got sent, yo."
  end

  def get_timeline
    unparsed = @access_token.get(make_address("home_timeline")).body
    JSON::parse(unparsed)
  end

  def get_friend_statuses(friend)
    unparsed = @access_token.get(make_address("user_timeline" , { :screen_name => friend })).body
    JSON::parse(unparsed)
  end

  def print_timeline(timeline_hash)
    timeline_hash.each { |tweet| puts tweet["user"]["name"] + " - " + tweet["created_at"] + " : " + tweet["text"] }
  end

  def dm(friend, message)
    send_tweet("d #{friend} #{message}")
  end

end
