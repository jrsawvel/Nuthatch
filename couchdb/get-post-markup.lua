

-- this will use a javascript view that was added to the database to retrieve the markup for the doc id.

local ltn12 = require "ltn12"
local http  = require "socket.http"
local cjson   = require "cjson"


local url = 'http://127.0.0.1:5984/scaupdvlp1/_design/views/_view/post_markup?key="info"'

local response = {}
local num, status_code, headers, status_string = http.request {
    method = "GET",
    url = url,
    sink = ltn12.sink.table(response)   
}
-- get response as string by concatenating table filled by sink
response = table.concat(response)

print(status_code) -- should be: 200

print(response)

print("\n\n")

local t = cjson.decode(response)

local post = t.rows[1].value

print(post.markup)

