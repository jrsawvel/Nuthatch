
local M = {}

local luchia  = require "luchia"
local cgilua  = require "cgilua"

local config = require "config"
local rj     = require "returnjson"


-- {"status":"active","_id":"ef077e45e3810107ab9821d8df003efc","_rev":"2-0950378625a6dc556387ccaa03861bd2","created_at":"2018\/06\/20 09:04:20","updated_at":"2018\/06\/20 09:04:43","type":"session_id"}


function M.logout()

    local author_name = cgilua.QUERY.author
    local session_id  = cgilua.QUERY.session_id

    local doc
    local config_author_name = config.get_value_for("author_name")

    if config_author_name ~= author_name then
        rj.report_error("400", "Unable to logout.", "Invalid info submitted.")
    else
        doc = luchia.document:new(config.get_value_for("database_name"))

        local response = doc:retrieve(session_id)

        if response == nil then
            rj.report_error("400", "Unable to logout.", "Invalid info submitted.")
        else
            local session_id_info = response
            local id     = session_id_info._id
            local rev    = session_id_info._rev
            local status = session_id_info.status

            if status ~= "active" or id ~= session_id then
                rj.report_error("400", "Unable to logout.", "Invalid info submitted.")
            else
                session_id_info.status = "deleted"   

                response = doc:update(session_id_info, id, rev)
                
                if response == nil or response.ok == false then
                    rj.report_error("400", "Unable to update session doc.", "Logout unsuccessful.")
                else
                    local hash = {
                        logged_out = true
                    }
                    rj.success(hash)
                end
            end
        end 

    end
end



return M

