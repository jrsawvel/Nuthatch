
-- curl -XGET  http://127.0.0.1:9200/scaupdvlp1/scaupdvlp1/_search -d '{"query" : { "term" : {"markup" : "scarf" }} }'


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

local url = "http://127.0.0.1:9200/" .. db .. "/" .. db .. "/_search"


-- search the markup field for posts that contain "scarf" OR "wren"
--[[
local request_body = { 
  query = {
    match = {
      markup = "scarf wren"
    }
  }
}
]]


-- exact phrase match. it's case insensitive.
local request_body = { 
  query = {
    match_phrase = {
      markup = "scarf for mom"
    }
  }
}


local json_text = cjson.encode(request_body)
-- print(json_text)
-- os.exit()


local response_body = {}

local res, status_code, response_headers, status_string = http.request{
    url = url,
    method = "GET", 
    headers = 
      {
          ["User-Agent"] = "Mozilla/5.0 (X11; CrOS armv7l 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36",
          ["Content-Type"] = "application/json",
          ["Content-Length"] = #json_text
      },
    source = ltn12.source.string(json_text),
    sink = ltn12.sink.table(response_body)
}

response_body = table.concat(response_body)

print("status code = " .. status_code) -- should be: 200

print(response_body)


--[[

if type(response_headers) == "table" then
  for k, v in pairs(response_headers) do 
    print(k, v)
  end
end

if type(response_body) == "table" then
    local returned_json_text = table.concat(response_body)
    print(returned_json_text)
    local value = cjson.decode(returned_json_text)
    for k,v in pairs(value) do
        print(k,v)
    end
else
  print("Not a table:", type(response_body))
end

]]
