
local M = {}


local cgilua = require "cgilua"


local rj     = require "returnjson"
local create = require "create"
local read   = require "read"
local update = require "update"
local poststatus = require "poststatus"


function M.posts(a_params)

    local request_method = cgilua.servervariable("REQUEST_METHOD")

    if request_method == "POST" then
        create.create_post()
    elseif request_method == "GET" then
        if cgilua.QUERY.action ~= nil and ( cgilua.QUERY.action == "delete" or cgilua.QUERY.action == "undelete" )  then
            poststatus.change_post_status(cgilua.QUERY.action, a_params[2])
        else
            read.get_post(a_params[2]) -- in this app, id = the slug or post uri 
        end
    elseif request_method == "PUT" then
        update.update_post()
    else
        rj.report_error("400", "Not found", "Invalid request " .. request_method .. ".")
    end
end


return M


