

local ltn12 = require "ltn12"
local http  = require "socket.http"
local https = require "ssl.https"

local url = 'http://127.0.0.1:5984/veerydvlp1/_design/views/_view/tag_search?descending=true&limit=16&skip=0&startkey=["wiki", {}]&endkey=["wiki"]'


url = 'http://127.0.0.1:5984/veerydvlp1/_design/views/_view/tag_search?descending=true&limit=16&skip=0&startkey=[%22wiki%22,%20%7B%7D]&endkey=[%22wiki%22]' 

print(url)

local response = {}
local num, status_code, headers, status_string = http.request {
    method = "GET",
    url = url,
    sink = ltn12.sink.table(response)   
}
-- get response as string by concatenating table filled by sink
response = table.concat(response)

print(status_code)
print(response)


