require 'rubygems'
require 'sequel'
require 'sequel/extensions/pretty_table'
require 'json'
require 'fileutils'

class TweetsStore
  attr_accessor :database_path
  attr_accessor :database
  attr_accessor :tweets

  def initialize(database_path)
    if database_path.nil? || database_path.empty?
      raise RuntimeError, "database_path must not be blank."
    end
    self.database_path = database_path
    setup_database
  end
  
  def setup_database
    create_database_dir_if_necessary
    self.database = Sequel.sqlite(self.database_path)
    create_tweets_table_if_necessary
    self.tweets = self.database[:tweets]
  end
  
  def create_tweets_table_if_necessary
    return if self.database.table_exists?(:tweets)

    self.database.create_table :tweets do
      primary_key :id
      Integer :tweet_id
      DateTime :created_at
      String :text
      Integer :in_reply_to_status_id
      Integer :retweeted_status_id
      String :raw_json
      index :tweet_id
      index :created_at
    end
  end
  
  def count
    return self.tweets.count
  end
  
  def lowest_tweet_id
    earliest_tweet = self.tweets.order(Sequel.asc(:tweet_id)).first
    if !earliest_tweet.nil?
      earliest_tweet[:tweet_id]
    else
      nil
    end
  end
  
  def highest_tweet_id
    latest_tweet = self.tweets.order(Sequel.desc(:tweet_id)).first
    if !latest_tweet.nil?
      latest_tweet[:tweet_id]
    else
      nil
    end
  end

  def append_tweets(tweets)
    records = tweets.map do |tweet|
      record = {
        :tweet_id => tweet['id_str'].to_i,
        :created_at => DateTime.parse(tweet['created_at']),
        :text => tweet['text'], 
        :in_reply_to_status_id => tweet['in_reply_to_status_id_str'] ? tweet['in_reply_to_status_id_str'].to_i : nil,
        :retweeted_status_id => tweet['retweeted_status'] ? tweet['retweeted_status']['id_str'].to_i : nil,
        :raw_json => JSON.pretty_generate(tweet)
      }
    end
    self.tweets.multi_insert(records)
  end
  
  private
  
  # def parse_json_file
  #   if (File.exists?(self.path_to_json_file))
  #     File.open(self.path_to_json_file, mode: 'r:UTF-8', cr_newline: true) do |file|
  #       json_string = file.read(nil)
  #       JSON.parse(json_string)
  #     end
  #   else
  #     nil
  #   end
  # end
  
  def create_database_dir_if_necessary
    dirname = File.dirname(self.database_path)
    if !Dir.exists?(dirname)
      FileUtils.mkpath(dirname)
    end
  end
  
  # def write_tweets_to_data_file
  #   File.open(self.path_to_json_file, mode: 'w:UTF-8', cr_newline: true) do |file| 
  #     json_string = JSON.pretty_generate(self.tweets)
  #     file.write(json_string)
  #   end
  # end
end
