local M = {}


local cjson = require "cjson"
local entities = require "htmlEntities"

local display   = require "display"
local page      = require "page"
local config    = require "config"
local httputils = require "httputils"
local utils     = require "utils"
local user      = require "user"
local cache     = require "rediscache"
local getpost   = require "showpost"



function M.show_post_to_edit(a_params)

    local author_name  = display.get_cookie("author_name")
    local session_id   = display.get_cookie("session_id")
    local rev          = display.get_cookie("rev")

    local post_id = ""

    if author_name == nil or session_id == nil or rev == nil then
        display.report_error("user", "Cannot perform action.", "You are not logged in.")
    else
        post_id = a_params[2]
 
        local query_string = "?author=" .. author_name .. "&session_id=" .. session_id .. "&rev=" .. rev
        query_string = query_string .. "&text=markup"

        local api_url = config.get_value_for("api_url") .. "/posts/" .. post_id

        api_url = api_url .. query_string
     
        local response_body, status_code, headers_table, status_string = httputils.get_unsecure_web_page(api_url)

        local h_json = cjson.decode(response_body)
        local post = h_json.post

        if status_code >= 200 and status_code < 300 then
            page.set_template_name("updatepostform")
            page.set_template_variable("slug", post.slug)
            page.set_template_variable("title", post.title)
            page.set_template_variable("rev", post._rev)
            page.set_template_variable("markup", entities.decode(post.markup))    
            display.web_page(page.get_output("Updating Post "))
        elseif status_code >= 400 and status_code < 500 then
            display.report_error("user", h_json["user_message"], h_json["system_message"])
        else
            display.report_error("user", "Unable to complete request.", "Invalid response code returned from API. " .. h_json["user_message"] .. " - " .. h_json["system_message"])
        end

    end
end



function M.update_post()

    local author_name  = user.get_logged_in_author_name()
    local session_id   = user.get_logged_in_session_id()

    local submit_type     = display.get_POST_value_for("sb")  --  Preview or Update
    local post_id         = display.get_POST_value_for("post_id")
    local rev             = display.get_POST_value_for("rev")
    local original_markup = display.get_POST_value_for("markup")

    -- perl version
    --   my $markup = Encode::decode_utf8($original_markup);
    --   $markup    = HTML::Entities::encode($markup,'^\n^\r\x20-\x25\x27-\x7e');

    local markup = utils.encode_extended_ascii(original_markup)
  
    local api_url = config.get_value_for("api_url")

    local post_url = api_url .. "/posts"

    local request_body = { 
        author      = author_name,
        session_id  = session_id,
        submit_type = submit_type,
        markup      = markup,
        post_id     = post_id,
        rev         = rev
    }
    local json_text = cjson.encode(request_body)
   
    local response_body, status_code, headers_table, status_string = httputils.unsecure_json_put(post_url, json_text)

    local h_json = cjson.decode(response_body)

    if status_code >= 200 and status_code < 300 then
        if submit_type == "Preview" then
            page.set_template_name("updatepostform")
            page.set_template_variable("previewingpost", true)
            page.set_template_variable("slug", post_id)
            page.set_template_variable("rev", rev)
            if h_json.post_type == "article" then
                page.set_template_variable("title", h_json.title)
            end
            page.set_template_variable("html", h_json.html)
            page.set_template_variable("markup", original_markup)
            display.web_page(page.get_output("Previewing updated post " .. h_json.title))
        elseif submit_type == "Update" then
            cache.cache_page(h_json.post_id, getpost.show_post({h_json.post_id}, "private"))
            display.redirect_to(config.get_value_for("home_page") .. "/" .. post_id)
        else 
            display.report_error("user", "Unable to complete request.", "Invalid submit type: " .. submit_type .. ".")
        end
    elseif status_code >= 400 and status_code < 500 then
        display.report_error("user", h_json["user_message"], h_json["system_message"])
    else
        display.report_error("user", "Unable to complete request.", "Invalid response code returned from API. " .. h_json["user_message"] .. " - " .. h_json["system_message"])
    end

end


function M.show_editor_update(a_params)

    local author_name  = display.get_cookie("author_name")
    local session_id   = display.get_cookie("session_id")
    local rev          = display.get_cookie("rev")

    local post_id = ""

    if author_name == nil or session_id == nil or rev == nil then
        display.report_error("user", "Cannot perform action.", "You are not logged in.")
    else
--        local post_id = a_params[2]   -- in this app, id = the slug or post uri 
--        local original_slug = post_id

        if #a_params > 2 then
            for i=2, #a_params do
                post_id = post_id .. a_params[i]
                if i < #a_params then
                    post_id = post_id .. "/"
                end
            end    
        else
            post_id = a_params[2]   -- in this app, id = the slug or post uri 
        end

        local original_slug = a_params[#a_params]
 
        local query_string = "?author=" .. author_name .. "&session_id=" .. session_id .. "&rev=" .. rev
        query_string = query_string .. "&text=markup"

        local api_url = config.get_value_for("api_url") .. "/posts/" .. post_id

        api_url = api_url .. query_string

-- display.report_error("user", "debug", api_url)
-- if true then
-- return
-- end

        local response_body, status_code, headers_table, status_string = httputils.get_unsecure_web_page(api_url)

        local h_json = cjson.decode(response_body)

        if status_code >= 200 and status_code < 300 then
            page.set_template_name("tanager")
            page.set_template_variable("action", "updateblog")
            page.set_template_variable("api_url", config.get_value_for("api_url"))
            page.set_template_variable("markup", entities.decode(h_json.markup))    
            page.set_template_variable("post_id", original_slug)
            display.web_page(page.get_output_min("Editing - Editor "))
        elseif status_code >= 400 and status_code < 500 then
            display.report_error("user", h_json["user_message"], h_json["system_message"])
        else
            display.report_error("user", "Unable to complete request.", "Invalid response code returned from API. " .. h_json["user_message"] .. " - " .. h_json["system_message"])
        end

    end

end


return M

