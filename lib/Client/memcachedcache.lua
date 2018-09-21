
local M = {}


local memcached = require "memcached"

local config = require "config"



function M.cache_page(post_id, html)
    html = html .. "\n<!-- memcached -->\n"

    local key
    local hashname = config.get_value_for("domain_name")
    local port     = config.get_value_for("memcached_port")

    key = hashname .. "-" .. post_id

    local memd = memcached("localhost", port)

    memd:set(key, html)
end


return M
