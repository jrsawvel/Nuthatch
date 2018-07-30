
local M = {}

-- installed modules

-- my modules
local requri     = require "requri"
local user       = require "user"
local display    = require "display"
local showstream = require "showstream"
local changestatus = require "changestatus"

-- local createpost = require "createpost"
-- local updatepost = require "updatepost"


function M.execute()
    local a_cgi_params = requri.get_cgi_params()

    local subs = { 
                   post         = showpost.show_post,
                   stream       = showstream.show_stream,
                   search       = showstream.string_search,
                   deleted      = showstream.show_deleted_posts,
                   tag          = showstream.tag_search,
                   login        = user.show_login_form,
                   dologin      = user.do_login,
                   nopwdlogin   = user.no_password_login, 
                   logout       = user.logout,
                   searchform   = showstream.show_search_form,
                   undelete     = changestatus.undelete_post,
                   delete       = changestatus.delete_post,
                   showerror    = display.do_invalid_function
                 }

    if a_cgi_params == nil or #a_cgi_params == 0 then
--         display.report_error("user", "Cannot complete request.", "No action given.")
        subs.stream(a_cgi_params)        
    else
        local action = a_cgi_params[1]
        if subs[action] ~= nil then
            subs[action](a_cgi_params)
        else
            subs.showerror(a_cgi_params)
        end          
    end
end

return M
