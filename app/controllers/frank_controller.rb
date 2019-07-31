class FrankController < ApplicationController
require 'line/bot'
require "nokogiri"
require "json"
    protect_from_forgery with: :null_session 
    def request_headers
        render plain: request.headers.to_h.reject{ |key, value|
        key.include? '.'
      }.map{ |key, value|
        "#{key}: #{value}"
      }.sort.join("\n")
end

def request_body
    render plain: request.body
end


def response_headers
    response.headers['志偉']='母湯'
    render plain:response.headers.to_h.map{|key,value|
"#{key}:#{value}"
}.sort.join("\n")
end

def show_response_body
    puts "中斷點"
    render plain:response.body
end

def sent_request
    require 'net/http'
    uri = URI('http://localhost:3000/frank/eat')
    http = Net::HTTP.new(uri.host, uri.port)
    http_request  = Net::HTTP::Get.new(uri)
    http_response = http.request(http_request)
    render plain: JSON.pretty_generate({
        request_class: request.class,
        response_class: response.class,
        http_request_class: http_request.class,
        http_response_class: http_response.class
      })
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

#新增功能 抽抽
reply_image = get_imgur(received_text)
unless reply_image.nil?
  response = reply_image_to_line(reply_image)
  head :ok 
  return 
end

#新增功能 十連抽



#新增功能 抽動漫
reply_image = get_imgur_anime(received_text)
unless reply_image.nil?
  response = reply_image_to_line(reply_image)
  head :ok 
  return 
end

#新增功能 看片


reply_carousel_template = get_carousel_template(received_text)
unless reply_carousel_template.nil?
  response = reply_carousel_template_to_line(reply_carousel_template)
  head :ok
  return
end

    # 學說話
    reply_text = learn(received_text)
    #reply_text = forget(received_text)
    # 關鍵字回覆
    reply_text = keyword_reply(received_text) if reply_text.nil?
    # 傳送訊息到 line
    response = reply_to_line(reply_text)
    # 回應 200
    head :ok
  end 

def get_ID(received_text)
  return nil unless received_text.downcase =="return"
  line_source = params['events'][0]['source']
  #回傳的東西
  "group ID:#{line_source['groupId']}\nroom ID:#{line_source['roomId']}\nUser ID:#{line_source['userId']}"
end


def get_imgur_anime(received_text)
  return nil unless received_text == '油'

  #下面為要回傳的東西，回傳東西必須為 XXXX.png
  require 'net/https'
  #使用imgur的API
  url = URI("https://api.imgur.com/3/album/pfTWwrj/images")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(url)
  request["authorization"] = 'Client-ID bd1056a141e8e03'
  response = http.request(request)
  #抓取後他會回傳json格式，用json解析後，抓取他的array[data]
  json = JSON.parse(response.read_body)
  #-1是因為array 從0開始最後端需要做count-1的動作
  json_length = json['data'].count-1
  #撒網
  r=Random.new.rand(0..json_length)
  begin
    #最後以json拋
    json['data'][r]['link'].gsub("http:","https:")
  rescue
    nil
  end
end



def get_carousel_template(received_text)
  return nil unless received_text == '日本行'
   'test string'
end
  #取得圖片
  def get_imgur(received_text)
    return nil unless received_text == '抽'
    

    #下面為要回傳的東西，回傳東西必須為 XXXX.png
    require 'net/https'
    #使用imgur的API
    url = URI("https://api.imgur.com/3/album/NlFQ6h7/images")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["authorization"] = 'Client-ID bd1056a141e8e03'
    response = http.request(request)
    #抓取後他會回傳json格式，用json解析後，抓取他的array[data]
    json = JSON.parse(response.read_body)
    #-1是因為array 從0開始最後端需要做count-1的動作
    json_length = json['data'].count-1
    #撒網
    r=Random.new.rand(0..json_length)
    begin
      #最後以json拋
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
  #抓天氣圖，這邊傳超慢，不知道為啥，可能是我有上傳到imgur
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
    #這是我的Client-ID，沒事別亂動
    request["authorization"] = 'Client-ID bd1056a141e8e03'
#回傳image
    request.set_form_data({"image" => image_url})
    response = http.request(request)
    json = JSON.parse(response.read_body)
    begin
      #最後以json拋
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
#召喚美金
def get_rate_USD(received_text)
  return nil unless received_text =='美金' #呼叫阿6
  require "nokogiri"
   require 'open-uri'
   url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"
   html = Nokogiri::HTML(open(url))
   datetime = html.css("span.time").text
   tableRows = html.css("table > tbody > tr")
 
 rates = {
   update: datetime,
   results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
 }
 rates= rates.to_json
 json = JSON.parse(rates)
 "#{json['update']} 美金\n本行現金買入:#{json['results']['USD']['cash_buy_rate']}\n本行現金賣出:#{json['results']['USD']['cash_sell_rate']}\n本行即期買入:#{json['results']['USD']['buying_rate']}\n*本行即期賣出:#{json['results']['USD']['selling_rate']}"
