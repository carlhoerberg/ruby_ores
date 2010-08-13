require 'uri'
require 'json' 
require 'net/http'
require 'net/https'
require 'apikeys'
require 'open-uri'

class RPX
	def self.get_user(token)
		u = URI.parse('https://rpxnow.com/api/v2/auth_info')
		req = Net::HTTP::Post.new(u.path)
		req.set_form_data({'token' => token, 'apiKey' => APIKeys::Rpx, 'format' => 'json', 'extended' => 'true'})
		http = Net::HTTP.new(u.host,u.port)
		http.use_ssl = true if u.scheme == 'https'
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
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
