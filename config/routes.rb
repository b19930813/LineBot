Rails.application.routes.draw do
  resources :keyword_mappings
  resources :push_messages, only: [:new, :create]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/frank/eat', to: 'frank#eat'
  get '/frank/request_headers', to: 'frank#request_headers'
  get '/frank/request_body', to: 'frank#request_body'
  get '/frank/response_headers', to: 'frank#response_headers'
  get '/frank/response_body',to:'frank#show_response_body'
  get '/frank/sent_request', to: 'frank#sent_request'
  post '/frank/webhook', to: 'frank#webhook'
  post '/push_messages/new', to: 'push_messages#create'
  get 'frank/transJN', to: 'frank#transJN'
end
