#!/usr/bin/ruby

require 'cinch'
require 'redis'

require 'open-uri'

CHANNELS = ['#lesswrong', '#lw-bitcoin', '#bitcoin-hidden', '##hplusroadmap', '##biohack', '##neuroscience']

uri = URI.parse ENV["REDISCLOUD_URL"]
$redis = Redis.new host: uri.host, port: uri.port, password: uri.password

$cinch = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.freenode.org'
    c.channels = CHANNELS
    c.nick = 'drewbot'
  end

  on :message do |m|
    if CHANNELS.include? m.channel
      $redis.append m.channel, "#{m.time} #{m.user} #{m.message}\r\n"
    end
  end

  on :private do |m|
    if m.user.nick == 'drewbug'
      m.reply "sending email logs! yay!"
      $emailjob.perform
    end
  end
end

#####

require 'action_mailer'

ActionMailer::Base.smtp_settings = {
    :port =>           '587',
    :address =>        'smtp.mandrillapp.com',
    :user_name =>      ENV['MANDRILL_USERNAME'],
    :password =>       ENV['MANDRILL_APIKEY'],
    :domain =>         'heroku.com',
    :authentication => :plain
}

ActionMailer::Base.delivery_method = :smtp

class DrewbotMailer < ActionMailer::Base
  def drewbot
    body = String.new

    $redis.keys.each do |key|
      body << "==== #{key} ===="
      body << "\r\n"

      body << $redis.getset(key, "")
      body << "\r\n"

      body << "\r\n"
    end

    mail(from: ENV['MANDRILL_USERNAME'],
         to: "drewbot@drewb.ug",
         body: body,
         content_type: "text/plain",
         subject: "drewbot Logs")
  end
end

#####

require 'sucker_punch'
require 'active_support/core_ext'

class EmailJob
  include SuckerPunch::Job

  def start
    after(Time.now.seconds_until_end_of_day) { perform() }
  end

  def perform
    DrewbotMailer.drewbot.deliver
  end
end

$emailjob = EmailJob.new

#####

$emailjob.start
$cinch.start
