local function pchar_to_char(str)
    return string.char(tonumber(str, 16))
end
local function decodeURIComponent(str)
    return (str:gsub("%%(%x%x)", pchar_to_char))
end

function Log(lm)
    vlc.msg.info("[dailymotion.lua] " .. lm)
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

--"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" --extraintf=http:logger --verbose=6 --file-logging --logfile=D:\vlc-log.txt "https://httpbin.org/get?user=SuperflyVideomaker&id=655842574572765"

function parse()
    local info = debug.getinfo(1,'S');
    local kk,jj,ll = string.match(string.sub(info.source,2), "(.-)([^\\/]-%.?([^%.\\/]*))$")
    if string.match( vlc.path, "dailymotion.com/video") then
        a = string.match(vlc.path, 'video/([^?/]+)')
        if a then
            return {{path = "https://www.dailymotion.com/player/metadata/video/".. a}}
        else
            vlc.msg.err( "Couldn't extract dailymotion video URL, please check for updates to this script" )
            return {};
        end
    end
    Log(kk,jj,ll);
    JSON = (loadfile (kk.."JSON.lua"))() -- one-time load of the routines
    local json = ''
    while true do
        local line = vlc.readline()
        if line then
            json = json .. line
        else
            break
        end
    end
    local pall = JSON:decode(json)
    local title = nil
    local artist = nil
    if isdef(pall,"owner","screenname") then
        artist = pall.owner.screenname
    end
    if isdef(pall,"title") then
        title = pall.title
    end
    if isdef(pall,"stream_chromecast_url") then
        return {{path = pall.stream_chromecast_url, artist = artist, title = title}}
    end
    vlc.msg.err( "Couldn't extract dailymotion video URL, please check for updates to this script" )
    return {};
end

-- Probe function.
function probe()
    Log("sono qui "..vlc.path)
    if vlc.access ~= "http" and vlc.access ~= "https" then
        return false
    end
    return string.match( vlc.path, "dailymotion.com/video" ) or string.match( vlc.path, "dailymotion.com/player/metadata/video" )
 end