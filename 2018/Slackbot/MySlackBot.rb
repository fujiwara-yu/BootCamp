# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'

class MySlackBot < SlackBot
  # cool code goes here
  def say_respond(params, username: Bot)
    text = params[:text].match(/「(.*)」と言って/)
    
    return {text: #{text}}.merge(option).to_json
  end
end

slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
  content_type :json
  if (prams[:text] =~ /「.*」と言って/) then
    slackbot.respond(params, username: "FBot")
  elsif () then
    #My api method
  else
    slackbot.naive_respond(params, username: "FBot")
  end
end
