

local luchia  = require "luchia"
local cjson   = require "cjson"

local cdb_hash = {
  type              =  'session_id',
  created_at        =  '2018/06/20 14:04:38',
  updated_at        =  '2018/06/20 14:04:38',
  status            =  'pending'
}

local doc = luchia.document:new("veerydvlp1")

-- lucia create api call returns: responsedata, responsecode, headers, status_code.
local responsedata, responsecode, headers, status_code = doc:create(cdb_hash, "jrs")

-- in couchdb, id must be unique. if it's not, then the following info is returned:
--    responsecode = 409
--    status_code = HTTP/1.1 409 Conflict

print("responsecode = " .. responsecode)
print("status_code = " .. status_code)
print("\n")
for k,v in pairs(headers) do print(k,v) end

if responsecode < 300 then
    local json_text = cjson.encode(responsedata)
    print(json_text)
    print("rev = " .. responsedata.rev)
end

