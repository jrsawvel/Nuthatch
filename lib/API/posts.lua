
local M = {}


local cgilua = require "cgilua"


local rj         = require "returnjson"
local create     = require "create"
local read       = require "read"
local update     = require "update"
local poststatus = require "poststatus"
local deleted    = require "deleted"
local stream     = require "stream"


function M.posts(a_params)

    local page_num = 0
    if cgilua.QUERY.page ~= nil then
        page_num = cgilua.QUERY.page
    end

    local request_method = cgilua.servervariable("REQUEST_METHOD")

    if request_method == "GET" then
        if cgilua.QUERY.action ~= nil and ( cgilua.QUERY.action == "delete" or cgilua.QUERY.action == "undelete" )  then
            poststatus.change_post_status(cgilua.QUERY.action, a_params[2])
        elseif cgilua.QUERY.deleted ~= nil and cgilua.QUERY.deleted == "yes" then
            deleted.show_deleted_posts()
        elseif a_params[2] ~= nil then
            read.get_post(a_params[2]) -- in this app, id = the slug or post uri 
        else
            stream.read_stream(page_num)
        end
    elseif request_method == "POST" then
        create.create_post()
    elseif request_method == "PUT" then
        update.update_post()
    else
        rj.report_error("400", "Not found", "Invalid request " .. request_method .. ".")
    end
end


return M


