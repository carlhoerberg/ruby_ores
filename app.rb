require 'sinatra/base'

class RubyOres < Sinatra::Base
  get '/' do
    'Hello RubyOres!'
  end
end
