

local M = {}


local redis = require "redis"

local config  = require "config"



-- key = post id or URI slug
function M.cache_page(key, html)
    html = html .. "\n<!-- redis cached -->\n"

    local client = redis.connect('127.0.0.1', 6379)

    local response = client:ping()

    if response == true then
        local hashname = config.get_value_for("domain_name")
        client:hset(hashname, key, html)
    end
end


return M
