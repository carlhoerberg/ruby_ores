require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'

class User
	include DataMapper::Resource
	property :id, Serial
	
	def self.current
		User.new
	end
end

class Link
	include DataMapper::Resource
	property :id, Serial
	property :url, String, :format => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
	property :title, String
	property :body, Text
	property :up_vote, Integer
	property :down_vote, Integer
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
	set :run,true
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
    user = User.current
    haml :add
  end
  
  post '/vote' do
	link = Link.get(params[:id])
	link.up_vote ? link.up_vote += 1 : link.up_vote = 1
	link.save
	redirect "/"
  end

  post '/add' do
	@link = Link.new(
		:url=>params[:url],
		:title=>params[:title], 
		:body=>params[:body],
		:created_by => session[:user])
	if @link.save
		redirect '/'
	else
		haml :add
	end
  end
end