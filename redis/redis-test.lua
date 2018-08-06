

-- https://github.com/nrk/redis-lua


local redis = require 'redis'

local client = redis.connect('127.0.0.1', 6379)
local response = client:ping()           -- true
print(response)

client:set('usr:nrk', 10)
client:set('usr:nobody', 5)
local value = client:get('usr:nrk') 
print(value)



--[[

At the Linux command prompt:

# redis-cli

redis 127.0.0.1:6379> hset nuthatch.soupmode.com this-is-a-test "hello world 1"
(integer) 1

redis 127.0.0.1:6379> hget nuthatch.soupmode.com this-is-a-test
"hello world 1"

redis 127.0.0.1:6379> quit

]]


value = client:hget('nuthatch.soupmode.com', 'this-is-a-test')
print(value)


client:hset('nuthatch.soupmode.com', 'the-slug-is-the-page-id', "this value would store the html")
value = client:hget('nuthatch.soupmode.com', 'the-slug-is-the-page-id')
print(value)


value = client:hget('nuthatch.soupmode.com', 'special-weather-statement-06aug2018')
print(value)

