require 'digest/md5'

class User
	include DataMapper::Resource
	property :id,         Serial
	property :identifier, String
	property :email,      String
	property :nickname,   String
	def photo_url
		"http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(@email)}" 
	end
	has n, :votes
	has n, :links
end

class Vote
	include DataMapper::Resource
	belongs_to :user, :key => true
	belongs_to :link, :key => true
	property :is_down?, Boolean, :required => true, :default=> false

end

class Link
	include DataMapper::Resource
	property :id, Serial
	property :url, String, :format => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
	property :title, String
	property :body, Text
	property :votes, Integer, :required=> true, :default=> 0
	property :created_at, DateTime
	belongs_to :created_by, 'User'		

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
