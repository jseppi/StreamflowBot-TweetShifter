$: << File.expand_path('../lib', __FILE__)
require 'java'

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

#ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] ||= 'development'

ENV['RACK_ENV'] = 'development' #JAS TEST

require File.expand_path("../config/#{ENV['RACK_ENV']}", __FILE__)

# Connect to MongoDB
Mongoid.configure do |config|
  config.master = Mongo::Connection.new(MONGO_SERVER, MONGO_PORT).db(MONGO_DB)
  config.master.authenticate(MONGO_USER, MONGO_PASS)
end
Mongoid.logger = Logger.new($stdout)

# Data models
require 'models'

# Mobile development
#require 'c2dm'
#C2DM.instance.auth(C2DM_USER, C2DM_PASS)

# Twitter listener
require 'twitter'

# Web frontend
require 'web'

# Start listening to Twitter events
@twitter_thread = Thread.new do
  puts "Twitter thread"
  Twitter.start
end

# Periodically ensure statistics existence
@checker_thread = Thread.new do
  loop do
    puts 'Statistics thread'
    begin
      Statistics.check
    rescue Exception => e
      puts e.message
    end
    sleep(Statistics.interval)
  end
end

# Start web frontend
run Web