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
	property :url, String, :format => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
	property :title, String
	property :body, Text
	property :votes, Integer, :required=> true, :default=> 0
	property :created_by, String
	property :created_at, DateTime
		
	def url=(submited_url)
		attribute_set(:url, fix_url(submited_url))
	end
	
	def fix_url(url)
		unless url.match(/^http|https/)
			url = "http://" + url
		end
		url
	end
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
    haml :add
  end
  
  post '/vote' do
	link = Link.get(params[:id])
	link.votes = link.votes + 1 if params[:operator] == "+"
	link.votes = link.votes - 1 if params[:operator] == "-"
	link.save
	redirect "/"
  end

  post '/add' do
	if session[:userid].nil? then redirect '/' end
	link = Link.create(
		:url=>params[:url],
		:title=>params[:title], 
		:body=>params[:body],
		:created_by => session[:user_id])
	if @link.save
		redirect '/'
	else
		haml :add
	end
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
