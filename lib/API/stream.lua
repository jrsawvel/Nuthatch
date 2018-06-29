

local M = {}

local config = require "config"
local rj     = require "returnjson"
local utils  = require "utils"
local cjson  = require "cjson"


function M.read_stream(page_num)

    if page_num == 0 then
        page_num = 1
    end

    local db = config.get_value_for("database_name")

    local max_entries = config.get_value_for("max_entries_on_page")

    -- this math makes the result a float, such as 0.0 or 15.0
    local skip_count = (max_entries * page_num) - max_entries

    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/stream?descending=true&limit=' .. max_entries + 1 .. '&skip=' .. math.tointeger(skip_count)

    local response = utils.get_unsecure_web_page(url)

    -- convert the json text into a lua table (hashes and arrays)
    local t = cjson.decode(response)

    if t.rows[1] ~= nil then
        local stream = t.rows

        local next_link_bool = 0

        if #stream > max_entries then
                next_link_bool = 1
        end

        local posts = {}

        for i=1, #stream do
            stream[i].value.formatted_updated_at = utils.format_date_time(stream[i].value.updated_at)
            posts[i] = stream[i].value

            -- this is done because when a couchdb returns an empty array, and that json gets converted into
            -- lua's data structures (tables) and then back to json, the empty array becames an empty hash or
            -- associative array. 
            -- "tags":[] becomes "tags":{} which blows up client code expected tags to be an array.
            -- the code below caused the returned json to become: "tags":[""].
            -- that's not perfect, but apparently it's viewed as an empty array by perl client code.
            -- probably should change how an array of tags is stored.
            -- https://github.com/mpx/lua-cjson/issues/11
            -- https://github.com/brimworks/lua-cjson/commit/3499130c852a993e4afc741aa2aa902959775b30
            -- http://openmymind.net/Lua-JSON-turns-empty-arrays-into-empty-hashes/
            -- https://stackoverflow.com/questions/43272872/redis-lua-differetiating-empty-array-and-object
            -- i assumed that it's because arrays and hashes are treated as tables in lua while other
            -- programming languages differentiate between the two types of structures.
            if #posts[i].tags < 1 then
                posts[i].tags[1] = ""
                -- posts[i].tags = nil
            end
               
            if i == max_entries then
                break
            end
        end

        local hash = {}
        hash.posts = posts
        hash.next_link_bool = next_link_bool
        rj.success(hash)
    else
        local hash = {}
        hash.posts = nil
        rj.success(hash)               
    end
end

return M


