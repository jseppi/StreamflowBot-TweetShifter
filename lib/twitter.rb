require 'jars/twitter4j-core-2.2.5.jar'
require 'jars/twitter4j-async-2.2.5.jar'
require 'jars/twitter4j-stream-2.2.5.jar'

import 'twitter4j.FilterQuery'
import 'twitter4j.TwitterStreamFactory'
import 'twitter4j.StatusListener'
import 'twitter4j.conf.ConfigurationBuilder'
import 'twitter4j.StatusUpdate'
import 'twitter4j.Status'
import 'twitter4j.TwitterFactory'
import 'twitter4j.GeoLocation'

class Twitter

  def self.config
    config = ConfigurationBuilder.new
    config.setDebugEnabled(true)
    config.setOAuthConsumerKey(TWITTER_CONSUMER_KEY)
    config.setOAuthConsumerSecret(TWITTER_CONSUMER_SECRET)
    config.setOAuthAccessToken(TWITTER_ACCESS_TOKEN)
    config.setOAuthAccessTokenSecret(TWITTER_ACCESS_SECRET)
    config.build
  end

  def self.start
    @stream = TwitterStreamFactory.new(self.config).instance
    @stream.addListener(self.new)
    @stream.filter(FilterQuery.new(0, TWITTER_USERS.to_java(:long), TWITTER_KEYWORDS.to_java(:string)))

    
    #@twitter.updateStatus("I'm up and running (#{Time.now})!")
  end

  def initialize
    @twitter = TwitterFactory.new(Twitter.config).instance
  end

  def get_nwis_iv_response(site_code)

    param_codes = "00060,00065" #discharge (cfs), gage height (feet)

    iv_uri = URI::HTTP.build(
      :host => "waterservices.usgs.gov",
      :path => '/nwis/iv/',
      :query => { 
        :format => "json",
        :sites => site_code,
        :parameterCd => param_codes
      }.map{|k,v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}"}.join("&"))

    begin
      data = Net::HTTP.get_response(iv_uri).body
      j = JSON.parse(data)

      sitename = j['value']['timeSeries'][0]\
            ['sourceInfo']['siteName']

      lat = j['value']['timeSeries'][0]\
          ['sourceInfo']['geoLocation']['geogLocation']['latitude']

      lon = j['value']['timeSeries'][0]\
          ['sourceInfo']['geoLocation']['geogLocation']['longitude']

      discharge = j['value']['timeSeries'][0]\
            ['values'][0]['value'][0]['value']

      timestamp = j['value']['timeSeries'][0]\
            ['values'][0]['value'][0]['dateTime']

      gage_height = j['value']['timeSeries'][1]\
            ['values'][0]['value'][0]['value']

      return {
        :sitename => sitename, 
        :lat => lat,
        :lon => lon,
        :discharge => discharge, 
        :gage_height => gage_height, 
        :timestamp => timestamp
      }

    rescue
       return nil
    end
  end

  include StatusListener

  def onStatus(status)

    tweet = Tweet.new

    tweet[:id] = status.id.to_s
    tweet[:created_at] = status.created_at.time / 1000
    tweet[:user_name] = status.user.screen_name
    tweet[:user_id] = status.user.id.to_s
    tweet[:text] = status.text
    tweet[:type] = :default

    if status.in_reply_to_status_id > -1
      tweet[:type] = :reply
      tweet[:reply_to_id] = status.in_reply_to_status_id.to_s
      tweet[:reply_to_user_name] = status.in_reply_to_screen_name
      tweet[:reply_to_user_id] = status.in_reply_to_user_id.to_s
    end

    if status.retweet?
      tweet[:type] = :retweet
      tweet[:retweet_text] = status.retweeted_status.text
      tweet[:retweet_user_name] = status.retweeted_status.user.screen_name
      tweet[:retweet_user_id] = status.retweeted_status.user.id.to_s
    end



    #if status.text contains 8-15 digit number, then try to 
    if ( /(\d{8,15})/ =~ status.text ) #8-15 digits for USGS site codes
      site_code = $1
      ans = get_nwis_iv_response(site_code)

      if not ans
        #site wasn't found OR didn't have both parameters
        tweet[:response_type] = "ERROR"
      else
        
        
        new_status_update = StatusUpdate.new(
          "@#{status.user.screen_name} Flow at #{ans[:sitename]} (#{site_code}): " +
          "#{ans[:discharge]} cfs; Stage: #{ans[:gage_height]} ft; Time: #{ans[:timestamp]}")
        
        new_status_update.setLocation(GeoLocation.new(
          ans[:lat].to_f, ans[:lon].to_f))
        new_status_update.setInReplyToStatusId(status.id)
        new_status_update.setDisplayCoordinates(true)

        begin
          @twitter.updateStatus(new_status_update)
          tweet[:responded_to] = true
          tweet[:usgs_site_id] = ans[:discharge]
          tweet[:response_type] = "NORMAL"

          puts "Responding to #{status.user.screen_name}'s request for #{ans[:sitename]} in tweet ##{status.id}."
        rescue Exception=>e
          #there was an error updating (like maybe it was a repeat status or twitter is down)
          tweet[:response_type] = "ERROR"
          puts "ERROR in responding to #{status.user.screen_name}'s request for #{ans[:sitename]} in tweet ##{status.id}."
          puts e.to_s
        end

        
      end

    end

    tweet.save
    Statistics.current.inc(:tweets, 1)
    
    #Registration.all.each do |receiver|
    #  C2DM.instance.notify(receiver.registration_id, tweet[:user_name], tweet[:text])
    #end
  end

  def onDeletionNotice(statusDeletionNotice)
    puts "something was deleted"
  end

  def onException(exception)
    exception.printStackTrace
  end

end
