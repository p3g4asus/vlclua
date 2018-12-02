local function pchar_to_char(str)
    return string.char(tonumber(str, 16))
end
local function decodeURIComponent(str)
    return (str:gsub("%%(%x%x)", pchar_to_char))
end

function Log(lm)
    vlc.msg.info("[raiplay.lua] " .. lm)
end
local function trim1(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function isdef(p,...)
    if not p then
        return false
    else
        local tb = p
        for i,v in ipairs(arg) do
            if tb[v]==nil then
                return false
            else
                tb = tb[v]
            end
        end
        return true
    end
end

function find_table_field(tbl,fld,JSON)
    for k, v in pairs( tbl ) do
        local h = nil
        if type(v)=="table" then
            h = v
        elseif type(v)=="string" then
            err,h = pcall(function() return JSON:decode(decodeURIComponent(v)) end)
            if err==false then
                h = nil
            end
        end
        if type(h)=="table" then
            local rv = find_table_field(h,fld,JSON)
            if rv~=nil then
                return rv
            end
        elseif k==fld then
            return v
        end
    end
    return nil
end

function LogT(t,lev)
    local sp = string.rep("  ", 4*lev)
    for k, v in pairs( t ) do
        if type(v)=="table" then
            Log(sp .. tostring(k) .. " = {")
            LogT(v,lev+1)
            Log(sp .. "}")
        else
            Log(sp .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

local urldecode = function(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

function get_url_param( url, name )
    local _, _, res = string.find( url, "[&?]"..name.."=([^&]*)" )
    return res
end

--"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" --extraintf=http:logger --verbose=6 --file-logging --logfile=D:\vlc-log.txt "https://httpbin.org/get?user=SuperflyVideomaker&id=655842574572765"

function parse()
    if string.match( vlc.path, "raiplay%.it/dirette" ) then
        local pth = nil
        local chhan = nil
        while true do
            local line = vlc.readline()
            if line==nil then 
                break
            else
                pth = string.match(line,'data%-video%-url="([^"]+)"')
                if pth then
                    chan = string.match(line,'data%-canale="([^"]+)"')
                    if not chan then
                        chan = ''
                    end
                    return { { path = pth .. '&output=45&title='..chan, title = chan }}
                end
            end
        end
    elseif string.match( vlc.path, "rai%.it/relinker" ) then
        local all = ''
        while true do
            local line = vlc.readline()
            if line==nil then 
                break
            else
                all = all .. "\n" .. line
            end
        end
        local chan = get_url_param( vlc.path, "title" )
        local xml2lua = require("xml2lua")
        --Uses a handler that converts the XML to a Lua table
        local handler = require("xmlhandler.tree")

        --Instantiates the XML parser
        local parser = xml2lua.parser(handler)
        parser:parse(all)
        if #handler.root.Mediapolis.url>=1 then
            LogT(vlc,1)
            return { { path = handler.root.Mediapolis.url[1][1], title = chan }}
        else
            return {}
        end
    end
    vlc.msg.err( "Couldn't extract facebook video URL, please check for updates to this script" )
    return {}
end

-- Probe function.
function probe()
    Log("sono qui rai "..vlc.path.." "..string.sub( vlc.path, 1, 9 ))
    return string.match( vlc.path, "raiplay%.it/dirette" ) or string.match( vlc.path, "rai%.it/relinker" )
    -- if vlc.access=="https" and string.match( vlc.path, "httpbin.org" ) then
        -- return true
    -- end
    -- if vlc.access ~= "http" and vlc.access ~= "https" then
        -- return false
    -- end
    -- youtube_site = string.match( string.sub( vlc.path, 1, 9 ), "facebook" )
    -- if not youtube_site then
        -- youtube_site = string.find( vlc.path, ".facebook.com" )
        -- if youtube_site == nil then
            -- return false
        -- end
    -- end
    -- return string.match( vlc.path, "/videos/vl%.%d" ) or string.match( vlc.path, "/videos/%d" )
 end
--local raw_json_text = "[[\"params\",\"\\u00257B\\u002522auto_hd\\u002522\\u00253Afalse\\u00252C\\u002522autoplay_reason\\u002522\\u00253A\\u002522unknown\\u002522\\u00252C\\u002522default_hd\\u002522\\u00253Atrue\\u00252C\\u002522disable_native_controls\\u002522\\u00253Atrue\\u00252C\\u002522inline_player\\u002522\\u00253Afalse\\u00252C\\u002522pixel_ratio\\u002522\\u00253A1\\u00252C\\u002522preload\\u002522\\u00253Atrue\\u00252C\\u002522start_muted\\u002522\\u00253Atrue\\u00252C\\u002522rtmp_stage_video\\u002522\\u00253Atrue\\u00252C\\u002522rtmp_buffer\\u002522\\u00253Afalse\\u00252C\\u002522rtmp_buffer_time\\u002522\\u00253A0\\u00252C\\u002522rtmp_buffer_time_max\\u002522\\u00253A0\\u00252C\\u002522video_data\\u002522\\u00253A\\u00257B\\u002522progressive\\u002522\\u00253A\\u00257B\\u002522is_hds\\u002522\\u00253Afalse\\u00252C\\u002522video_id\\u002522\\u00253A\\u002522657135521110137\\u002522\\u00252C\\u002522is_live_stream\\u002522\\u00253Afalse\\u00252C\\u002522rotation\\u002522\\u00253A0\\u00252C\\u002522sd_src_no_ratelimit\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft42.1790-2\\u00255C\\u00252F14130732_1776026479338289_545816769_n.mp4\\u00253Fefg\\u00253DeyJ2ZW5jb2RlX3RhZyI6InN2ZV9zZCJ9\\u002526oh\\u00253Db51c4a877df5d34b172ed9b4685008f8\\u002526oe\\u00253D57BDE2BC\\u002522\\u00252C\\u002522hd_src_no_ratelimit\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft43.1792-2\\u00255C\\u00252F13947333_1668592886727478_1675599100_n.mp4\\u00253Fefg\\u00253DeyJ2ZW5jb2RlX3RhZyI6InN2ZV9oZCJ9\\u002526oh\\u00253D4bb144de87f30698daccbe00668ddd93\\u002526oe\\u00253D57BDF8E4\\u002522\\u00252C\\u002522hd_src\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft43.1792-2\\u00255C\\u00252F13947333_1668592886727478_1675599100_n.mp4\\u00253Fefg\\u00253DeyJybHIiOjE1MDAsInJsYSI6NDA5NiwidmVuY29kZV90YWciOiJzdmVfaGQifQ\\u00255Cu00253D\\u00255Cu00253D\\u002526rl\\u00253D1500\\u002526vabr\\u00253D715\\u002526oh\\u00253D4bb144de87f30698daccbe00668ddd93\\u002526oe\\u00253D57BDF8E4\\u002522\\u00252C\\u002522sd_src\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft42.1790-2\\u00255C\\u00252F14130732_1776026479338289_545816769_n.mp4\\u00253Fefg\\u00253DeyJybHIiOjU3NiwicmxhIjoyMTg4LCJ2ZW5jb2RlX3RhZyI6InN2ZV9zZCJ9\\u002526rl\\u00253D576\\u002526vabr\\u00253D320\\u002526oh\\u00253Db51c4a877df5d34b172ed9b4685008f8\\u002526oe\\u00253D57BDE2BC\\u002522\\u00252C\\u002522hd_tag\\u002522\\u00253A\\u002522sve_hd\\u002522\\u00252C\\u002522sd_tag\\u002522\\u00253A\\u002522sve_sd\\u002522\\u00252C\\u002522stream_type\\u002522\\u00253A\\u002522progressive\\u002522\\u00252C\\u002522live_routing_token\\u002522\\u00253A\\u002522\\u002522\\u00252C\\u002522projection\\u002522\\u00253A\\u002522flat\\u002522\\u00252C\\u002522subtitles_src\\u002522\\u00253Anull\\u00252C\\u002522dash_manifest\\u002522\\u00253Anull\\u00252C\\u002522dash_prefetched_representation_ids\\u002522\\u00253Anull\\u00257D\\u00252C\\u002522hls\\u002522\\u00253Anull\\u00257D\\u00252C\\u002522video_data_preference\\u002522\\u00253A\\u00257B\\u0025221\\u002522\\u00253A\\u00257B\\u002522is_hds\\u002522\\u00253Afalse\\u00252C\\u002522video_id\\u002522\\u00253A\\u002522657135521110137\\u002522\\u00252C\\u002522is_live_stream\\u002522\\u00253Afalse\\u00252C\\u002522rotation\\u002522\\u00253A0\\u00252C\\u002522sd_src_no_ratelimit\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft42.1790-2\\u00255C\\u00252F14130732_1776026479338289_545816769_n.mp4\\u00253Fefg\\u00253DeyJ2ZW5jb2RlX3RhZyI6InN2ZV9zZCJ9\\u002526oh\\u00253Db51c4a877df5d34b172ed9b4685008f8\\u002526oe\\u00253D57BDE2BC\\u002522\\u00252C\\u002522hd_src_no_ratelimit\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft43.1792-2\\u00255C\\u00252F13947333_1668592886727478_1675599100_n.mp4\\u00253Fefg\\u00253DeyJ2ZW5jb2RlX3RhZyI6InN2ZV9oZCJ9\\u002526oh\\u00253D4bb144de87f30698daccbe00668ddd93\\u002526oe\\u00253D57BDF8E4\\u002522\\u00252C\\u002522hd_src\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft43.1792-2\\u00255C\\u00252F13947333_1668592886727478_1675599100_n.mp4\\u00253Fefg\\u00253DeyJybHIiOjE1MDAsInJsYSI6NDA5NiwidmVuY29kZV90YWciOiJzdmVfaGQifQ\\u00255Cu00253D\\u00255Cu00253D\\u002526rl\\u00253D1500\\u002526vabr\\u00253D715\\u002526oh\\u00253D4bb144de87f30698daccbe00668ddd93\\u002526oe\\u00253D57BDF8E4\\u002522\\u00252C\\u002522sd_src\\u002522\\u00253A\\u002522https\\u00253A\\u00255C\\u00252F\\u00255C\\u00252Fvideo.xx.fbcdn.net\\u00255C\\u00252Fv\\u00255C\\u00252Ft42.1790-2\\u00255C\\u00252F14130732_1776026479338289_545816769_n.mp4\\u00253Fefg\\u00253DeyJybHIiOjU3NiwicmxhIjoyMTg4LCJ2ZW5jb2RlX3RhZyI6InN2ZV9zZCJ9\\u002526rl\\u00253D576\\u002526vabr\\u00253D320\\u002526oh\\u00253Db51c4a877df5d34b172ed9b4685008f8\\u002526oe\\u00253D57BDE2BC\\u002522\\u00252C\\u002522hd_tag\\u002522\\u00253A\\u002522sve_hd\\u002522\\u00252C\\u002522sd_tag\\u002522\\u00253A\\u002522sve_sd\\u002522\\u00252C\\u002522stream_type\\u002522\\u00253A\\u002522progressive\\u002522\\u00252C\\u002522live_routing_token\\u002522\\u00253A\\u002522\\u002522\\u00252C\\u002522projection\\u002522\\u00253A\\u002522flat\\u002522\\u00252C\\u002522subtitles_src\\u002522\\u00253Anull\\u00252C\\u002522dash_manifest\\u002522\\u00253Anull\\u00252C\\u002522dash_prefetched_representation_ids\\u002522\\u00253Anull\\u00257D\\u00252C\\u0025222\\u002522\\u00253Anull\\u00257D\\u00252C\\u002522show_captions_default\\u002522\\u00253Atrue\\u00252C\\u002522persistent_volume\\u002522\\u00253Atrue\\u00252C\\u002522hide_controls_when_finished\\u002522\\u00253Afalse\\u00252C\\u002522rtmp_start_playing_non_zero_stream_time\\u002522\\u00253Atrue\\u00252C\\u002522rtmp_improve_playback_config\\u002522\\u00253Afalse\\u00252C\\u002522rtmp_no_stream_reported_time\\u002522\\u00253Afalse\\u00252C\\u002522rtmp_start_time_fix\\u002522\\u00253Atrue\\u00252C\\u002522buffer_length\\u002522\\u00253A0.1\\u00257D\"],[\"width\",\"476\"],[\"height\",\"262\"],[\"user\",\"100000020660166\"],[\"log\",\"no\"],[\"div_id\",\"id_57bdc0d29b3719b34187239\"],[\"swf_id\",\"swf_id_57bdc0d29b3719b34187239\"],[\"browser\",\"Firefox+49.0\"],[\"tracking_domain\",\"https\\u00253A\\u00252F\\u00252Fpixel.facebook.com\"],[\"post_form_id\",\"\"]]"
--
--local lua_value = JSON:decode(raw_json_text) -- decode example
--for k, v in pairs(lua_value) do
--  if v[1]=="params" then
--    v2 = JSON:decode(decodeURIComponent(v[2]))
--  end
--  Log(k, v[1],v[2])
--end
--require 'pl.pretty'.dump(v2)
--require 'pl.pretty'.dump(v2.video_data_preference["1"].hd_src)
--end
--function script_path()
--   local str = debug.getinfo(2, "S").source:sub(2)
--   return str:match("(.*/)") or "."
--end

--Log(script_path())
--main()
