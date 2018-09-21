

local M = {}


local config    = require "config"
local httputils = require "httputils"
local user      = require "user"


function M.api_req(prefix, suffix)

    local api_url = config.get_value_for("api_url") 
    local fetch_url
    local query_string


    if user.get_logged_in_flag() == true then
        local author_name  = user.get_logged_in_author_name()
        local session_id   = user.get_logged_in_session_id()
        local rev          = user.get_logged_in_rev()
        query_string = "?author=" .. author_name .. "&session_id=" .. session_id .. "&rev=" .. rev 
        fetch_url = api_url .. prefix .. query_string .. suffix
    else
        query_string = "?author=&session_id=&rev="
        fetch_url = api_url .. prefix .. query_string .. suffix
    end

    local response_body, status_code, headers_table, status_string = httputils.get_unsecure_web_page(fetch_url)

    return response_body, status_code
end


return M


