#!/usr/bin/ruby

require 'cinch'
require 'redis'

require 'open-uri'

uri = URI.parse ENV["REDISCLOUD_URL"]
$redis = Redis.new host: uri.host, port: uri.port, password: uri.password

$cinch = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.freenode.org'
    c.channels = ['#lesswrong', '#lw-bitcoin', '#bitcoin-hidden', '##hplusroadmap', '##biohack', '##neuroscience']
    c.nick = 'drewbot'
  end

  on :message do |m|
    $redis.append m.channel, "#{m.time} #{m.user} #{m.message}\n"
  end
end

$cinch.start
