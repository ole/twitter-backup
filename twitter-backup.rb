#!/usr/bin/env ruby

require File.dirname(File.expand_path(__FILE__)) + '/config.rb'
require File.dirname(File.expand_path(__FILE__)) + '/tweets_store.rb'
require File.dirname(File.expand_path(__FILE__)) + '/twitter_downloader.rb'
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
  puts "Trying to download tweets newer than id: #{ most_recent_tweet_id }"

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