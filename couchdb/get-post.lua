

-- this will return all of the json that's used to represent the document for the post id retrieved.


local luchia  = require "luchia"
local cjson   = require "cjson"


local doc = luchia.document:new("veerydvlp1")

local response = doc:retrieve("info")

if response == nil then
    print("document not found.")
else
    local json_text = cjson.encode(response)
    print(json_text)
end


print("\n\n" .. response.post_status)

