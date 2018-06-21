
local ltn12 = require "ltn12"
local http  = require "socket.http"
local cjson   = require "cjson"
local urlcode = require "cgilua.urlcode"
local pretty = require "resty.prettycjson"


local search_string = "SCARF FOR MOM"
--      search_string = "beer"
--      search_string = "black cloister"

search_string = urlcode.escape(search_string)

local db = "scaupdvlp1"

local url = "http://127.0.0.1:9200/" .. db .. "/" .. db .. "/_search?size=10&q=%2Btype%3Apost+%2Bpost_status%3Apublic+%2Bmarkup%3A" .. search_string



print(url)


local response = {}
local num, status_code, headers, status_string = http.request {
    method = "GET",
    url = url,
    sink = ltn12.sink.table(response)   
}
-- get response as string by concatenating table filled by sink
response = table.concat(response)

print(status_code) -- should be: 200

-- display un-pretty json text as one long string
-- print(response) 

-- convert json text to a lua table (hashes and arrays)
local t = cjson.decode(response)

local json_text = pretty(t, "\n", "  ")

print(json_text)

print("total hits = " .. t.hits.total)

local stream = t.hits.hits

local number_of_matches = #stream

print("number of search results = " .. number_of_matches)


print(t.hits.hits[1]._source.author)
print(t.hits.hits[1]._source.title)
print(t.hits.hits[1]._source.markup)



--[[

{
  "hits": {
    "hits": [
      {
        "_score": 1.4018872,
        "_id": "scarf-for-mom",
        "_index": "scaupdvlp1",
        "_source": {
          "reading_time": 0,
          "author": "JohnR",
          "_rev": "6-21acddf3e534e2b1bb8ac49ae3a4d00d",
          "post_type": "article",
          "post_status": "public",
          "more_text_exists": 1,
          "updated_at": "2015\/04\/17 15:29:43",
          "word_count": 83,
          "type": "post",
          "created_at": "2015\/03\/05 00:04:24",
          "_id": "scarf-for-mom",
          "title": "Scarf for Mom",
          "text_intro": " <span class=\"streamtitle\"><a href=\"\/scarf-for-mom\">Scarf for Mom<\/a><\/span> -   Finished it on Fri, Feb 27, 2015. Began it the previous weekend. Did not work on it each day.  ",
          "html": "<a name=\"Scarf_for_Mom\"><\/a>\n<h1 class=\"headingtext\"><a href=\"\/scarf-for-mom\">Scarf for Mom<\/a><\/h1>\n\n<p>Finished it on Fri, Feb 27, 2015. Began it the previous weekend. Did not work on it each day.<\/p>\n\n<p><more \/><\/p>\n\n<p>Used nearly two skeins of:<\/p>\n\n<ul>\n<li> <a href=\"http:\/\/malabrigoyarn.com\/description_sub_yarn.php?id=647\">http:\/\/malabrigoyarn.com\/description_sub_yarn.php?id=647<\/a><\/li>\n<li>633 Colorinche<\/li>\n<li>Merino Worsted<\/li>\n<li>Approx 210 yards per skein<\/li>\n<\/ul>\n\n<p>Dimensions 56 inches long and 8.5 inches wide.<\/p>\n\n<p>I used half-double crochet stitch.<\/p>\n\n<p>I crocheted lengthwise.<\/p>\n\n<p>It looks like candy. The multicolored yarn contains colors of reds, purples, blues, and greens.<\/p>\n\n<p>I mailed it on Wed, Mar 4, 2015.<\/p>\n\n<p> <a href=\"\/tag\/crochet\">#crochet<\/a> <a href=\"\/tag\/wool\">#wool<\/a> <a href=\"\/tag\/yarn\">#yarn<\/a> <a href=\"\/tag\/merino\">#merino<\/a> <a href=\"\/tag\/scarf\">#scarf<\/a><\/p>",
          "markup": "h1. Scarf for Mom\r\n\r\nFinished it on Fri, Feb 27, 2015. Began it the previous weekend. Did not work on it each day.\r\n\r\nmore.\r\n\r\nUsed nearly two skeins of:\r\n\r\n*  http:\/\/malabrigoyarn.com\/description_sub_yarn.php?id=647\r\n* 633 Colorinche\r\n* Merino Worsted\r\n* Approx 210 yards per skein\r\n\r\nDimensions 56 inches long and 8.5 inches wide.\r\n\r\nI used half-double crochet stitch.\r\n\r\nI crocheted lengthwise.\r\n\r\nIt looks like candy. The multicolored yarn contains colors of reds, purples, blues, and greens.\r\n\r\nI mailed it on Wed, Mar 4, 2015.\r\n\r\n #crochet #wool #yarn #merino #scarf",
          "tags": [
            "crochet",
            "wool",
            "yarn",
            "merino",
            "scarf"
          ]
        },
        "_type": "scaupdvlp1"
      }
    ],
    "total": 1,
    "max_score": 1.4018872
  },
  "_shards": {
    "failed": 0,
    "successful": 5,
    "total": 5
  },
  "took": 9,
  "timed_out": false
}



total hits = 1.0
number of search results = 1


]]
