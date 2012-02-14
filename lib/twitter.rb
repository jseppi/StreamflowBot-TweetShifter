require 'jars/twitter4j-core-2.2.5.jar'
require 'jars/twitter4j-async-2.2.5.jar'
require 'jars/twitter4j-stream-2.2.5.jar'

import 'twitter4j.FilterQuery'
import 'twitter4j.TwitterStreamFactory'
import 'twitter4j.StatusListener'
import 'twitter4j.conf.ConfigurationBuilder'

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

  include StatusListener

  def onStatus(status)
    tweet = Tweet.new

    tweet[:id] = status.id.to_s
    tweet[:created_at] = status.created_at.time / 1000
    tweet[:user_name] = status.user.screen_name
    tweet[:user_id] = status.user.id.to_s
    tweet[:text] = status.text
    tweet[:retweet] = :default

    if status.in_reply_to_status_id > -1
      tweet[:reply_to_id] = status.in_reply_to_status_id.to_s
      tweet[:reply_to_user_name] = status.in_reply_to_screen_name
      tweet[:reply_to_user_id] = status.in_reply_to_user_id.to_s
    end

    if status.retweet?
      tweet[:retweet_text] = status.retweeted_status.text
      tweet[:retweet_user_name] = status.retweeted_status.user.screen_name
      tweet[:retweet_user_id] = status.retweeted_status.user.id.to_s
    end

    tweet.save
    Statistics.current.inc(:tweets, 1)
  end

  def onException(exception)
    exception.printStackTrace
  end

end
