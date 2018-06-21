
local M = {}


local luchia  = require "luchia"
local cgilua  = require "cgilua"
local cjson   = require "cjson"
local md5     = require "md5"
local Mailgun = require("mailgun").Mailgun
local io      = require "io"


-- my modules
local utils  = require "utils"
local config = require "config"
local rj     = require "returnjson"



function M.is_valid_login(submitted_author_name, submitted_session_id, submitted_rev)

    local author_name = config.get_value_for("author_name")

    if submitted_author_name ~= author_name then
        return false 
    else
        local h_session = _read_session_file(submitted_rev)
        if submitted_session_id ~= h_session.session_id then
            return false
        elseif h_session.status ~= "active" then
            return false
        else
            return true
        end
   end

end



function _send_login_link(email_rcpt, rev, date_time)

    local m = Mailgun({
        domain = config.get_value_for("mailgun_domain"),
        api_key = "api:" .. config.get_value_for("mailgun_api_key"),
        default_sender = config.get_value_for("mailgun_from")
    })

    local home_page = config.get_value_for("home_page")

    local link = home_page .. "/nopwdlogin/" .. rev 

    local site_name = config.get_value_for("site_name")

    local subject = site_name .. " Login Link - " .. date_time

    local message = "Clink or copy link to log into the site.\n\n" .. link .. "\n"

    m:send_email({
        to      = "<" .. email_rcpt .. ">",
        subject = subject,
        html    = false,
        body    = message
    })

end



function _create_session_id ()

    local created_at = utils.create_datetime_stamp()
    local updated_at = created_at

    local cdb_hash = {
        type              =  'session_id',
        created_at        =  created_at,
        updated_at        =  updated_at,
        status            =  'pending'
    }

    local db = config.get_value_for("database_name")

    local doc = luchia.document:new(db)

    local response = doc:create(cdb_hash)
    
    return response.rev

end



function _get_email_for(author_name)

    local db = config.get_value_for("database_name")

    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/author?key="' .. author_name .. '"'

    local response = utils.get_unsecure_web_page(url)

    local t = cjson.decode(response)

    local author_info = t.rows[1].value

    return author_info.email

end



function M.create_and_send_no_password_login_link()

    local json_text = cgilua.POST[1]

    local hash_ref_login = cjson.decode(json_text)

    local user_submitted_email = utils.trim_spaces(hash_ref_login.email)

    if user_submitted_email == nil or user_submitted_email == "" then
        rj.report_error("400", "Invalid input.", "Insufficent data was submitted.")
    else

        local author_name = config.get_value_for("author_name")

        local author_email = _get_email_for(author_name)

        local rev = ""

        local date_time = utils.get_date_time()

        if user_submitted_email ~= author_email then
            rj.report_error("400", "Invalid input.", "Data was not found.")
        else
            rev = _create_session_id() -- return the login digest (rev for couchdb speak) to be emailed

            _send_login_link(author_email, rev, date_time)

            local hash = {}

            if config.get_value_for("debug_mode") then
                hash["session_id_digest"] = rev
            end
           
            hash["user_message"]   = "Creating New Login Link." 
            hash["system_message"] = "A new login link has been created and sent."
 
            rj.success(hash)
        end

    end

end



function _update_user_current_session_id(session_id)

    local author_name = config.get_value_for("author_name")

    local db = config.get_value_for("database_name")

    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/author?key="' .. author_name .. '"'

    local response = utils.get_unsecure_web_page(url)

    local t = cjson.decode(response)

    local author_info = t.rows[1].value

    author_info.current_session_id = session_id

    local doc = luchia.document:new(db)
    
    local response = doc:update(author_info, author_info._id, author_info._rev)

end



function _get_session_id(user_submitted_rev)

    -- user_submitted_rev = random_string created when requesting login link that was emailed to the author

    local db = config.get_value_for("database_name")

    local url = 'http://127.0.0.1:5984/' .. db .. '/_design/views/_view/session_id?key="' .. user_submitted_rev .. '"'

    local response = utils.get_unsecure_web_page(url)

    local t = cjson.decode(response)

    if t.rows[1] == nil then
        return nil
    else
        local session_id_info = t.rows[1].value
        local id     = session_id_info._id
        local rev    = session_id_info._rev
        local status = session_id_info.status

        if status ~= "pending"  or  rev ~= user_submitted_rev then
            return nil
        else
            session_id_info.status = "active"
            session_id_info.updated_at = utils.create_datetime_stamp()

            local doc = luchia.document:new(db)
        
            local response = doc:update(session_id_info, id, rev )

            if response.ok == false then
                return nil
            else
                _update_user_current_session_id(id);
                return id
           end 
        
        end
    end

end



function M.activate_no_password_login()

    local rev = cgilua.QUERY.rev -- the random_string created above and sent to the author

    local session_id = _get_session_id(rev)

    if session_id == nil then
        rj.report_error("400", "Unable to login.", "Invalid session information submitted.")
    else
        local hash = {
            author_name = config.get_value_for("author_name"),
            session_id  = session_id,
            rev         = rev
        }

        rj.success(hash)
    end

end




-- {"status":"active","_id":"ef077e45e3810107ab9821d8df003efc","_rev":"2-0950378625a6dc556387ccaa03861bd2","created_at":"2018\/06\/20 09:04:20","updated_at":"2018\/06\/20 09:04:43","type":"session_id"}


function M.logout()

    local author_name = cgilua.QUERY.author
    local session_id  = cgilua.QUERY.session_id
    local rev         = cgilua.QUERY.rev

    local doc
    local config_author_name = config.get_value_for("author_name")

    if config_author_name ~= author_name then
        rj.report_error("400", "Unable to logout.", "Invalid info submitted.")
    else
        doc = luchia.document:new(config.get_value_for("database_name"))

        local response = doc:retrieve(session_id)

        if response == nil then
            rj.report_error("400", "Unable to logout.", "Invalid info submitted.")
        else
            local session_id_info = response
            local id     = session_id_info._id
            local status = session_id_info.status

            if status ~= "active" or id ~= session_id then
                rj.report_error("400", "Unable to logout.", "Invalid info submitted.")
            else
                session_id_info.status = "deleted"   

                response = doc:update(session_id_info, id, rev)
                
                if response == nil or response.ok == false then
                    rj.report_error("400", "Unable to update session doc.", "Logout unsuccessful.")
                else
                    local hash = {
                        logged_out = true
                    }
                    rj.success(hash)
                end
            end
        end 

    end
end



return M

