class FrankController < ApplicationController
require 'line/bot'
require "exchange_rate"
require "json"
require 'net/https'

protect_from_forgery with: :null_session 
def request_headers
    render plain: request.headers.to_h.reject{ |key, value|
      key.include? '.'
      }.map{ |key, value|
        "#{key}: #{value}"
      }.sort.join("\n")
end


def webhook
#回傳line資訊
reply_text = get_ID(received_text)
response = reply_to_line(reply_text)
head :ok
#爬蟲爬匯率
reply_text = get_rate(received_text)
response = reply_to_line(reply_text)
head :ok
#玉山銀行
reply_text = bank(received_text)
response = reply_to_line(reply_text)
head :ok
#日換台
reply_text = transJN(received_text)
response = reply_to_line(reply_text)
head :ok
#台換日
reply_text = transNJ(received_text)
response = reply_to_line(reply_text)
head :ok
#美換台
reply_text = transAN(received_text)
response = reply_to_line(reply_text)
head :ok
#台換美
reply_text = transNA(received_text)
response = reply_to_line(reply_text)
head :ok
#爬蟲人民幣
reply_text = get_rate_CNY(received_text)
response = reply_to_line(reply_text)
head :ok
#爬蟲美金
reply_text = get_rate_USD(received_text)
response = reply_to_line(reply_text)
head :ok
=begin
#回報
reply_text = get_map(received_text)
response = reply_location_to_line(reply_text)
head :ok
=end

#新增關鍵字 指令
  reply_text = my_keyword(received_text)
  response = reply_to_line(reply_text)
  head :ok

#新增功能 抽
reply_image = get_imgur(received_text)
unless reply_image.nil?
  response = reply_image_to_line(reply_image)
  head :ok 
  return 
end


#新增功能 抽動漫
reply_image = get_imgur_anime(received_text)
unless reply_image.nil?
  response = reply_image_to_line(reply_image)
  head :ok 
  return 
end


reply_carousel_template = get_carousel_template(received_text)
unless reply_carousel_template.nil?
  response = reply_carousel_template_to_line(reply_carousel_template)
  head :ok
  return
end

# 學說話
  reply_text = learn(received_text)
# 關鍵字回覆
  reply_text = keyword_reply(received_text) if reply_text.nil?
# 傳送訊息到 line
  response = reply_to_line(reply_text)
    # 回應 200
  head :ok
  end 

#回傳當前使用者、群組ID
def get_ID(received_text)
  return nil unless received_text.downcase =="return"
  line_source = params['events'][0]['source']
  #回傳的東西
  "group ID:#{line_source['groupId']}\nroom ID:#{line_source['roomId']}\nUser ID:#{line_source['userId']}"
end


def get_imgur_anime(received_text)
  return nil unless received_text == '油'
  #使用imgur的API
  url = URI("https://api.imgur.com/3/album/pfTWwrj/images")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(url)
  request["authorization"] = 'Client-ID [your imgur ID]'
  response = http.request(request)
  #抓取後他會回傳json格式，用json解析後，抓取他的array[data]
  json = JSON.parse(response.read_body)
  #Random圖片
  json_length = json['data'].count-1
  r=Random.new.rand(0..json_length)
  begin
    #return json
    json['data'][r]['link'].gsub("http:","https:")
  rescue
    nil
  end
end



#取得圖片
def get_imgur(received_text)
  return nil unless received_text == '抽'
  
  #使用imgur的API
  url = URI("https://api.imgur.com/3/album/NlFQ6h7/images")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(url)
  request["authorization"] = 'Client-ID [your imgur ID]'
  response = http.request(request)
  json = JSON.parse(response.read_body)
  json_length = json['data'].count-1
  r=Random.new.rand(0..json_length)
  begin
    json['data'][r]['link'].gsub("http:","https:")
  rescue
    nil
  end
end



#取得天氣
def get_weather(received_text)
  return nil unless received_text.include? '天氣'
  upload_to_imgur(get_weather_from_cwb)
end
  
def get_weather_from_cwb
  require 'net/https'
  uri = URI('https://www.cwb.gov.tw/V7/js/HDRadar_1000_n_val.js')
  response = Net::HTTP.get(uri)
  start_index = response.index('","') + 3
  end_index = response.index('"),') - 1
  "https://www.cwb.gov.tw" + response[start_index..end_index]
end

#上傳圖片
def upload_to_imgur(image_url)
  require 'net/https'
  url = URI("https://api.imgur.com/3/image")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(url)
  request["authorization"] = 'Client-ID [your imgur ID]'
#回傳image
  request.set_form_data({"image" => image_url})
  response = http.request(request)
  json = JSON.parse(response.read_body)
  begin
    #return json
    json['data']['link'].gsub("http:","https:")
  rescue
    nil
  end
end

def reply_image_to_line(reply_image)
  return nil if reply_image.nil?
  
  # 取得 reply token
  reply_token = params['events'][0]['replyToken']
  
  # 設定回覆訊息
  message = {
    type: "image",
    originalContentUrl: reply_image,
    previewImageUrl: reply_image
  }

  # 傳送訊息
  line.reply_message(reply_token, message)
end

# 取得對方說的話
def received_text
  message = params['events'][0]['message']
  message['text'] unless message.nil?
end

def forget(received_text)
    return nil unless received_text[0..2] == '忘記;'
    received_text = received_text[3..-1]
    semicolon_index = received_text.index(';')
    return nil if semicolon_index.nil?

    keyword = received_text[0..semicolon_index-1]
    KeywordMapping.delete(keyword: keyword)
    line_source = params['events'][0]['source']
    #回傳的東西
    response = line.get_profile(line_source['userId'])
    contact = JSON.parse(response.body)
    #contact['displayName']
    "好Der，#{contact['displayName']}"
