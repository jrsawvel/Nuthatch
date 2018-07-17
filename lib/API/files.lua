

local M = {}


local io    = require "io"

local config    = require "config"
local rj        = require "returnjson"



-- save markup to backup storage directory on the file system
function M.save_markup(submit_type, hash)

    local save_markup = hash.markup ..  "\n\n<!-- author: " .. hash.author .. " -->\n"
    save_markup = save_markup  ..  "<!-- created_at: "  .. hash.created_at .. " -->\n"
    save_markup = save_markup  ..  "<!-- updated_at: "  .. hash.updated_at .. " -->\n"

    -- write markup to markup storage outside of document root
    -- if "create" then the file must not exist
    local domain_name = config.get_value_for("domain_name")
    local markup_filename = config.get_value_for("markup_storage") .. "/" .. domain_name .. "-" .. hash._id .. ".markup"

    if submit_type == "create" and io.open(markup_filename, "r") ~= nil then 
        rj.report_error("400", "Unable to create markup and HTML files because they already exist.", "Change title or do an 'update'.")
        return false
    else
        local o = io.open(markup_filename, "w")
        if o == nil then
            rj.report_error("500", "Save Markup to Storage Dir. Unable to open file for write.", "Post id: " .. hash.slug .. " filename: " .. markup_filename)
            return false
        else
            o:write(save_markup .. "\n")
            o:close()
        end
    end

    return true

end


return M
