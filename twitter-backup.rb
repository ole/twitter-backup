#!/usr/bin/env ruby

require File.dirname(File.expand_path(__FILE__)) + '/config.rb'
require File.dirname(File.expand_path(__FILE__)) + '/tweets_store.rb'
require File.dirname(File.expand_path(__FILE__)) + '/twitter_downloader.rb'
require 'optparse'

# Parse command line arguments
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

# Setup
database_path = File.dirname(File.expand_path(__FILE__)) + "/data/#{twitter_username}.sqlite3"
tweetsStore = TweetsStore.new(database_path)
downloader = TwitterDownloader.new(
  TwitterBackup::Config::CONSUMER_KEY, 
  TwitterBackup::Config::CONSUMER_SECRET,
  TwitterBackup::Config::OAUTH_TOKEN, 
  TwitterBackup::Config::OAUTH_TOKEN_SECRET)
downloader.username = twitter_username

# See if there are old tweets to download (older than the oldest one we already have)
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
    puts "Downloaded #{ tweets_downloaded } tweets from #{ tweets.first['id_str'] } to #{ tweets.last['id_str'] }."
  end
  tweetsStore.append_tweets(tweets)
end while tweets_downloaded > 0
puts "Past tweets downloaded: #{ past_tweets_downloaded }"

most_recent_tweet_id = tweetsStore.highest_tweet_id
last_downloaded_tweet_id = nil
if !most_recent_tweet_id.nil?
  puts "Trying to download tweets newer than id: #{ most_recent_tweet_id }."

  recent_tweets_downloaded = 0
  begin
    tweets = downloader.download_tweets_between(most_recent_tweet_id, last_downloaded_tweet_id)
    continue_download = false
    if tweets.empty?
      puts "Downloaded no more tweets."
    else
      continue_download = true
      tweets_downloaded = tweets.count
      recent_tweets_downloaded = recent_tweets_downloaded + tweets_downloaded
      puts "Downloaded #{ tweets_downloaded } tweets from #{ tweets.first['id_str'] } to #{ tweets.last['id_str'] }."
      
      last_downloaded_tweet = tweets.last
      last_downloaded_tweet_id = last_downloaded_tweet["id"]
    end
    tweetsStore.append_tweets(tweets)
  end while continue_download
  puts "New tweets downloaded: #{ recent_tweets_downloaded }"
end

puts "Total tweets stored: #{ tweetsStore.count }"