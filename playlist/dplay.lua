function Log(lm)
    vlc.msg.info("[dplay.lua] " .. lm)
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
            err,h = pcall(function() return JSON:decode(vlc.strings.decode_uri(v)) end)
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

function get_url_param( url, name )
    local _, _, res = string.find( url, "[&?]"..name.."=([^&]*)" )
    return res
end

--"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" --extraintf=http:logger --verbose=6 --file-logging --logfile=D:\vlc-log.txt "https://httpbin.org/get?user=SuperflyVideomaker&id=655842574572765"

function parse()
    local pgrname,seas = string.match(vlc.path, "/([^/]+)/episodi/stagione%-([0-9]+)/?$")
    if pgrname then
        local j = 0
        local status = -1
        local pth = nil
        local ep = nil
        local title = nil
        local season = nil
        local lst = {}
        local numep = 0
        local dpsett = require("dplay_sett")
        local fullp = vlc.access.."://"..string.match(vlc.path, "^([^/]+)")
        Log("Fullp = "..fullp)
        while true do
            local line = vlc.readline()
            if line==nil then
                j = j+1
                if j==1000 then
                    break
                end
            else
                if j~=0 then
                    Log("1- Bachetto: j = "..tostring(j))
                    j = 0
                end
                --Log("line is "..line)
                if string.match(line,"e%-single%-episode%-content") then
                    if status>0 then
                        lst[numep] = {}
                        lst[numep].pth = pth
                        lst[numep].title = title
                        numep = numep+1
                    end
                    status = 0
                    pth = nil
                    title = nil
                    ep = nil
                    Log("Start of episode detected")
                elseif status==0 then
                    pth = string.match(line,"<a href=\"([^\"]+)\"")
                    if pth then
                        status = 1
                    end
                elseif status==1 then
                    if not title then
                        title = string.match(line,'e%-grid%-episode__title">([^<]+)')
                    end
                    if not ep then
                        ep,season = string.match(line,'e%-grid%-episode__episode%-season">E%.([0-9]+) S%.([0-9]+)')
                        if ep and season then
                            title = string.format("%dx%02d",season,ep)
                        end
                    end
                end
            end
        end
        if status>0 then
            lst[numep] = {}
            lst[numep].pth = pth
            lst[numep].title = title
            numep = numep+1
        end
        local od = dpsett.outdir.."\\"..pgrname..'-S'..seas
        Log("folder "..od)
        os.execute("mkdir "..od)
        for i,video in ipairs(lst) do
            local stringrun = "cmd /c \"\"\""..dpsett.mklink.."\"\" \""..od.."\\"..video.title..".lnk\" \""..dpsett.vlc.."\" \""..fullp..video.pth.."\"\""
            Log("video "..tostring(i)..") "..stringrun)
            os.execute(stringrun)
        end
    elseif string.match(vlc.path, "/ajax/playbackjson") then
        local dec = vlc.strings.decode_uri(vlc.path)
        local title = get_url_param(dec,'t')
        Log("Dec = "..dec.." / Tit "..title)
        local j = 0
        while true do
            local line = vlc.readline()
            if line==nil then
                j = j+1
                if j==1000 then
                    break
                end
            else
                if j~=0 then
                    Log("1- Bachetto: j = "..tostring(j))
                    j = 0
                end
                pth = string.match(line,'\\"hls\\" *: *%{\\n *\\"url\\" *: *\\"([^\\]+)')
                if pth then
                    return { { path = pth, title = title }}
                end
            end
        end
    else--if string.match(vlc.path, "/[^/]+/stagione%-[0-9]+%-episodio%-[0-9]+") then
        local j = 0
        local title = nil
        local pth = nil
        while true do
            local line = vlc.readline()
            if line==nil then
                j = j+1
                if j==1000 then
                    break
                end
            else
                if j~=0 then
                    Log("1- Bachetto: j = "..tostring(j))
                    j = 0
                end
                if not title then
                    title = string.match(line,'<title>([^<]+)')
                    if title then
                        Log('title ='..title)
                    end
                end
                if not pth then
                    pth = string.match(line,'/ajax/playbackjson/video/[0-9]+')
                    if pth then
                        Log('pth ='..pth)
                        title = vlc.strings.encode_uri_component(title)
                        return { { path = vlc.access..'://'..string.match(vlc.path, "^([^/]+)")..pth..'?t='..title }}
                    end
                end
            end
        end
    end
    vlc.msg.err( "Couldn't extract dplay video URL, please check for updates to this script" )
    return {}
end

-- Probe function.
function probe()
    local probedp =  string.match(vlc.path,"dplay%.com")
        --and (
        --string.match(vlc.path, "/[^/]+/episodi/stagione%-[0-9]+/?$") or
        --string.match(vlc.path, "/[^/]+/stagione%-[0-9]+%-episodio%-[0-9]+") or
        --string.match(vlc.path, "/ajax/playbackjson"))
    Log("probedp "..tostring(probedp))
    return probedp
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
