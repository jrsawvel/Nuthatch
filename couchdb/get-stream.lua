


local ltn12 = require "ltn12"
local http  = require "socket.http"
local cjson   = require "cjson"


local url = 'http://127.0.0.1:5984/veerydvlp1/_design/views/_view/stream/?descending=true&limit=16'

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

-- convert json text to a lua table (hashes and arrays)
local t = cjson.decode(response)

-- table of the stream of posts
local stream = t.rows

local row_count = #stream

print(row_count)

print("row 16 id = " .. stream[16].id)

print("row 16 intro text = " .. stream[16].value.text_intro)


--[[ example json for a single post of the returned stream

{
  "id":"testing-funky-chars-from-within-js-editor",
  "key":"2015/06/11 18:45:39",
  "value":
    {
      "slug":"testing-funky-chars-from-within-js-editor",
      "text_intro":"testing funky chars from within js editor    When you have a built-up snowpack, it tends to build upon itself, said Karen Clark, a meteorologist with the National Weather Service office in Cleveland. Theres such an extensive supply of cold air.    updated 1.  updated 2.  updated 3 from the html text ...",
      "more_text_exists":1,
      "tags":[],
      "post_type":"note",
      "author":"JohnR",
      "updated_at":"2015/06/11 18:45:39",
      "reading_time":0
    }
}



another example. this time, an article post.


{
  "id":"our-first-snowfall-may-occur-this-weekend",
  "key":"2015/06/11 19:26:40",
  "value":
    {
      "slug":"our-first-snowfall-may-occur-this-weekend",
      "text_intro":" <span class=\"streamtitle\"><a href=\"/our-first-snowfall-may-occur-this-weekend\">Our first snowfall may occur this weekend</a></span> -   Based upon the Wed evening, Oct 29, 2014 forecast by the National Weather Service, Toledo may receive its first snowflakes and its first measurable snowfall of the season on Sat morning, Nov 1.  Oct 31, 2014 morning update: We may receive up to a  ...",
      "more_text_exists":1,
      "tags":["snow","rain","forecast"],
      "post_type":"article",
      "author":"JohnR",
      "updated_at":"2015/06/11 19:26:40",
      "reading_time":7
    }
}



]]


