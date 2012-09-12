# Using the Twitter gem, see https://github.com/sferik/twitter
require 'twitter'

class TwitterDownloader
  attr_accessor :username
  
  def initialize(username)
    self.username = username
  end
  
  def download_tweets_earlier_than(tweet_id)
    options = { 
      :count => 200, 
      :trim_user => false, 
      :exclude_replies => false, 
      :include_rts => true, 
      :include_entities => true,
      :contributor_details => true
    }
    if tweet_id
      options[:max_id] = tweet_id.to_i
    end
    tweets = Twitter.user_timeline(self.username, options)
  end

  def download_tweets_later_than(tweet_id)
    options = { 
      :count => 200, 
      :trim_user => false, 
      :exclude_replies => false, 
      :include_rts => true, 
      :include_entities => true,
      :contributor_details => true
    }
    if tweet_id
      options[:since_id] = tweet_id.to_i
    end
    tweets = Twitter.user_timeline(self.username, options)
  end
end
