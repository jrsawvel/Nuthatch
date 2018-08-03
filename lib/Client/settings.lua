
local M = {}

-- external modules
local cjson   = require "cjson"

-- my modules
local page      = require "page"
local display   = require "display"
local fetch     = require "fetch"
local user      = require "user"
local config    = require "config"
local httputils = require "httputils"



function M.get_user_settings()

    local response_body, status_code = fetch.api_req("/users/" .. user.get_logged_in_author_name() .. "/", "")

    local h_json = cjson.decode(response_body)

    if status_code >= 400 and status_code < 500 then
        display.report_error("user", h_json["user_message"], h_json["system_message"])
    elseif status_code >= 200 and status_code < 300 then
        page.set_template_name("settings")
        page.set_template_variable("name",      h_json.name)
        page.set_template_variable("old_email", h_json.email)
        page.set_template_variable("id",        h_json._id)
        page.set_template_variable("rev",       h_json._rev)
        local html_output = page.get_output("Update User Settings")
        display.web_page(html_output) 
    else  
        display.report_error("user", "Unable to complete request.", "Invalid response code returned from API.")
    end

end



function M.update_settings()

    local old_email = display.get_POST_value_for("old_email")
    local new_email = display.get_POST_value_for("new_email")
    local rev       = display.get_POST_value_for("rev")
    local id        = display.get_POST_value_for("id")

    if old_email == nil then
        display.report_error("user", "Invalid input.", "Old email address was missing.")
    elseif new_email == nil then
        display.report_error("user", "Invalid input.", "New email address was missing.")
    else
        local api_url = config.get_value_for("api_url")

        local post_url = api_url .. "/users"

        local request_body = { 
            old_email  = old_email,
            new_email  = new_email,
            rev        = rev,
            id         = id,
            author     = user.get_logged_in_author_name(),
            session_id = user.get_logged_in_session_id(),
            rev        = user.get_logged_in_rev()
        }

        local json_text = cjson.encode(request_body)


        local response_body, status_code, headers_table, status_string = httputils.unsecure_json_put(post_url, json_text)

        local h_json = cjson.decode(response_body)

        if status_code >= 200 and status_code < 300 then
            display.success("Updating user settings.", "Updating user settings.", "Changes were saved.")
        elseif status_code >= 400 and status_code < 500 then
            display.report_error("user", "Unable to complete request.", "Invalid data provided. " .. h_json["user_message"] .. " - " .. h_json["system_message"])
        else
            display.report_error("user", "Unable to complete request.", "Invalid response code returned from API. " .. h_json["user_message"] .. " - " .. h_json["system_message"])
        end
    end

end



return M
