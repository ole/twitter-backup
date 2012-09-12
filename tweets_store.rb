require 'json'
require 'fileutils'

class TweetsStore
  attr_accessor :tweets
  attr_accessor :path_to_json_file

  def initialize(path_to_json_file)
    if path_to_json_file.nil? || path_to_json_file.empty?
      raise RuntimeError, "path_to_json_file must not be blank."
    end
    self.path_to_json_file = path_to_json_file
    self.tweets = parse_json_file || []
  end
  
  def count
    return self.tweets.count
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
    create_data_dir_if_necessary
    write_tweets_to_data_file
  end
  
  private
  
  def parse_json_file
    if (File.exists?(self.path_to_json_file))
      File.open(self.path_to_json_file, mode: 'r:UTF-8', cr_newline: true) do |file|
        json_string = file.read(nil)
        JSON.parse(json_string)
      end
    else
      nil
    end
  end
  
  def create_data_dir_if_necessary
    dirname = File.dirname(self.path_to_json_file)
    if !Dir.exists?(dirname)
      FileUtils.mkpath(dirname)
    end
  end
  
  def write_tweets_to_data_file
    File.open(self.path_to_json_file, mode: 'w:UTF-8', cr_newline: true) do |file| 
      json_string = JSON.pretty_generate(self.tweets)
      file.write(json_string)
    end
  end
end
