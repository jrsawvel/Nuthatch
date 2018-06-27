

local M = {}

local cgilua  = require "cgilua"

local auth   = require "auth"
local config = require "config"
local rj     = require "returnjson"
local utils  = require "utils"
local cjson  = require "cjson"


function M.show_deleted_posts()

    local logged_in_author_name = cgilua.QUERY.author
    local session_id = cgilua.QUERY.session_id

    if auth.is_valid_login(logged_in_author_name, session_id) ~= true then
        rj.report_error("400", "Unable to perform action.", "You are not logged in.")
    else
        local db = config.get_value_for("database_name")

        local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/deleted_posts/?descending=true'

        local response = utils.get_unsecure_web_page(url)

        -- convert the json text into a lua table (hashes and arrays)
        local t = cjson.decode(response)

        if t.rows[1] ~= nil then
            local deleted = t.rows

            local posts = {}

            for i=1, #deleted do
                posts[i] = deleted[i].value
            end
         
            local hash = {}
            hash.posts = posts
            rj.success(hash)
        else
            local hash = {}
            hash.posts = nil
            rj.success(hash)               
        end
    end
end

return M


