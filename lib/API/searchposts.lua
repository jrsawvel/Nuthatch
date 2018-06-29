

local M = {}

local cgilua  = require "cgilua"
local urlcode = require "cgilua.urlcode"
local cjson   = require "cjson"

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

    if a_params[3] == nil then
        rj.report_error("400", "Missing data.", "Enter keyword(s) to search.")
    else
        local keyword = a_params[3]
        local page_num = 1

        if cgilua.QUERY.page ~= nil and utils.is_numeric(cgilua.QUERY.page) == true then
            page_num = cgilua.QUERY.page
        end

        keyword = utils.trim_spaces(keyword)

        if keyword:len() < 1 then
            rj.report_error("400", "Missing data.", "Enter keyword(s) to search.")
        else
            keyword = urlcode.unescape(keyword)
            keyword = keyword:gsub("+", " ")
            rj.report_error("400", "DEBUG", keyword)
        end
    end
end


function M.xxxsearches(a_params)

    local author_name = cgilua.QUERY.author
    local session_id  = cgilua.QUERY.session_id
    local rev         = cgilua.QUERY.rev

    if auth.is_valid_login(author_name, session_id, rev) == false then 
        rj.report_error("400", "Unable to peform action.", "You are not logged in.")
    else
        local posts = {}

        local total_hits = 0
  
        local search_text = a_params[2]

        search_text = urlcode.unescape(search_text)

        -- remove unnacceptable chars from the search string
        search_text = rex.gsub(search_text, "[^A-Za-z0-9 _'%-%#%.]", "", nil, "sx")

        local default_doc_root = config.get_value_for("default_doc_root")

        local search_results_filename = config.get_value_for("searches_storage") .. "/" .. os.time() .. ".txt"

        local grep_cmd = "grep -i -R --exclude-dir=versions --include='*.txt' -m 1 '" .. search_text .. "' " .. default_doc_root .. " > " .. search_results_filename

        local r = os.execute(grep_cmd)

        if r == true then
            local f = io.open(search_results_filename, "r")

            if f == nil then
                rj.report_error("400", "Could not open search results file for read.", "")
            else
                local home_page = config.get_value_for("home_page")
                for line in f:lines() do
                    local tmp_array = utils.split(line, ".txt:")
                    local tmp_str = rex.gsub(tmp_array[1], default_doc_root .. "/" , "")
                    local tmp_hash = {
                        uri = tmp_str,
                        url = home_page .. "/" .. tmp_str .. ".html"
                    }
                    table.insert(posts, tmp_hash)
                    total_hits = total_hits + 1
                end
                f:close()
                local hash = {
                    total_hits = total_hits,
                    search_text = search_text,
                    posts = posts
                }
                
                rj.success(hash) 
            end
        else
            rj.report_error("400", "Unable to execute search.", grep_cmd)
        end

    end
end


return M

