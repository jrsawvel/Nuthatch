
local cjson = require "cjson"

local config = require "config"
local utils  = require "utils"


local M = {}


function M.get(author_name)

    local db = config.get_value_for("database_name")

    -- why use a javascript view over http://127.0.0.1:5984/dbname/author_name
    -- when the view does nothing advanced, compared to the simple couchdb get?  
    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/author?key="' .. author_name .. '"'

    local response = utils.get_unsecure_web_page(url)

    -- convert json text to lua's data structure format, which is a table.
    local t = cjson.decode(response)

    if t.rows[1] == nil then
        return nil
    else
        return t.rows[1].value
    end

end


--[[

couchdb author doc =

{
    "_id" : "MrX",
    "_rev" : "1-435be1729c60657a333adee6e190869d",
    "type" : "author",
    "name" : "MrX",
    "email" : "mrx@mrx.com",
    "current_session_id" : "50ff8f05c0f5d95aabbe7c5d81026436"
}


when accessing the javascript view at the command line with the curl command, couchdb returns:

{
	"total_rows": 2,
	"offset": 1,
	"rows": [{
		"id": "MrX",
		"key": "MrX",
		"value": {
			"_id": "MrX",
			"_rev": "1-38351ba5ac4c8272c7928b61810ac0b1",
			"name": "MrX",
			"current_session_id": "ef077e55e3810107ab9821d8df00a819",
			"type": "author",
			"email": "mrx@mrx.com"
		}
	}]
}

]]


return M


