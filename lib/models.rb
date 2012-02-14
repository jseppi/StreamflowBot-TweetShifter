class Tweet

  include Mongoid::Document

  field :created_at, :type => Integer

  field :id, :type => Integer
  field :text, :type => String

  field :user_name, :type => String
  field :user_id, :type => Integer

  field :type, :type => Symbol

  field :reply_to_id, :type => Integer
  field :reply_to_user_name, :type => String
  field :reply_to_user_id, :type => Integer

  field :retweet_id, :type => Integer
  field :retweet_user_name, :type => String
  field :retweet_user_id, :type => Integer


end

class Statistics

  include Mongoid::Document

  field :interval, :type => Integer
  field :tweets, :type => Integer

  def self.current
    time = Time.now.to_i
    time = time - (time % self.interval)
    Statistics.find_or_create_by(:interval => time)
  end

  def self.interval
    3600
  end

  def self.check
    Statistics.current.inc(:tweets, 0)
  end

end