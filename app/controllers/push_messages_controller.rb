class PushMessagesController < ApplicationController
  
    # GET /push_messages/new
    def new
    end
  
    # POST /push_messages
    def create
        text = params[:text]
        channel = params[:channel]
        push_to_line(channel, text)
      
        redirect_to '/push_messages/new'
    end
    def push_to_line(channel_id, text)
        return nil if channel_id.nil? or text.nil?
        
        # 設定回覆訊息
        message = {
          type: 'text',
          text: text
        } 
    
        # 傳送訊息
        line.push_message(channel_id, message)
      end
      def line
        @line ||= Line::Bot::Client.new { |config|
          config.channel_secret = '0887d7434953abe95aa320fe29f20e43'
          config.channel_token = 'nYs3kTGBVRlmAZq6Zt3bqPxK7YOAAYt9TZZj/lTErYkXJFYDfXOL7s+nEFIcr9D8leYFMGeJr7GasofFiU7zji3PiQWeLqYpVPRMiK4RxIcMrayWEsEzzpoHVsyrDXJaLlHEGyGM+20BaDfwxVAiLAdB04t89/1O/w1cDnyilFU='
        }
      end
  end