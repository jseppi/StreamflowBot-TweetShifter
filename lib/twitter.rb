require 'jars/twitter4j-core-2.2.5.jar'
require 'jars/twitter4j-async-2.2.5.jar'
require 'jars/twitter4j-stream-2.2.5.jar'
require 'usgs_services'

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
  end

  def initialize
    @twitter = TwitterFactory.new(Twitter.config).instance
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
    tweet[:responded_to] = false

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

    if not status.retweet #ignore if it is a retweet

      if ( /(\d{8,15})/ =~ status.text ) #if status.text contains 8-15 digit number, then try to get data
        site_code = $1
        ans = USGSServices.get_nwis_iv_response(site_code)

        if not ans #Service down or something
          new_status_update = StatusUpdate.new(
            "@#{status.user.screen_name} There was an error with the USGS service. "+
            "Please try later (Time: #{Time.now}).")
          new_status_update.setInReplyToStatusId(status.id)
          tweet[:response_type] = :ERROR_SERVICE_ERR

        elsif ans == "NOT_FOUND"  #site not found
          puts "ERROR - #{site_code} was NOT FOUND"

          new_status_update = StatusUpdate.new(
            "@#{status.user.screen_name} Site #{site_code} not found. "+
            "Try with a valid site (see http://goo.gl/TwXa1)")
          
          new_status_update.setInReplyToStatusId(status.id)
          tweet[:response_type] = :ERROR_SITE_NOT_FOUND

        else #everything ok
          
          new_status_update = StatusUpdate.new(
            "@#{status.user.screen_name} "+
              "#{ans[:discharge] ? 'Flow at ' + ans[:sitename] + ' (' + site_code + '): ' + 
                ans[:discharge] + ' cfs; ' \
                : 'No flow avail; '}" +
              "Stage: #{ans[:gage_height]} ft; Time: #{ans[:timestamp]}")
          
          new_status_update.setLocation(GeoLocation.new(
            ans[:lat].to_f, ans[:lon].to_f))
          new_status_update.setInReplyToStatusId(status.id)
          new_status_update.setDisplayCoordinates(true)

          tweet[:response_type] = :NORMAL
          tweet[:usgs_site_id] = site_code
        end

        begin
          @twitter.updateStatus(new_status_update)
          tweet[:responded_to] = true

          puts "Responding to #{status.user.screen_name}'s tweet ##{status.id}."
        
        rescue Exception=>e
          #there was an error updating (like maybe it was a repeat status or twitter is down)
          puts "ERROR in responding to #{status.user.screen_name}'s tweet ##{status.id}."
          
          new_status_update = StatusUpdate.new(
            "@#{status.user.screen_name} Data for #{site_code} have not changed " +
            "since your last request.")
          new_status_update.setInReplyToStatusId(status.id)

          @twitter.updateStatus(new_status_update)
          tweet[:responded_to] = true
          tweet[:response_type] = :ERROR_REPEAT
        end

      else #No site code -- send usage info

        begin
          new_status_update = StatusUpdate.new(
              "@#{status.user.screen_name} Send me a USGS Site ID to get flow data. " +
              "See http://goo.gl/TwXa1 for sites.")
          new_status_update.setInReplyToStatusId(status.id)
          @twitter.updateStatus(new_status_update)
          tweet[:responded_to] = true
          tweet[:response_type] = :ERROR_NO_SITE_CODE
        rescue
          #do nothing
        end
      end #end else
    end #end if not status.retweet

    tweet.save
    Statistics.current.inc(:tweets, 1)
    
  end

  def onDeletionNotice(statusDeletionNotice)
    puts "something was deleted"
  end

  def onException(exception)
    exception.printStackTrace
  end

end
