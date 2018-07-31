
local M = {}

local cjson   = require "cjson"

local page      = require "page"
local display   = require "display"
local config    = require "config"
local utils     = require "utils"
local user      = require "user"
local fetch     = require "fetch"



function _change_post_status(action, post_id)

    local response_body, status_code = fetch.api_req("/posts/" .. post_id, "&action=" .. action)

    local h_json = cjson.decode(response_body)

    if status_code >= 200 and status_code < 300 then
        local url = config.get_value_for("home_page") .. "/deleted"
        display.redirect_to(url)
    elseif status_code >= 400 and status_code < 500 then
        if status_code == 401 then
            display.report_error("user", "Unable to complete action.", "You are not logged in.")
        else
            display.report_error("user", h_json["user_message"], h_json["system_message"])
        end
    else
        display.report_error("user", "Unable to complete request.", "Invalid response code returned from API.")
    end

end



function M.delete_post(a_params)
    local post_id = a_params[2]
    _change_post_status("delete", post_id)
end



function M.undelete_post(a_params)
    local post_id = a_params[2]
    _change_post_status("undelete", post_id)
end


return M
