

local M = {}

local rex = require "rex_pcre"
local markdown = require "markdown"


local rj      = require "returnjson"
local utils   = require "utils"



function M.create_tag_array(str)
    str = " " .. str  -- hack to help with regex

    local unique_tags = {}

    local tag_list_str = "|"

    for hashtag in rex.gmatch(str, "[\\s]#(\\w+)", "is", nil) do 
        if string.find(tag_list_str, hashtag) == nil then
            tag_list_str = tag_list_str .. hashtag .. "|"
            table.insert(unique_tags, hashtag) 
        end
    end

    if #unique_tags < 1 then
        unique_tags[1] = ""
    end

    return unique_tags
end



function _hashtag_to_link(str) 
    str = " " .. str

    local tagsearchurl = "/tag/"

    -- for hashtag in string.gmatch(str, "[ ]#(%w+)") do 
    for hashtag in rex.gmatch(str, "[\\s]#(\\w+)", "is", nil) do 
        tagsearchstr = ' <a href="' .. tagsearchurl .. hashtag .. '">#' .. hashtag .. '</a>'
        str = string.gsub(str, "[%s]#" .. hashtag, tagsearchstr)
    end

    str = utils.trim_spaces(str)

    return str
end



function M.get_more_text_info(markup, html, slug, title)
    local tmp_post = rex.gsub(html, "<more />", "[more]", nil, "im")

    -- not needed, since html is based upon the markup that exists after the title if a title exists
    -- tmp_post = rex.gsub(tmp_post, '<h1 class="headingtext">', "[h1]", nil, "im")
    -- tmp_post = rex.gsub(tmp_post, "</h1>", "[/h1]", nil, "im")

    tmp_post = utils.remove_html(tmp_post)

    local text_intro
    local more_text_exists = 0 -- false - compatible with client code written in perl

    local before_more, after_more = rex.match(tmp_post, "^(.*)[[]more[]](.*)$", 1, "is")

    if before_more ~= nil and after_more ~=nil then
        text_intro = before_more

        local tmp_extended = utils.trim_spaces(after_more)
        if tmp_extended:len() > 0 then
            more_text_exists = 1
        end
       
        if text_intro:len() > 300 then
            text_intro = text_intro:sub(1, 300)
            text_intro = text_intro .. " ..."
        end 
    elseif tmp_post:len() > 300 then
       text_intro = tmp_post:sub(1, 300)
       text_intro = text_intro .. " ..."
       more_text_exists = 1
    else
        text_intro = tmp_post
    end   

-- not needed per above.
--    text_intro = rex.gsub(text_intro, '[h1]', '<span class="streamtitle"><a href="/' .. slug .. '">', nil, "im")
--    text_intro = rex.gsub(text_intro, '[h1]', '</a></span> - ', nil, "im")

    text_intro = utils.remove_newline(text_intro)

    if _get_power_command_on_off_setting_for("url_to_link", markup, false) == true then
        text_intro = utils.url_to_link(text_intro)
    end

    if _get_power_command_on_off_setting_for("hashtag_to_link", markup, true) == true then
        text_intro = _hashtag_to_link(text_intro)
    end

    return { more_text_exists = more_text_exists, text_intro = text_intro }
   
       -- https://github.com/jrsawvel/Veery-API-Perl/blob/master/lib/App/Format.pm#L195
       -- wont' support the intro= command that exists in other veery api code. 
       -- this command allows for custom intro text to be used. this text does not have to 
       -- appear in the main article. the info gets removed from the final article output.

end



function M.calc_reading_time_and_word_count(html)

    local text = utils.remove_html(html)

    local hash = {}

    local dummy, n = text:gsub("%S+","") -- n = substitutions

    hash.word_count   = n or 0

    hash.reading_time = 0  -- minutes

    if hash.word_count >= 180 then
        hash.reading_time = math.floor(hash.word_count / 180) 
    end

    return hash

end



-- commands in markup use values yes and no.
-- ex:   hashtag_to_link = no
function _get_power_command_on_off_setting_for(command, str, default_bool) 

    local return_bool = default_bool

    local tmp_str = rex.match(str, "^" .. command .. "[\\s]*=[\\s]*(.*)$", 1, "im")

    if tmp_str ~= nil then   
        local string_value = utils.trim_spaces(string.lower(tmp_str))
        if string_value == "no" then
            return_bool = false
        elseif string_value == "yes" then 
            return_bool = true 
        end 
    end
 
    return return_bool

end




function M.extract_css(str)

    local return_data = {}

    str = rex.gsub(str, "^css_end -->", "</css>", nil, "im")
    str = rex.gsub(str, "^<!-- css_start", "<css>", nil, "im")

    local pre_css, tmp_css, tmp_markup = rex.match(str, "^(.*)<css>(.*)</css>(.*)$", 1, "is")

    if pre_css ~= nil and tmp_css ~= nil and tmp_markup ~= nil then
        return_data.markup = pre_css .. tmp_markup
        return_data.custom_css = tmp_css
--rj.report_error("400", return_data.markup, return_data.custom_css)
    else
        return_data.markup = str
        return_data.custom_css = nil
--rj.report_error("400", return_data.markup, "no custom css found")
    end 

    return return_data
    
end



function M.extract_json(str)

    str = rex.gsub(str, "^json_end -->", "</jsontmp>", nil, "im")
    str = rex.gsub(str, "^<!-- json_start", "<jsontmp>", nil, "im")

    local pre_json, tmp_json, tmp_markup = rex.match(str, "^(.*)<jsontmp>(.*)</jsontmp>(.*)$", 1, "is")

    if tmp_json ~= nil then 
        return utils.trim_spaces(tmp_json)
    else
        return nil
    end
end



function _custom_commands(str)

    str = rex.gsub(str, "^c[.][.]", "</code></pre>", nil, "im")
    str = rex.gsub(str, "^c[.]", "<pre><code>", nil, "im")


    str = rex.gsub(str, "^more.", "<more />", nil, "im")

--    str = rex.gsub(str, "^q[.][.]", "\n</blockquote>", nil, "im")
--    str = rex.gsub(str, "^q[.]", "<blockquote>\n", nil, "im")

    return str

end




function _remove_power_commands(str)

    -- url_to_link=yes|no
    -- hashtag_to_link=yes|no

    str = rex.gsub(str, "^hashtag_to_link[\\s]*=[\\s]*[noNOyesYES]+", "", nil, "im")
    str = rex.gsub(str, "^url_to_link[\\s]*=[\\s]*[noNOyesYES]+", "", nil, "im")

    return str

end




function M.markup_to_html(markup)

    local html = _remove_power_commands(markup)

    if _get_power_command_on_off_setting_for("url_to_link", markup, false) == true then
        html = utils.url_to_link(html)
    end

    html = _custom_commands(html)

    if _get_power_command_on_off_setting_for("hashtag_to_link", markup, true) == true then
        html = _hashtag_to_link(html)
    end

    html = markdown(html)

    return html

end



return M
