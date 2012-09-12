#!/usr/bin/env ruby

require File.dirname(File.expand_path(__FILE__)) + '/config.rb'

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


require 'optparse'

options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{opts.program_name} <username>"
end
option_parser.parse!

if ARGV.empty?
  puts option_parser
  exit(-1)
end

twitter_username = ARGV[0]
path_to_json_file = File.dirname(File.expand_path(__FILE__)) + "/data/#{twitter_username}.json"
tweetsStore = TweetsStore.new(path_to_json_file)
downloader = TwitterDownloader.new(twitter_username)

earliest_tweet_id = tweetsStore.lowest_tweet_id
if earliest_tweet_id.nil?
  puts "No tweets stored so far. Trying to download all your tweets."
else
  puts "Trying to download tweets older than id: #{ earliest_tweet_id }."
end

past_tweets_downloaded = 0
begin
  max_tweet_id = nil
  earliest_tweet_id = tweetsStore.lowest_tweet_id
  if (!earliest_tweet_id.nil?)
    max_tweet_id = earliest_tweet_id.to_i - 1
  end

  tweets = downloader.download_tweets_earlier_than(max_tweet_id)
  tweets_downloaded = tweets.count
  if tweets.empty?
    puts "Downloaded no more tweets."
  else
    past_tweets_downloaded = past_tweets_downloaded + tweets_downloaded
    puts "Downloaded #{ tweets_downloaded } tweets from #{ tweets.first['id'] } to #{ tweets.last['id'] }."
  end
  tweetsStore.append_tweets(tweets)
end while tweets_downloaded > 0
puts "Past tweets downloaded: #{ past_tweets_downloaded }"

most_recent_tweet_id = tweetsStore.highest_tweet_id
if !most_recent_tweet_id.nil?
  puts "Trying to download tweets later than id: #{ most_recent_tweet_id }"

  recent_tweets_downloaded = 0
  begin
    since_tweet_id = tweetsStore.highest_tweet_id
    tweets = downloader.download_tweets_later_than(since_tweet_id)
    tweets_downloaded = tweets.count
    if tweets.empty?
      puts "Downloaded no more tweets."
    else
      recent_tweets_downloaded = recent_tweets_downloaded + tweets_downloaded
      puts "Downloaded #{ tweets_downloaded } tweets from #{ tweets.first['id'] } to #{ tweets.last['id'] }."
    end
    tweetsStore.prepend_tweets(tweets)
  end while tweets_downloaded > 0
  puts "New tweets downloaded: #{ recent_tweets_downloaded }"
end

tweetsStore.save
puts "Total tweets stored: #{ tweetsStore.tweets.count }"