end

def get_rate_CNY(received_text)
 return nil unless received_text =='人民幣' #呼叫阿6
 require "nokogiri"
  require 'open-uri'
  url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"
  html = Nokogiri::HTML(open(url))
  datetime = html.css("span.time").text
  tableRows = html.css("table > tbody > tr")

rates = {
  update: datetime,
  results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
}
rates= rates.to_json
json = JSON.parse(rates)
"#{json['update']} 人民幣\n本行現金買入:#{json['results']['CNY']['cash_buy_rate']}\n本行現金賣出:#{json['results']['CNY']['cash_sell_rate']}\n本行即期買入:#{json['results']['CNY']['buying_rate']}\n*本行即期賣出:#{json['results']['CNY']['selling_rate']}"
end

def bank(received_text)
  return nil unless received_text == '*日圓' ||received_text == '*日幣' #呼叫日圓匯回傳
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  url = "https://www.esunbank.com.tw/bank/personal/deposit/rate/forex/foreign-exchange-rates"#玉山網址

  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span[@id = LbQuoteTime]").text #他的套件
  tableRows = html.css("table > tr > td") 

rates = {
  update: datetime,  #自定義一個變數名稱為update抓取上面所設定的datetime
  result:  parseNode_Mountain(tableRows)
}
temp = parseNode_Mountain(tableRows)
rates = rates.to_json
json = JSON.parse(rates)
"#{json['update']} 日圓\n玉山銀行現金買入:#{json['result']['cash_buy_rate']}\n玉山銀行現金賣出:#{json['result']['cash_sell_rate']}\n玉山優惠買入匯率:#{json['result']['buying_best_rate']}\n玉山優惠賣出匯率:#{json['result']['selling_best_rate']}\n玉山銀行即期買入:#{json['result']['buying_rate']}\n玉山銀行即期賣出:#{json['result']['selling_rate']}"
end

#呼叫爬蟲功能，爬台銀匯率
def get_rate(received_text)
  return nil unless received_text == '日圓' ||received_text == '日幣' #呼叫日圓匯回傳
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"#台銀網址
  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span.time").text #他的套件
  tableRows = html.css("table > tbody > tr") 
#reduce(initial) { |memo, obj| block } → obj
#results為tableRows.reduce在這個tableRows裡面做重複的動作，也就說抓有幾個幣值，並且給他戴上套套{}，
#後自訂兩個變數accunulator和node，accumulator使用merge(hash)方式讓他結合"aaa"=>"bbb"的形式
#bbb指的是parseNode，也就是下方跑的function parseNode
rates = {
  update: datetime,  #自定義一個變數名稱為update抓取上面所設定的datetime
  results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
}

rates= rates.to_json
json = JSON.parse(rates)
"#{json['update']} 日圓\n本行現金買入:#{json['results']['JPY']['cash_buy_rate']}\n本行現金賣出:#{json['results']['JPY']['cash_sell_rate']}\n本行即期買入:#{json['results']['JPY']['buying_rate']}\n*本行即期賣出:#{json['results']['JPY']['selling_rate']}"

end

def parseNode_Mountain(node)
  name = node.css("td[data-name=外幣類型]")[3].text
  symbol = name.match(/[A-Z]+/).to_s
  temp_str = "網路銀行/App優惠匯率買入匯率"
  rates = {
    cash_buy_rate:node.css("td[data-name=即期買入匯率]")[3].text,
    cash_sell_rate: node.css("td[data-name=即期賣出匯率]")[3].text,
    buying_rate: node.css("td[data-name=現金買入匯率]")[3].text,
    selling_rate: node.css("td[data-name=現金賣出匯率]")[3].text,
    buying_best_rate: node.css("td[data-name]")[24].text,
    selling_best_rate: node.css("td[data-name]")[25].text,
    name: name.strip
  }
  return rates
  
end

def parseNode(node)
  name = node.css("div.print_show").text #詳情問問台銀
  symbol = name.match(/[A-Z]+/).to_s #指的是我要抓全部，這邊是幣值的代碼，ex:JPY
#rates抓東西
  rates = {
  cash_buy_rate: node.css("td[data-table=本行現金買入]")[0].text,
  cash_sell_rate: node.css("td[data-table=本行現金賣出]")[0].text,
  buying_rate: node.css("td[data-table=本行即期買入]")[0].text,
  selling_rate: node.css("td[data-table=本行即期賣出]")[0].text,
  name: name.strip
}
data = { symbol.to_sym => rates }

