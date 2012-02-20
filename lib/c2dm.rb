# https://www.google.com/accounts/ClientLogin
require 'singleton'

class C2DM

  include Singleton
  include HTTParty

  def auth(username, password)
    params = {
        'Email' => username,
        'Passwd' => password,
        'accountType' => 'HOSTED_OR_GOOGLE',
        'service' => 'ac2dm'
    }
    data = self.class.post('https://www.google.com/accounts/ClientLogin', :body => params)
    puts data
    data = /Auth=([^\n]+)/.match(data)
    @auth = data[1]
  end

  def notify(id, username, tweet)
    params = {
        'registration_id' => id,
        'collapse_key' => 'tweets',
        'data.username' => username,
        'data.tweet' => tweet
    }
    headers = {
        'Authorization' => "GoogleLogin auth=#{@auth}"
    }
    data = self.class.post('https://android.apis.google.com/c2dm/send', :body => params, :headers => headers)
    puts data
  end

end