local boundary = require('boundary')
local ping = require('ping')
local timer = require('timer')
local async = require('async')

local HOST_IS_DOWN = -1

local param = boundary.param

--[[ 
If we do not have a poll Interval for the plugin set it
each host has its own poll interval
]]

local pollInterval = param.pollInterval or 1000

-- Keep track of the host's last polled time so we don't hammer the host
local previous = {}

function logSuccess(source, duration)
    io.stdout:write('PING_RESPONSETIME '..duration..' '..source..'\n')
end

function logFailure(err, source, duration)
    if (err) then
        io.stderr:write(err .. '\n')
    else
        io.stdout:write('PING_RESPONSETIME '..HOST_IS_DOWN..' '..source..'\n')
    end
end

function complete(err)
    if (err) then io.stderr:write(err) end
end

-- Validate we have Hosts to ping
if (not param.items) then
    io.stdout:write('No configuration has been setup yet, so we\'re exiting\n')
    os.exit(1);
end

-- Validate the hosts intervals
table.foreach(param.items, function(hIndex)

    local host = param.items[hIndex]
    local pollInterval = 5

    if host.pollInterval then
        pollInterval = tonumber(host.pollInterval)
    end

    --Lets assume that the poll interval associated with hosts is provided in seconds

    host.pollInterval = pollInterval

end)

function pingHost(host, cb)

    -- Check if we need to poll again

    local source = host.source

    if(not previous[source]) then
        previous[source] = os.time()
    end    	

    local now = os.time()

    if ( (previous[source] + host.pollInterval) > now ) then
        return cb(nil)
    else
        previous[source] = now
    end

    -- Ping the host
    ping.ping(host.host, function(err, responseTime)
    
        if (err) then
            logFailure(err, source, responseTime)

        elseif (responseTime == nil or responseTime < 0) then
            logFailure(nil, source, responseTime)

        else
            logSuccess(source, responseTime)
        end        

        return cb(nil)
    end)

end

function poll()

    async.forEach(param.items, pingHost, complete)
    timer.setTimeout(pollInterval, poll)
end

-- Lets get the party started
poll()