end

def transAN(received_text)
  return nil unless received_text[0..2] == '美換台'
  semicolon_index = received_text.index(' ')

  # 找不到空白就跳出
  return nil if semicolon_index.nil?

  money = received_text[semicolon_index+1..-1]

  #取得即期匯率
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  
  url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"#台銀網址
  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span.time").text #他的套件
  tableRows = html.css("table > tbody > tr") 
rates = {
  results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
}
rates= rates.to_json
json = JSON.parse(rates)
begin
  if money.to_i!=0
"美金#{money} = 台幣 #{(money.to_i*json['results']['USD']['cash_buy_rate'].to_f).round(2)}\n當前現金匯率為#{json['results']['USD']['cash_buy_rate']}"
  else
"請輸入可以識別或是非零的數字"
  end
rescue
"發生錯誤"
end
end

def transNA(received_text)
  return nil unless received_text[0..2] == '台換美'
  semicolon_index = received_text.index(' ')

  # 找不到空白就跳出
  return nil if semicolon_index.nil?

  money = received_text[semicolon_index+1..-1]

  #取得即期匯率
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  
  url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"#台銀網址
  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span.time").text #他的套件
  tableRows = html.css("table > tbody > tr") 
rates = {
  results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
}
rates= rates.to_json
json = JSON.parse(rates)
begin
  if money.to_i!=0
"台幣#{money} = 美金 #{(money.to_i/json['results']['USD']['cash_sell_rate'].to_f).round(2)}\n當前現金匯率為#{json['results']['USD']['cash_sell_rate']}"
  else
"請輸入可以識別或是非零的數字"
  end
rescue
"發生錯誤"
end
end



#日幣換成台幣
def transJN(received_text)
  return nil unless received_text[0..2] == '日換台'
  semicolon_index = received_text.index(' ')

  # 找不到空白就跳出
  return nil if semicolon_index.nil?

  money = received_text[semicolon_index+1..-1]

  #取得即期匯率
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  
  url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"#台銀網址
  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span.time").text #他的套件
  tableRows = html.css("table > tbody > tr") 
rates = {
  results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
}
rates= rates.to_json
json = JSON.parse(rates)
begin
  if money.to_i!=0
"日幣#{money} = 台幣 #{(money.to_i*json['results']['JPY']['cash_buy_rate'].to_f).round(2)}\n當前現金匯率為#{json['results']['JPY']['cash_buy_rate']}"
  else
"請輸入可以識別或是非零的數字"
  end
rescue
"發生錯誤"
end
end

#台幣換成日幣
def transNJ(received_text)
  return nil unless received_text[0..2] == '台換日'
  semicolon_index = received_text.index(' ')

  # 找不到空白就跳出
  return nil if semicolon_index.nil?

  money = received_text[semicolon_index+1..-1]

  #取得即期匯率
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  
  url = "https://rate.bot.com.tw/xrt?Lang=zh-TW"#台銀網址
  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span.time").text #他的套件
  tableRows = html.css("table > tbody > tr") 
rates = {
  results: tableRows.reduce({}) { |accumulator, node| accumulator.merge parseNode(node) }
}
rates= rates.to_json
json = JSON.parse(rates)
begin
  if money.to_i!=0
"台幣#{money} = 日幣 #{(money.to_i/json['results']['JPY']['cash_sell_rate'].to_f).round(2)}\n當前現金匯率為#{json['results']['JPY']['cash_sell_rate']}"
  else
"請輸入可以識別或是非零的數字"
  end
rescue
"發生錯誤"
end
end

def cheap
  require "nokogiri"
  require 'open-uri' #要require這個linebot 才能顯示
  url = "https://www.esunbank.com.tw/bank/personal/deposit/rate/forex/foreign-exchange-rates"#玉山網址

  html = Nokogiri::HTML(open(url)) 
  datetime = html.css("span[@id = LbQuoteTime]").text #他的套件
  tableRows = html.css("table > tr > td") 

rates = {
  update: datetime,  #自定義一個變數名稱為update抓取上面所設定的datetime
  result:  parseNode_Mountain(tableRows)
}
temp = parseNode_Mountain(tableRows)
rates = rates.to_json
json = JSON.parse(rates)
render  plain: "#{json['update']} 日圓\n玉山銀行現金買入:#{json['result']['cash_buy_rate']}\n玉山銀行現金賣出:#{json['result']['cash_sell_rate']}\n玉山優惠買入匯率:#{json['result']['buying_best_rate']}\n玉山優惠賣出匯率:#{json['result']['selling_best_rate']}\n玉山銀行即期買入:#{json['result']['buying_rate']}\n玉山銀行即期賣出:#{json['result']['selling_rate']}"
end

