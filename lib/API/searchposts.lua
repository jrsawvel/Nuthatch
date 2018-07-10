

local M = {}

local cgilua  = require "cgilua"
local urlcode = require "cgilua.urlcode"
local cjson   = require "cjson"
local rex     = require "rex_pcre"

local config  = require "config"
local utils   = require "utils"
local rj      = require "returnjson"


-- a_params[1] = searches
-- a_params[2] = tag
-- a_params[3] = <tag name>
-- example api request: /api/v1/searches/tag/toledo

function M.do_tag_search(a_params)

    if a_params[3] == nil then
        rj.report_error("400", "Cannot perform search.", "Tag name missing.")
    else
        local keyword = a_params[3]
        local page_num = 1

        if cgilua.QUERY.page ~= nil and utils.is_numeric(cgilua.QUERY.page) == true then
            page_num = cgilua.QUERY.page
        end

        local db = config.get_value_for("database_name")

        local max_entries = config.get_value_for("max_entries_on_page")

        -- this math makes the result a float, such as 0.0 or 15.0
        local skip_count = (max_entries * page_num) - max_entries

        local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/tag_search?descending=true&limit=' .. max_entries + 1 .. '&skip=' .. math.tointeger(skip_count)

        -- for tag "wiki" : &startkey=["wiki", {}]&endkey=["wiki"]
        url = url .. '&startkey=[%22' .. keyword .. '%22,%20%7B%7D]&endkey=[%22' .. keyword .. '%22]'

        local response = utils.get_unsecure_web_page(url)

        -- convert the json text into a lua table (hashes and arrays)
        local t = cjson.decode(response)

        if t.rows[1] == nil then
            -- no search results found. but it's not an error. it's up to the client to deal with this fact.
            local hash = {}
            hash.posts = nil
            rj.success(hash)               
        else
            local stream = t.rows

            local next_link_bool = 0

            if #stream > max_entries then
                next_link_bool = 1
            end

            local posts = {}

            for i=1, #stream do
                stream[i].value.formatted_updated_at = utils.format_date_time(stream[i].value.updated_at)
                posts[i] = stream[i].value

                if #posts[i].tags < 1 then
                    posts[i].tags[1] = ""
                end
               
                if i == max_entries then
                    break
                end
            end

            local hash = {}
            hash.posts = posts
            hash.next_link_bool = next_link_bool
            rj.success(hash)
        end
   end

end



function M.do_string_search(a_params)

    local page_num = 1

    if a_params[3] == nil then
        rj.report_error("400", "Missing data.", "Enter keyword(s) to search.")
    else
        local keyword = a_params[3]

        if cgilua.QUERY.page ~= nil and utils.is_numeric(cgilua.QUERY.page) == true then
            page_num = cgilua.QUERY.page
        end

        keyword = utils.trim_spaces(keyword)

        if keyword:len() < 1 then
            rj.report_error("400", "Missing data.", "Enter keyword(s) to search.")
        else
            keyword = urlcode.unescape(keyword)
            keyword = keyword:gsub("+", " ")
            -- remove unnacceptable chars from the search string
            -- keyword = rex.gsub(keyword, "[^A-Za-z0-9 _'%-%#%.]", "", nil, "sx")

            local db = config.get_value_for("database_name")

            local max_entries = config.get_value_for("max_entries_on_page")

            local skip_count = (max_entries * page_num) - max_entries

-- local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/tag_search?descending=true&limit=' .. max_entries + 1 .. '&skip=' .. math.tointeger(skip_count)

            local url = 'http://127.0.0.1:9200/' .. db .. '/' .. db .. '/_search?size=' .. max_entries + 1 .. '&q=%2Btype%3Apost+%2Bpost_status%3Apublic+%2Bmarkup%3A' .. urlcode.escape(keyword) .. '&from=' .. math.tointeger(skip_count)

            local response = utils.get_unsecure_web_page(url)

            -- convert the json text into a lua table (hashes and arrays)
            local t = cjson.decode(response)

            local total_hits = math.tointeger(t.hits.total)

            if total_hits == 0 then
                -- no search results found. but it's not an error. it's up to the client to deal with this fact.
                local hash = {}
                hash.posts = nil
                rj.success(hash)               
            else
                local stream = t.hits.hits

                local next_link_bool = 0

                if #stream > max_entries then
                    next_link_bool = 1
                end

                local posts = {}

                for i=1, #stream do
                   -- stream[i]._source.formatted_updated_at = utils.format_date_time(stream[i]._source.updated_at)

                    posts[i] = stream[i]._source

                    posts[i].formatted_updated_at = utils.format_date_time(posts[i].updated_at)

                    posts[i].slug = posts[i]._id

                    if #posts[i].tags < 1 then
                        posts[i].tags[1] = ""
                    end

                    posts[i]._id = nil
                    posts[i].created_at = nil
                    posts[i].html = nil
                    posts[i].markup = nil
                    posts[i]._rev = nil
                    posts[i].post_status = nil
                    posts[i].type = nil
                    posts[i].word_count = nil

                    if i == max_entries then
                        break
                    end
                end

                local hash = {}
                hash.posts = posts
                hash.next_link_bool = next_link_bool
                rj.success(hash)
            end

        end
    end
end


return M

