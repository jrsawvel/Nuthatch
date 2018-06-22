

local luchia  = require "luchia"
local cjson   = require "cjson"

local cdb_hash = {
  type              =  'session_id',
  created_at        =  '2018/06/20 14:04:38',
  updated_at        =  '2018/06/20 14:04:38',
  status            =  'pending'
}

local doc = luchia.document:new("veerydvlp1")

local response = doc:create(cdb_hash)

local json_text = cjson.encode(response)

print(json_text)


print("rev = " .. response.rev)


