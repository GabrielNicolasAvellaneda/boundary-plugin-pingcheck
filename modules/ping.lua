local _child = require('childprocess')
local _os = require('los')
local uv = require('uv')

local _platform = _os.type()
local _path
local _options

if (_platform == 'linux') then

    _path = '/bin/ping'
    _options = {'-n', '-w 2', '-c 1'}

elseif (_platform == 'win32' ) then
    _path = 'C:/windows/system32/ping.exe'
    _options = {'-n', '1', '-w', '3000'}

elseif (_platform == 'darwin') then
    _path = '/sbin/ping'
    _options = {'-n', '-t 2', '-c 1'}

else 
    io.stderr:write('Your platform is not supported.  We currently support Linux, Windows and OSX')
    os.exit(-1)
end

function pingHost(host, cb)

    local output = ""
    local ping = nil

    table.insert(_options, host)
    ping = _child.spawn(_path, _options)
    table.remove(_options)

    ping:on('error', function(err)

        local error = 'pingcheck: There was an error while executing the ping program. Please check the path or permissions.'
        error = error .. '\npath: ' .. _path
        error = error .. '\n' .. tostring(err)
        
        return cb and cb(error)

    end)

    ping.stdout:on('data', function (data)
        output = output .. tostring(data)
    end)

    ping.stderr:on('data', function (data)
        output = output .. tostring(data) 
    end)

    ping:on('exit', function (code)        

        -- If the there was an unknown host return that error
        if ( string.find(output, "unknown host") ) then
            return cb and cb('ERROR: The host "' .. host .. '" was not found')
        end

        -- If the there was an unknown host return that error (windows error message) 
        if ( string.find(output, "could not find host") ) then
            return cb and cb('ERROR: The host "' .. host .. '" was not found')
        end

        -- If there was no output, there was an error, mark it as failed
        if (output == "") then
            return cb and cb('ERROR: Unable to obtain any output')
        end

        -- If the process did not exit correctly, the host is down
        if (code ~= 0) then
            return cb and cb('ERROR: Exit code is ' .. code)
        end

        -- Parse the data to get the ping time
        local pingTime, index, prevIndex, i, j, time = 0, 0, 0, 0, 0, 0

        while true do

            prevIndex = index
            index = string.find(output, "\n", index+1)

            if index == nil then break end

            local line = string.sub(output, prevIndex, index-1)
            i, j, time  = string.find(line, "time=([0-9]*%.?[0-9]+)")

            if(time) then 
                pingTime = tonumber(time)
                break
            end

        end        

        return cb and cb(nil, pingTime)        

    end)

end

exports.ping = pingHost