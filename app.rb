require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'open-uri'
require 'digest/md5'
#require 'rack-flash'
require 'json' 
require 'net/http'
require 'net/https'

class User
	include DataMapper::Resource
	property :identifier, String, :key => true
	property :email,      String
        property :nickname,   String
	property :photo_url,  String
end
class Vote
	include DataMapper::Resource
	property :link_id, Integer, :key => true
	property :user_id, String, :key => true
	property :vote, Integer 
validates_numericality_of :vote, :gte => -1, :lte => 1, :integer_only => true
end
class Link
	include DataMapper::Resource
	property :id, Serial
	property :url, String
	property :title, String
	property :body, Text
	property :up_vote, Integer
	property :down_vote, Integer
	property :created_by, String
	property :created_at, DateTime
end


class RubyOres < Sinatra::Base
set :sessions, true
#use Rack::Flash

	configure :production do 
	  DataMapper.setup(:default, ENV['DATABASE_URL']) 
	end

	configure :development do
	  DataMapper::Logger.new($stdout, :debug)
	  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/dev.db")
	end

	configure do
	  DataMapper.finalize
	  DataMapper.auto_upgrade!
	end

  get '/' do
    @links = Link.all(:order => :created_at.desc, :limit => 10)
    haml :index
  end

  get '/add' do
    redirect '/login' unless OpenIDAuth.logged_in?
    haml :add
  end

  post '/add' do
if session[:userid].nil? then erb :login end 
	link = Link.create(
		:url=>params[:url],
		:title=>params[:title], 
		:body=>params[:body],
		:created_by => session[:user])
    redirect '/'
  end
get '/logout' do
  session[:userid] = nil
  redirect '/'
end

get '/login' do
 erb :login
end

post '/auth' do
	openid_user = get_user(params[:token])
	user = User.first_or_create({:identifier => openid_user[:identifier]},{:nickname => openid_user[:nickname], :email => openid_user[:email], :photo_url => "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(openid_user[:email])}" })
	session[:userid] = user.identifier # keep what is stored small
	redirect "/"
end

def get_user(token)
	u = URI.parse('https://rpxnow.com/api/v2/auth_info')
	req = Net::HTTP::Post.new(u.path)
	req.set_form_data({'token' => token, 'apiKey' => '406851aee5052f464a0dadeba54277a57397159a', 'format' => 'json', 'extended' => 'true'})
	http = Net::HTTP.new(u.host,u.port)
	http.use_ssl = true if u.scheme == 'https'
	json = JSON.parse(http.request(req).body)

	if json['stat'] == 'ok'
		identifier = json['profile']['identifier']
		nickname = json['profile']['preferredUsername']
		nickname = json['profile']['displayName'] if nickname.nil?
		email = json['profile']['email']
		{:identifier => identifier, :nickname => nickname, :email => email}
	else
		#raise LoginFailedError, 'Cannot log in. Try another account!'
		raise Exception, "An error occured: #{json['err']['msg']}"
	end
end
end
