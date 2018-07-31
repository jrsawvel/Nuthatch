

local M = {}



local cjson   = require "cjson"

local page      = require "page"
local display   = require "display"
local config    = require "config"
local utils     = require "utils"
local user      = require "user"
local fetch     = require "fetch"



function M.show_post(a_params, creation_type)

    -- since not using an id number, then param 1 equals slug or id for post
    local post_id = a_params[1]

    local response_body, status_code = fetch.api_req("/posts/" .. post_id,  "&text=html")

    local h_json = cjson.decode(response_body)

    if status_code >= 200 and status_code < 300 then
        local post = h_json.post
        page.set_template_name("post")
        page.set_template_variable("loggedin", user.get_logged_in_flag())
        page.set_template_variable("html", post.html)
        page.set_template_variable("author", post.author)
        page.set_template_variable("created_at", utils.format_date_time(post.created_at))
        page.set_template_variable("updated_at", utils.format_date_time(post.updated_at))
        if post.reading_time > 0 then
            page.set_template_variable("show_reading_time", true)
        else
            page.set_template_variable("show_reading_time", false)
        end
        page.set_template_variable("reading_time", math.tointeger(post.reading_time))
        page.set_template_variable("word_count", math.tointeger(post.word_count))
        page.set_template_variable("post_type", post.post_type)
        page.set_template_variable("slug", post.slug)
        page.set_template_variable("title", post.title)
        page.set_template_variable("author_profile", config.get_value_for("author_profile"))

        if post.post_type == "article" then
            page.set_template_variable("show_title", true)
        end

        if post.created_at ~= post.updated_at then
            page.set_template_variable("modified", true)
        end

-- todo cache in memcached
-- todo check for creation type
--[[
       if ( !User::get_logged_in_flag() and Config::get_value_for("write_html_to_memcached") ) {
            CacheHtml::cache_page($t->create_html($post->{'title'}), $post_id);
        } elsif ( $creation_type eq "private" ) {
            return $t->create_html($post->{'title'});
        } 
]]
       
        local html_output = page.get_output(post.title)
        display.web_page(html_output) 
    elseif status_code >= 400 and status_code < 500 then
        display.report_error("user", h_json["user_message"], h_json["system_message"])
    else
        display.report_error("user", "Unable to complete request.", "Invalid response code returned from API.")
    end

end



return M