end

def learn(received_text)
#判斷開頭一定要是學習;     ;←為半形  後來修正為空白
return nil unless received_text[0..2] == '學習 '

received_text = received_text[3..-1]
semicolon_index = received_text.index(' ')

# 找不到空白就跳出
return nil if semicolon_index.nil?

keyword = received_text[0..semicolon_index-1]
message = received_text[semicolon_index+1..-1]

KeywordMapping.create(keyword: keyword, message: message)
line_source = params['events'][0]['source']
#回傳的東西
response = line.get_profile(line_source['userId'])
contact = JSON.parse(response.body)
"好Der，#{contact['displayName']}"
end

#從台灣銀行取得當前美金
def get_rate_USD(received_text)
  return nil unless received_text =='美金' 
  now_Rate = TaiwanBank.get_US
 " 美金\n本行現金買入:#{now_Rate[:cash_buy_rate]}\n本行現金賣出:#{now_Rate[:cash_sell_rate]}\n本行即期買入:#{now_Rate[:buying_rate]}\n*本行即期賣出:#{now_Rate[:selling_rate]}"
end

def get_rate_CNY(received_text)
 return nil unless received_text =='人民幣' 
 now_Rate = TaiwanBank.get_CN
 " 人民幣\n本行現金買入:#{now_Rate[:cash_buy_rate]}\n本行現金賣出:#{now_Rate[:cash_sell_rate]}\n本行即期買入:#{now_Rate[:buying_rate]}\n*本行即期賣出:#{now_Rate[:selling_rate]}"
end

#呼叫玉山銀行的日幣Rate
def bank(received_text)
  return nil unless received_text == '*日圓' ||received_text == '*日幣' #呼叫日圓匯回傳
  now_Rate = ESun.get_JP
"日圓\n玉山銀行現金買入:#{now_Rate[:cash_buy_rate]}\n玉山銀行現金賣出:#{now_Rate[:cash_sell_rate]}\n玉山優惠買入匯率:#{now_Rate[:buying_best_rate]}\n玉山優惠賣出匯率:#{now_Rate[:selling_best_rate]}\n玉山銀行即期買入:#{now_Rate[:buying_rate]}\n玉山銀行即期賣出:#{now_Rate[:selling_rate]}"
end

#呼叫爬蟲功能，爬台銀匯率
def get_rate(received_text)
  return nil unless received_text == '日圓' ||received_text == '日幣' #呼叫日圓匯回傳
  now_Rate = TaiwanBank.get_JP
  " 日幣\n本行現金買入:#{now_Rate[:cash_buy_rate]}\n本行現金賣出:#{now_Rate[:cash_sell_rate]}\n本行即期買入:#{now_Rate[:buying_rate]}\n*本行即期賣出:#{now_Rate[:selling_rate]}"

end

def transAN(received_text)
  return nil unless received_text[0..2] == '美換台'
  semicolon_index = received_text.index(' ')
  # 找不到空白就跳出
  return nil if semicolon_index.nil?
  money = received_text[semicolon_index+1..-1]

"美金#{money} = 台幣 #{TaiwanBank.Exchange_US_TO_TW(money.to_i)}"

end

def transNA(received_text)
  return nil unless received_text[0..2] == '台換美'
  semicolon_index = received_text.index(' ')

  # 找不到空白就跳出
  return nil if semicolon_index.nil?
  money = received_text[semicolon_index+1..-1]
  "美金#{money} = 台幣 #{TaiwanBank.Exchange_US_TO_TW(money.to_i)}"
end



#日幣換成台幣
def transJN(received_text)
  return nil unless received_text[0..2] == '日換台'
  semicolon_index = received_text.index(' ')
  # 找不到空白就跳出
  return nil if semicolon_index.nil?
  money = received_text[semicolon_index+1..-1]
  "日幣#{money} = 台幣 #{TaiwanBank.Exchange_JP_TO_TW(money.to_i)}"
end

#台幣換成日幣
def transNJ(received_text)
  return nil unless received_text[0..2] == '台換日'
  semicolon_index = received_text.index(' ')
  # 找不到空白就跳出
  return nil if semicolon_index.nil?
  money = received_text[semicolon_index+1..-1]
  "台幣#{money} = 日幣 #{TaiwanBank.Exchange_TW_TO_JP(money.to_i)}"
end

#定義一些關鍵字
def my_keyword(received_text)
return nil unless received_text.include? '指令'  #只要對話內容有"指令"關鍵字
'目前指令有 "學習 東西A 東西B" ， 以及 "日本行"，"日幣、日圓、人民幣" '
end

# 關鍵字回覆
def keyword_reply(received_text)
  # 學習紀錄表
  KeywordMapping.where(keyword: received_text).last&.message
end


def get_map(received_text)
  return nil unless received_text == '回報'
  line_source = params['events'][0]['source']
  #回傳的東西
  response = line.get_profile(line_source['userId'])
  contact = JSON.parse(response.body)
  contact['displayName']
end

# 傳送訊息到 line
def reply_to_line(reply_text)
  return nil if reply_text.nil?
  
  # 取得 reply token
  reply_token = params['events'][0]['replyToken']
  
  # 設定回覆訊息
  message = {
    type: 'text',
    text: reply_text
  } 

  # 傳送訊息
  line.reply_message(reply_token, message)
end


#這邊是我line的資料 千萬不要動
def line
  @line ||= Line::Bot::Client.new { |config|
    config.channel_secret = '[your secret ]'
    config.channel_token = '[your token]'
  }
end

end