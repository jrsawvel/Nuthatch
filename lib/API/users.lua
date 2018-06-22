
local M = {}


local cgilua = require "cgilua"

local rj      = require "returnjson"
local login   = require "login"
local logout  = require "logout"


-- application/json POST type data can be accessed at: cgilua.POST[1]

function M.users(a_params)

    -- local request_method = os.getenv("REQUEST_METHOD")

    local request_method = cgilua.servervariable("REQUEST_METHOD")

    if request_method == "POST" then
        if a_params[2] ~= nil and a_params[2] == "login" then
            login.create_and_send_no_password_login_link()
        end
    elseif request_method == "GET" then
        if a_params[2] ~= nil and a_params[2] == "login" then
            login.activate_no_password_login()
        elseif a_params[2] ~= nil and a_params[2] == "logout" then
            logout.logout()
        end
    else
        rj.report_error("400", "Invalid request or action", "Request method = " .. request_method .. ". Action = " .. a_params[2])
    end

end


return M
