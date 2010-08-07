require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'

#include openid_auth.rb

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
	@links = Link.all(:order => :created_at)
    haml :index
  end

  get '/add' do
    haml :add
  end

  post '/add' do
	link = Link.create(
		:url=>params[:url],
		:title=>params[:title], 
		:body=>params[:body])
    redirect '/'
  end
end
