

local M = {}


local luchia  = require "luchia"
local cgilua  = require "cgilua"

local auth = require "auth"
local config = require "config"
local rj     = require "returnjson"



function M.change_post_status (action, post_id)

    local logged_in_author_name = cgilua.QUERY.author
    local session_id = cgilua.QUERY.session_id

    local doc

    if auth.is_valid_login(logged_in_author_name, session_id) ~= true then
        rj.report_error("400", "Unable to perform action.", "You are not logged in.")
    else
        if action ~= "delete" and action ~= "undelete" then
            rj.report_error("400", "Unable to perform action.", "Invalid action submitted.")
        else
            local db = config.get_value_for("database_name")
            doc = luchia.document:new(db)
            local response = doc:retrieve(post_id)

            if response == nil then
                rj.report_error("400", "Unable to " .. action .. " post.", "Post ID " .. post_id .. " was not found.")
            else
                if action == "delete" then
                    response.post_status = "deleted"
                end
                if action == "undelete" then
                    response.post_status = "public"
                end

                -- if no tags, then tags is stored as an empty array [].
                -- but lua converting from json to tables and back to json saves the emtpy info
                -- as {} which appears as an object or a hash or an associative array in other languages, 
                -- which causes problems for those other languages. i probably should not store tags at all
                -- as json entry if no tags exist. then all code can test simply to see if tags exists first.
                if #response.tags < 1 then
                    response.tags[1] = ""
                end
                 
                local update_response = doc:update(response, post_id, response._rev)

                if update_response == nil or update_response.ok == false then
                    rj.report_error("400", "Unable to update article doc.", "Action " .. action .. " unsuccessful.")
                else
                    local hash = {
                        post_id = post_id,
                        action  = action
                    }
                    rj.success(hash)
                end                        

            end
        end
    end

end


return M

