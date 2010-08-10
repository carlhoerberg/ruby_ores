module Models
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
end