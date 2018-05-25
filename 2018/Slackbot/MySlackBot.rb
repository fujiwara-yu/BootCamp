# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'

BASE_URL_GEOCODE = "https://maps.google.com/maps/api/geocode/json"

BASE_URL_DIRECTIONS = "https://maps.googleapis.com/maps/api/directions/json"

class MySlackBot < SlackBot
  def say_respond(params, options = {})
    text = params[:text].match(/「(.*)」と言って/)

    return {text: text[1]}.merge(options).to_json
  end

  def address_to_geocode(address)
    address = URI.encode(address)
    hash = Hash.new
    reqUrl = "#{BASE_URL_GEOCODE}?address=#{address}&sensor=false&language=ja&key=" + @config["google_maps_api_key"]
    response = Net::HTTP.get_response(URI.parse(reqUrl))

    case response
    when Net::HTTPSuccess then
      data = JSON.parse(response.body)
      if (data['results'] == [])
        return nil
      end

      hash['lat'] = data['results'][0]['geometry']['location']['lat']
      hash['lng'] = data['results'][0]['geometry']['location']['lng']
    else
      ponse.error!
    end

    return hash
  end

  def distribute_transport(params)
    test = params[:text].match(/@FBot (.*)での.*から.*までの道/)
    if (test[1] == "徒歩") then
      return "walking"
    elsif (test[1] == "自動車") then
      return "driving"
    elsif (test[1] == "電車")
      return "transit"
    else
      return nil
    end
  end

  def get_route_info(params, options = {}, start, goal)
    mode = distribute_transport(params)
    if (mode == nil)
      return nil
    end

    hash = Hash.new
    hash['distance'] = 0
    hash['duration'] = 0
    reqUrl = "#{BASE_URL_DIRECTIONS}?origin=#{start['lat']},#{start['lng']}&destination=#{goal['lat']},#{goal['lng']}&language=ja&mode=#{mode}&key=" + @config["google_maps_api_key"]

    response = Net::HTTP.get_response(URI.parse(reqUrl))

    case response
    when Net::HTTPSuccess then
      data = JSON.parse(response.body)
      if (data['routes'] == []) then
        return nil
      end
      hash['distance'] = data['routes'][0]['legs'][0]['distance']['text']
      hash['duration'] = data['routes'][0]['legs'][0]['duration']['text']
    else
      hash['distance'] = 0
      hash['duration'] = 0
    end

    return hash
  end

  def distance_respond(params, options = {})
    test = params[:text].match(/@FBot .*での(.*)から(.*)までの道/)
    p test[1]
    p test[2]
    start = address_to_geocode(test[1])
    goal  = address_to_geocode(test[2])
    if (start == nil || goal == nil)
      return {text: "測定できませんでした"}.merge(options).to_json
    end

    route_info = get_route_info(params, options, start, goal)
    if (route_info == nil) then
      return {text: "交通手段は徒歩か自動車か電車を選んでください"}.merge(options).to_json
    elsif (route_info == nil) then
      return {text: "測定できませんでした"}.merge(options).to_json
    end

    mode = distribute_transport(params)

    map = "https://www.google.co.jp/maps/dir/?api=1&origin=#{start['lat']},#{start['lng']}&destination=#{goal['lat']},#{goal['lng']}&travelmode=#{mode}"

    text = "距離は#{route_info['distance']}\nかかる時間は#{route_info['duration']}\n" + "詳しい道は<#{map}|こちら>"

    return {text: text}.merge(options).to_json
  end

  def help_respond(params, options = {})
    return {text: "「〇〇」と言って or (移動手段)での(出発地点)から(到着地点)までの道"}.merge(options).to_json
  end

end

slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
  content_type :json
  params[:text]
  if (params[:text] =~ /「.*」と言って/) then
    slackbot.say_respond(params, username: "FBot")
  elsif (params[:text] =~ /.*での.*から.*までの道/) then
    #My api method
    slackbot.distance_respond(params, username: "FBot")
  else
    slackbot.help_respond(params, username: "FBot")
   # slackbot.naive_respond(params, username: "FBot")
  end
end

