# Using the Twitter gem, see https://github.com/sferik/twitter
require 'twitter'

class TwitterDownloader
  attr_accessor :username
  
  def initialize(username)
    self.username = username
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
    default_options = { 
      :count => 200, 
      :trim_user => false, 
      :exclude_replies => false, 
      :include_rts => true, 
      :include_entities => true,
      :contributor_details => true
    }
    all_options = default_options.merge(options)
    tweets = Twitter.user_timeline(self.username, options)
  end
end
