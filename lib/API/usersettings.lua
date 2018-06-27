
local M = {}


local luchia  = require "luchia"
local cgilua  = require "cgilua"
local cjson   = require "cjson"

local auth   = require "auth"
local rj     = require "returnjson"
local utils  = require "utils"
local author = require "author"
local config = require "config"


-- despite the cgilua.POST[1] code, this function is processing a PUT (update) request.
-- originally, the cgilua module could not process PUT requests. i modified cgilua code
-- to store PUT request info into the POST array. i should fork cgilua because i had to 
-- make other minor changes to cgilua to support my needs, such as adding the ability to
-- return application/json text. 27june2018

-- the client sends the following JSON in a PUT request
--[[
{
    "author": "MrX", 
    "session_id": "5aabbe7c5d810346cb", 
    "id": "MrX",
    "rev": "45454554", 
    "new_email" : "new@new.com", 
    "old_email" : "old@old.com"
}
]]
function M.update_author_info()

    if cgilua.POST[1] == nil then
        rj.report_error("400", "Unable to process PUT request.", "Missing information.")
    else
        local json_text = cgilua.POST[1] 

        local inputs = cjson.decode(json_text)

        if auth.is_valid_login(inputs.author, inputs.session_id) ~= true then
            rj.report_error("400", "Unable to perform action.", "You are not logged in.")
        else
            local author_info = author.get(inputs.author)
 
            local t = _check_inputs(inputs, author_info)
                
            if t.new_email == nil then
                rj.report_error("400", "Unable to perform action.", t.err_msg)
            else
                author_info.email = t.new_email
                local db = config.get_value_for("database_name")
                local doc = luchia.document:new(db)
                local response = doc:update(author_info, author_info._id, author_info._rev)
                if response == nil or response.ok == false then
                    local jr = cjson.encode(response)
                    rj.report_error("400", "Unable to update author doc.", "Invalid author info submitted.")
                else
                    rj.success({})
                end
            end
        end
    end
end



function _check_inputs(t_i, t_a)

    local old_email = utils.trim_spaces(t_i.old_email)
    local new_email = utils.trim_spaces(t_i.new_email)

    if t_a == nil then
        return {new_email = nil, err_msg = "Author not found."}
    elseif t_i.session_id ~= t_a.current_session_id then
        return {new_email = nil, err_msg = "You are not logged in."}
    elseif old_email:lower() == new_email:lower() then
        return {new_email = nil, err_msg = "The provided old and new email addresses are identical."}
    elseif old_email ~= t_a.email then
        return {new_email = nil, err_msg = "The provided old email address does not match the email address contained in the database."}
    elseif t_i.id ~= t_a._id then
        return {new_email = nil, err_msg = "Invalid user information provided. (A)"}
    elseif t_i.rev ~= t_a._rev then
        return {new_email = nil, err_msg = "Invalid user information provided. (B)"}
    else
        return {new_email = new_email}
    end   

    -- todo: need to add check for valid email syntax to utils module and use it here.
end



function M.get_user_info(author_name)

    local logged_in_author_name = cgilua.QUERY.author
    local session_id = cgilua.QUERY.session_id

    local doc

    if author_name == nil then
        rj.report_error("400", "Unable to complete action.", "Author name was missing.")
    else
        local is_logged_in = false
   
        if auth.is_valid_login(logged_in_author_name, session_id) == true then
            is_logged_in = true
        end

        local author_info = author.get(author_name)
 
        if author_info == nil then
            rj.report_error("400", "Unable to complete action.", "Author not found. " .. author_name) 
        else
            if is_logged_in == false then
                author_info._id = nil
                author_info._rev = nil
                author_info.email = nil
                author_info.current_session_id = nil
            end
             
            author_info.is_logged_in = is_logged_in

            rj.success(author_info)
        end
    end
end


return M


