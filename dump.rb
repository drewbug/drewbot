#!/usr/bin/ruby

require 'haml'
require 'redis'

require 'open-uri'

uri = URI.parse `heroku config:get REDISCLOUD_URL`
$redis = Redis.new host: uri.host, port: uri.port, password: uri.password

template = DATA.read[1...-1]
print Haml::Engine.new(template).render(Object.new, redis: $redis)

__END__

!!! 5
%html
  %body
    %div{style: 'padding-bottom: 20px'}
      - redis.keys.each do |key|
        %a{href: '#'+key.delete('#')}= key
    - redis.keys.each do |key|
      %span{id: key.delete('#')}= key
      %textarea{style: 'width: 100%', rows: 40}= redis.get key
