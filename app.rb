require 'sinatra/base'

class RubyOres < Sinatra::Base
  get '/' do
    haml :index
  end

  get '/add' do
    haml :add
  end

  post '/add' do
    redirect '/'
  end
end
