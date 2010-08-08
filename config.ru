require 'rubygems'
require 'app.rb'
require 'openid_auth.rb'

run Rack::Cascade.new [RubyOres, OpenIDAuth]