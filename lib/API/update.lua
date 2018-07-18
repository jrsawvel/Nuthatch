

local M = {}


local luchia  = require "luchia"
local cgilua  = require "cgilua"
local urlcode = require "cgilua.urlcode"
local cjson   = require "cjson"
-- local rex     = require "rex_pcre"


local auth    = require "auth"
local utils   = require "utils"
local rj      = require "returnjson"
local title   = require "title"
local format  = require "format"
local config  = require "config"
local files   = require "files"



function _get_entire_post(post_id)

    local db = config.get_value_for("database_name")

    local doc = luchia.document:new(db)

    local responsedata, responsecode, headers, status_code = doc:retrieve(post_id)

    if responsedata == nil or responsecode >= 300 then
        rj.report_error("404", "Unable to get post.", "Post ID " .. post_id .. " was not found. Status code = " .. status_code) 
        return nil
    else
        return responsedata 
    end
end



function M.update_post()

    local json_text = cgilua.POST[1] -- PUT request handled by my modified version of cgilua

    local hash = cjson.decode(json_text)

    local logged_in_author_name = hash.author
    local session_id            = hash.session_id
    local rev                   = hash.rev
    local author                = config.get_value_for("author_name")
    local post_id               = hash.post_id
   
    if auth.is_valid_login(logged_in_author_name, session_id, rev) == false then 
        rj.report_error("400", "Unable to peform action.", "You are not logged in.")
    else
        local submit_type = hash.submit_type
        if submit_type ~= "Preview" and submit_type ~= "Update" then
            rj.report_error("400", "Unable to process post.", "Invalid submit type given.")
        else
           local original_markup = hash.markup
           local markup = utils.trim_spaces(original_markup)

           if markup == nil or markup == "" then
               rj.report_error("400", "Invalid post.", "You must enter text.")
           else
               local form_type = hash.form_type
               if form_type ~= nil and form_type == "ajax" then
                   markup = urlcode.unescape(markup) 
                   markup = utils.encode_extended_ascii(markup) 
               end

               local t = title.process(markup)
               if t.is_error then
                   rj.report_error("400", "Error creating post.", t.error_message)
               else
                   -- 11Jul2018 - these two lines came from my Sora code. 
                   -- might add the custom CSS option later.
                   -- local page_data   = format.extract_css(t.after_title_markup)
                   -- local html        = format.markup_to_html(page_data.markup)

                   local post_title  = t.title
                   local post_type   = t.post_type
                   local slug        = post_id
                   local html        = format.markup_to_html(t.after_title_markup)

                   local post_hash = {}

                   if submit_type == "Preview" then
                       post_hash.html = html
                       post_hash.title = post_title
                       post_hash.post_type = post_type
                       rj.success(post_hash)
                   else
                       local post_stats      = format.calc_reading_time_and_word_count(html) -- returns hash
                       local more_text_info  = format.get_more_text_info(markup, html, slug, post_title) -- returns hash 
                       local tags            = format.create_tag_array(markup)
                       local updated_at      = utils.create_datetime_stamp()

                       local existing_post   = _get_entire_post(post_id) -- get doc from db. func returns table.

                       if existing_post._rev ~= rev then
                           rj.report_error("400", "Unable to update post.", "Invalid rev information provided. existing_post rev = " .. existing_post._rev .. " submitted rev = " .. rev)
                       else
                           existing_post.markup           = markup
                           existing_post.title            = post_title
                           existing_post.markup           = markup
                           existing_post.html             = html
                           existing_post.text_intro       = more_text_info.text_intro
                           existing_post.more_text_exists = more_text_info.more_text_exists
                           existing_post.post_type        = post_type
                           existing_post.tags             = tags
                           existing_post.updated_at       = updated_at
                           existing_post.reading_time     = post_stats.reading_time
                           existing_post.word_count       = post_stats.word_count

                           local db = config.get_value_for("database_name")

                           local doc = luchia.document:new(db)

                           -- here slug = post_id which is _id in couchdb 
                           local responsedata, responsecode, headers, status_code = doc:update(existing_post, post_id, rev)
                        
                           if responsecode > 399 then
                               rj.report_error("400", "Unable to update post.", status_code)
                           else
                               if config.get_value_for("save_markup_to_file_system") then
                                   local files_rc = files.save_markup("update", existing_post)
                                   if files_rc == true then
                                       local return_hash = {
                                           post_id = slug,
                                           rev     = responsedata.rev,
                                           html    = html
                                       }
                                       rj.success(return_hash)
                                   else
                                       rj.report_error("400", "Unable to save markup to file system.", "")
                                   end
                               else
                                   local return_hash = {
                                       post_id = slug,
                                       rev     = responsedata.rev,
                                       html    = html
                                   }
                                   rj.success(return_hash)
                               end
                           end
                       end
                   end    

--                   rj.report_error("400", t.title .. "<br>" .. t.slug .. "<br><br>" .. t.after_title_markup, t.post_type .. "<br><br>" .. page_data.custom_css .. "<br><br><h3>markup</h3>" .. page_data.markup)
-- rj.report_error("400", "HTML=", html)
               end
           end
        end 
    end

end



return M
