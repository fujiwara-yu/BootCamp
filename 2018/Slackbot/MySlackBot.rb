# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'

class MySlackBot < SlackBot
  # cool code goes here
  def say_respond(params, options = {})
    text = params[:text].match(/「(.*)」と言って/)
    return {text: text[1]}.merge(options).to_json
 
   # return {text: text[1]}.to_json
  end

  def my_api_respond(params, options = {})
    
  end

end

slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
  content_type :json
  if (params[:text] =~ /「.*」と言って/) then
    slackbot.say_respond(params, username: "FBot")
  #elsif () then
    #My api method
  else
    slackbot.naive_respond(params, username: "FBot")
  end
end

