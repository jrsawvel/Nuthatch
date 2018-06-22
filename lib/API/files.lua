

local M = {}


local rex   = require "rex_pcre"
local io    = require "io"
local cjson = require "cjson"
local pretty = require "resty.prettycjson"


local page      = require "page"
local config    = require "config"
local rj        = require "returnjson"
local utils     = require "utils"



function _save_markup_to_storage_directory(submit_type, markup, hash)

    local save_markup = markup ..  "\n\n<!-- author_name: " .. config.get_value_for("author_name") .. " -->\n"
    save_markup = save_markup  ..  "<!-- published_date: "  .. hash.created_date .. " -->\n"
    save_markup = save_markup  ..  "<!-- published_time: "  .. hash.created_time .. " -->\n"

    local tmp_slug = hash.slug

    if hash.dir ~= nil then
        tmp_slug = utils.clean_title(hash.dir) .. "-" .. tmp_slug
--         rj.report_error("400", "hash.slug = " .. hash.slug, "hash.dir = " .. hash.dir)
--         return false
    end 

    -- write markup to markup storage outside of document root
    -- if "create" then the file must not exist
    local domain_name = config.get_value_for("domain_name")
    local markup_filename = config.get_value_for("markup_storage") .. "/" .. domain_name .. "-" .. tmp_slug .. ".markup"

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
