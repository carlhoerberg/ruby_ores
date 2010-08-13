require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
#require 'rack-flash'
require 'rpx'
require 'apikeys'
require 'models'

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
  helpers do 
	def get_thumbnail url
		res = "http://images.pageglimpse.com/v1/thumbnails?url=" + url +"/&size=small&devkey="  + APIKeys::PAGEGLIMPS
		res
	end
  end
  
  get '/' do
    @links = Link.all(:order => :created_at.desc, :limit => 10)
    haml :index
  end
  
  get '/add' do
    haml :add
  end
  
  post '/vote' do
	@vote = Vote.new(
			:user_id=> session[:userid],
			:link_id=> params[:id]
		)
	@vote.is_down?=> params[:operator] == "-"
	@vote.save
	link = Link.get(params[:id])
	link.votes = link.votes + 1 unless vote.is_down?
	link.votes = link.votes - 1 if vote.is_down?
	link.save
	redirect "/"
  end

  post '/add' do
	if session[:userid].nil? then redirect '/' end
	@link = Link.create(
		:url=>params[:url],
		:title=>params[:title], 
		:body=>params[:body],
		:created_by => session[:userid])
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

post '/login' do
	openid_user = RPX.get_user(params[:token])
	user = User.first_or_create({:identifier => openid_user[:identifier]},{:nickname => openid_user[:nickname], :email => openid_user[:email]})
	session[:userid] = user.identifier # keep what is stored small
	redirect "/"
end

get '/rss.xml' do
	baseUrl = "http://rubyores.heroku.com/"
	@posts = Link.all(:order => :created_at.desc, :limit => 50)

	builder do |xml|
	    xml.instruct! :xml, :version => '1.0'
	    xml.rss :version => "2.0" do
	      xml.channel do
		xml.title "Ruby Ores"
		xml.description "A Ruby news site."
		xml.link baseUrl        
		@posts.each do |post|
		  xml.item do
		    xml.title post.title
		    xml.link "#{baseUrl}#{post.id}"
		    xml.description post.body
		    xml.pubDate Time.parse(post.created_at.to_s).rfc822()
		    xml.guid "#{baseUrl}#{post.id}"
		  end
		end
	      end
	    end
	  end
end
end

if __FILE__ == $0
   RubyOres.run! :host => 'localhost', :port => 9393
end
