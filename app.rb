require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'open-uri'
require 'digest/md5'
#require 'rack-flash'

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
	property :is_down?, Boolean, :required => true, :default=> false
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
	@vote = Vote.new(
			:user_id=> session[:userid],
			:link_id=> params[:id]
			:is_down?=> params[:operator] == "-"
		)
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
	openid_user = get_user(params[:token])
	user = User.first_or_create({:identifier => openid_user[:identifier]},{:nickname => openid_user[:nickname], :email => openid_user[:email], :photo_url => "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(openid_user[:email])}" })
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
