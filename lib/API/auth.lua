
local M = {}


local luchia  = require "luchia"
local cjson   = require "cjson"

local config = require "config"
local utils  = require "utils"



local function _get_session_id_for(author_name)

    local db = config.get_value_for("database_name")

    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/author?key="' .. author_name .. '"'

    local response = utils.get_unsecure_web_page(url)

    local t = cjson.decode(response)

    local author_info = t.rows[1].value

    return author_info.current_session_id

end



function M.is_valid_login(submitted_author_name, submitted_session_id)

    local author_name = config.get_value_for("author_name")

    if submitted_author_name ~= author_name then
        return false 
    else
        local current_session_id = _get_session_id_for(author_name) -- from the user doc

        if submitted_session_id ~= current_session_id then
            return false
        else
            -- ensure that the current_session_id is active in the session_id doc
            local doc = luchia.document:new(config.get_value_for("database_name"))

            local session_info = doc:retrieve(current_session_id)

            if session_info == nil then
                return false
            else
                if session_info.status == "active" then
                    return true
                else
                    return false
                end
            end
        end
    end
end
             


return M

