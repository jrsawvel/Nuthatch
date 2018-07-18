

-- this will return all of the json that's used to represent the document for the post id retrieved.


local luchia  = require "luchia"
local cjson   = require "cjson"


local doc = luchia.document:new("veerydvlp1")

local responsedata, responsecode, headers, status_code = doc:retrieve("info")

if responsedata == nil or responsecode >= 300 then
    print("failed to retrieve doc. " .. status_code)
else
    local json_text = cjson.encode(responsedata)
    print(json_text)
    print("\n\n" .. responsedata.post_status)
end



