require 'json'
require 'fileutils'

class TweetsStore
  attr_accessor :path_to_json_file
  attr_accessor :tweets

  def initialize(path_to_json_file)
    if path_to_json_file.nil? || path_to_json_file.empty?
      raise RuntimeError, "path_to_json_file must not be blank."
    end
    self.path_to_json_file = path_to_json_file
    self.tweets = parse_json_file
  end
  
  def parse_json_file
    if (File.exists?(self.path_to_json_file))
      File.open(self.path_to_json_file, mode: 'r:UTF-8', cr_newline: true) do |file|
        json_string = file.read(nil)
        JSON.parse(json_string)
      end
    else
      # Empty array
      JSON.parse "[]"
    end
  end

  def lowest_tweet_id
    earliest_tweet = self.tweets.last
    if !earliest_tweet.nil?
      earliest_tweet['id'] || earliest_tweet[:id]
    else
      nil
    end
  end
  
  def highest_tweet_id
    latest_tweet = self.tweets.first
    if !latest_tweet.nil?
      latest_tweet['id'] || latest_tweet[:id]
    else
      nil
    end
  end

  def append_tweets(new_tweets)
    new_tweets.map! { |item| item.to_hash }
    self.tweets = self.tweets + new_tweets
  end

  def prepend_tweets(new_tweets)
    new_tweets.map! { |item| item.to_hash }
    self.tweets = new_tweets + self.tweets
  end
  
  def save
    # Create directory if it doesn't exist
    dirname = File.dirname(self.path_to_json_file)
    if !Dir.exists?(dirname)
      FileUtils.mkpath(dirname)
    end
    
    # Write tweets data to file
    File.open(self.path_to_json_file, mode: 'w:UTF-8', cr_newline: true) do |file| 
      json_string = JSON.pretty_generate(self.tweets)
      file.write(json_string)
    end
  end
end
