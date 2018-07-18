
local M = {}


local cgilua = require "cgilua"

local rj      = require "returnjson"
local searchposts = require "searchposts"


function M.searches(a_params)

    local request_method = cgilua.servervariable("REQUEST_METHOD")


    if request_method == "GET" then
        if a_params[2] ~= nil and a_params[2] == "tag" then
            searchposts.do_tag_search(a_params)
        elseif a_params[2] ~= nil and a_params[2] == "string" then
            searchposts.do_string_search(a_params)
        else
            rj.report_error("400", "Not found", "No search type specified.")
        end
    else 
        rj.report_error("400", "Not found", "Invalid request")
    end

end

-- todo: using elasticsearch's dsl feture requires a post request with json.


return M
