require 'oauth'
require 'json'

class TwitterDownloader
  attr_accessor :username
  attr_accessor :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret
  attr_accessor :access_token

  def initialize(consumer_key, consumer_secret, oauth_token, oauth_token_secret)
    self.consumer_key = consumer_key
    self.consumer_secret = consumer_secret
    self.oauth_token = oauth_token
    self.oauth_token_secret = oauth_token_secret
  end
  
  def authenticate
    consumer = OAuth::Consumer.new(
      self.consumer_key, 
      self.consumer_secret,
      { :site => "http://api.twitter.com", :scheme => :header })
    # now create the access token object from passed values
    token_hash = { :oauth_token => self.oauth_token, :oauth_token_secret => self.oauth_token_secret }
    self.access_token = OAuth::AccessToken.from_hash(consumer, token_hash)
    return self.access_token
  end
  
  def download_tweets_earlier_than(tweet_id)
    options = tweet_id ? { :max_id => tweet_id.to_i } : {}
    download_tweets(options)
  end

  def download_tweets_later_than(tweet_id)
    options = tweet_id ? { :since_id => tweet_id.to_i } : {}
    download_tweets(options)
  end

  def download_tweets(options = {})
    if self.access_token.nil?
      authenticate
    end
    
    default_options = { 
      :count => 200, 
      :trim_user => 'false', 
      :exclude_replies => 'false', 
      :include_rts => 'true', 
      :include_entities => 'true',
      :contributor_details => 'true'
    }
    all_options = default_options.merge(options)
    all_options[:screen_name] = self.username if !self.username.nil?
    
    querystring = all_options.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")
    response = self.access_token.request(:get, "http://api.twitter.com/1/statuses/user_timeline.json?#{querystring}")
    tweets = JSON.parse(response.body)
  end
end