#看片動作
def get_movie(received_text)
  return nil unless received_text.include? '我想上車'  #只要對話內容有"我想上車"關鍵字
  'go'
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
  
  def reply_carousel_template_to_line(reply_text)
    return nil if reply_text.nil?
   
    reply_token = params['events'][0]['replyToken']
   
    message = {
      "type": "template",
      "altText": "記得要看手機喔~",
      "template": {
          "type": "carousel",
          "columns": [
              {
                "thumbnailImageUrl": "https://i.imgur.com/Dk0U6fh.jpg",
                "imageBackgroundColor": "#FFFFFF",
                "title": "阿蘇火山",
                "text": "去看火山，阿蘇火山根本阿嘶",
                "defaultAction": {
                    "type": "uri",
                    "label": "View detail",
                    "uri": "http://www.aso.ne.jp/~volcano/"
                },
                "actions": [
                    {
                        "type": "uri",
                        "label": "交通方式",
                        "uri": "https://www.kyusanko.co.jp/aso/"
                    },
                    {
                        "type": "uri",
                        "label": "詳細介紹",
                        "uri": "http://bob20842.pixnet.net/blog/post/403107194-2018%E5%B9%B4%E7%9A%84%E9%98%BF%E8%98%87%E7%81%AB%E5%B1%B1%E5%8F%A3%E6%9C%80%E6%96%B0%E7%8B%80%E6%B3%81%28%E8%B6%85%E5%A3%AF%E8%A7%80%E7%9A%84%E9%98%BF%E8%98%87%E4%B8%AD"
                    }
                ]
              },
              {
                "thumbnailImageUrl": "https://i.imgur.com/cimzz96.jpg",
                "imageBackgroundColor": "#000000",
                "title": "くまモンスクエア",
                "text": "去熊本當然要看熊本熊阿，不然要幹嘛0.0?",
                "defaultAction": {
                    "type": "uri",
                    "label": "View detail",
                    "uri": "http://www.kumamon-sq.jp/"
                },
                "actions": [
                    {
                        "type": "uri",
                        "label": "交通方式",
                        "uri": "http://www.kumamon-sq.jp/access.html"
                    },                 
                    {
                        "type": "uri",
                        "label": "詳細介紹",
                        "uri": "http://haruhii.pixnet.net/blog/post/44663344-kumamon-square"
                    }
                ]
              },
              {
                "thumbnailImageUrl": "https://imgur.com/vlUUD5c.jpg",
                "imageBackgroundColor": "#000000",
                "title": "博多運城河",
                "text": "展現你的消費力",
                "defaultAction": {
                    "type": "uri",
                    "label": "View detail",
                    "uri": "https://canalcity.co.jp/"
                },
                "actions": [
                    {
                        "type": "uri",
                        "label": "交通方式",
                        "uri": "http://canalcity.pixnet.net/blog/post/3926830-%E6%A2%9D%E6%A2%9D%E5%A4%A7%E8%B7%AF%E9%80%9A%E5%8D%9A%E5%A4%9A%EF%BC%8C%E5%8D%9A%E5%A4%9A%E9%81%8B%E6%B2%B3%E5%9F%8E%E4%BA%A4%E9%80%9A%E6%95%99%E6%88%B0%EF%BC%81"
                    },                 
                    {
                        "type": "uri",
                        "label": "詳細介紹",
                        "uri": "https://cline1413.com.tw/2016-01-30-1219/"
                    }
                ]
              }
          ],
          "imageAspectRatio": "rectangle",
          "imageSize": "cover"
      }
    }
    line.reply_message(reply_token, message)
   end

   #回傳所在位置
   def reply_location_to_line(reply_text)
    return nil if reply_text.nil?

    reply_token = params['events'][0]['replyToken']

    message = {
  "type": "location",
  "title": "title",
  "address": "test",
  "latitude": 35.65910807942215,
  "longitude": 139.70372892916203
 }
 line.reply_message(reply_token, message)
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
      config.channel_secret = '0887d7434953abe95aa320fe29f20e43'
      config.channel_token = 'nYs3kTGBVRlmAZq6Zt3bqPxK7YOAAYt9TZZj/lTErYkXJFYDfXOL7s+nEFIcr9D8leYFMGeJr7GasofFiU7zji3PiQWeLqYpVPRMiK4RxIcMrayWEsEzzpoHVsyrDXJaLlHEGyGM+20BaDfwxVAiLAdB04t89/1O/w1cDnyilFU='
    }
  end

  
end