

local M = {}


local cgilua = require "cgilua"
local cjson  = require "cjson"

local rj      = require "returnjson"
local auth    = require "auth"
local config  = require "config"
local utils   = require "utils"
local auth    = require "auth"



function _get_post_data(post_id, view_name)

    local db = config.get_value_for("database_name")

    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/' .. view_name .. '?key="' .. post_id .. '"'

    local response = utils.get_unsecure_web_page(url)

    local t = cjson.decode(response)

    if t.rows[1] == nil then
        rj.report_error("404", "Unable to retrieve " .. post_id .. ".", "Content does not exist.")
        return nil
    else 
        return t.rows[1].value -- the web post
    end

end



function M.get_post(post_id)

    local author_name = cgilua.QUERY.author
    local session_id  = cgilua.QUERY.session_id
    local return_type = cgilua.QUERY.text
 
    local is_logged_in = auth.is_valid_login(author_name, session_id)

    local view_name -- pertains to the javascript views added to couchdb for lookups

    -- api:
    -- posts/info              defaults to returning only the html for post id "info".
    -- posts/info?text=html    same as above
    -- posts/info?text=full    returns both html text and the markup text.
    -- posts/info?text=markup  returns only the markup, such as markdown or textile for the post.

    if return_type == "markup" then
        view_name = "post_markup"
    elseif return_type == "full" then
        view_name = "post_full"
    else
        view_name = "post_html"
    end

    local t = _get_post_data(post_id, view_name)        

    if t ~= nil then
        if is_logged_in ~= "true" then
            t._rev = ""
        end
        local hash = {}
        hash.post = t
        rj.success(hash)
    end

end



return M
