$: << File.expand_path('../lib', __FILE__)
require 'java'

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

#ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] ||= 'development'
config_file_name = ENV['OPENSHIFT_APP_NAME'] ? 'production' : 'development'

require File.expand_path("../config/#{config_file_name}", __FILE__)

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
  #TODO: process "subscribe" tweets
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

@direct_message_thread = Thread.new do
  loop do
    puts 'Direct Message thread'
    begin
      
    end
    sleep(86400) #sleep for a day
  end
end

# Start web frontend
run Web