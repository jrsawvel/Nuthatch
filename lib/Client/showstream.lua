
local M = {}


local cjson   = require "cjson"

local page      = require "page"
local display   = require "display"
local config    = require "config"
local utils     = require "utils"
local httputils = require "httputils"
local user      = require "user"




function M.show_search_form(a_params)
    page.set_template_name("searchform")
    page.set_template_variable("css_dir_url", config.get_value_for("css_dir_url"))
    local html_output = page.get_output("Search Form")
    display.web_page(html_output) 
end



function M.show_stream(a_params, creation_type)

    local max_entries = config.get_value_for("max_entries_on_page")

    local query_string = "/"

    local page_num = 1

    if #a_params > 1 then
        if utils.is_numeric(a_params[2]) then
            page_num = math.tointeger(a_params[2])
            if page_num > 1 then
                query_string = query_string .. "?page=" .. page_num
            end
        end
    end

    local api_url = config.get_value_for("api_url") .. "/posts" .. query_string

    local response_body, status_code, headers_table, status_string = httputils.get_unsecure_web_page(api_url)

    local h_json = cjson.decode(response_body)
 
    if status_code >= 400 and status_code < 500 then
        display.report_error("user", h_json["user_message"], h_json["system_message"])
    else
        local next_link_bool = h_json.next_link_bool
        local stream         = h_json.posts
        local len = #stream

        local posts = {}

        -- posible todo: 
        -- remove this code block. should this be done on the API side at create/update article time?
        -- if yes, then the html-based tag list string would be another key-value store in the doc.

        local ctr = 0

        for i=1, #stream do
            if stream[i].post_type == "article" then
                stream[i].show_title = true
            end

            if stream[i].more_text_exists == 1 then
                stream[i].more_text_exists = true
            else
                stream[i].more_text_exists = false
            end

            if stream[i].reading_time > 0 then
                stream[i].show_reading_time = true
                stream[i].reading_time = math.tointeger(stream[i].reading_time) 
            else
                stream[i].show_reading_time = false
            end

            if stream[i].tags ~= nil and #stream[i].tags > 0 and string.len(stream[i].tags[1]) > 0 then
                local tags = stream[i].tags
                local tag_list = ""
                for t=1, #tags do
                    tag_list = tag_list .. '<a href="/tag/' .. tags[t] .. '">#' .. tags[t] .. '</a> '
                end
                stream[i].tag_list = tag_list
           end

           stream[i].tags = nil

           table.insert(posts, stream[i])

           ctr = ctr +1
        
           if ctr >= max_entries then
               break
           end
        end

        page.set_template_name("stream")

        local logged_in_flag = user.get_logged_in_flag()
        if logged_in_flag == false then
            page.set_template_variable("notloggedin", true)
        end

        page.set_template_variable("loggedin", logged_in_flag)
        page.set_template_variable("stream_loop", posts)

        if page_num == 1 then
            page.set_template_variable("not_page_one", false)
        else
            page.set_template_variable("not_page_one", true)
        end

        if len >= max_entries and next_link_bool == true then
            page.set_template_variable("not_last_page", true)
        else
            page.set_template_variable("not_last_page", false)
        end

        local previous_page_num = page_num - 1
        local next_page_num     = page_num + 1

        local next_page_url     = "/stream/" .. next_page_num
        local previous_page_url = "/stream/" .. previous_page_num

        page.set_template_variable("next_page_url", next_page_url)
        page.set_template_variable("previous_page_url", previous_page_url)

--[[
        if ( $page_num == 1 and !User::get_logged_in_flag() and Config::get_value_for("write_html_to_memcached") ) {
            CacheHtml::cache_page($t->create_html("Stream of Posts"), "homepage");
        } elsif ( $creation_type eq "private" ) {
           return $t->create_html("Stream of Posts");
        }
]]

        display.web_page(page.get_output("Stream of Posts"))

    end

end



function M.string_search(a_params)

    local search_string = nil 

    local query_string = ""

    local page_num = 1

    local request_method = os.getenv("REQUEST_METHOD")

    if request_method == "GET" then
        search_string = a_params[2]
        if search_string ~= nill then
            search_string = display.unescape(search_string)
        end

        if utils.is_numeric(a_params[3]) then
            page_num = a_params[3]
            if page_num > 1 then
                query_string = "?page=" .. page_num
            end
        end
    elseif request_method == "POST" then
        search_string = display.get_POST_value_for("keywords")  
    end

    search_string = utils.trim_spaces(search_string)

    if search_string == nil or search_string == "" then
        display.report_error("user", "Missing data.", "Enter keyword(s) to search on.")
    else
        local search_uri_str = display.escape(search_string)

        local api_url = config.get_value_for("api_url") .. "/searches/string/" .. search_uri_str .. query_string

        local response_body, status_code, headers_table, status_string = httputils.get_unsecure_web_page(api_url)

        local h_json = cjson.decode(response_body)
 
        if status_code >= 400 and status_code < 500 then
            display.report_error("user", h_json["user_message"], h_json["system_message"])
        else


        end

    end

end


return M


