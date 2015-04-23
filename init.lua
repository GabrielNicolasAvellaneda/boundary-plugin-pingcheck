local framework = require('./modules/framework')
local CommandOutputDataSource = framework.CommandOutputDataSource
local Plugin = framework.Plugin
local los = require('los')
local table = require('table')
local string = require('string')

local isEmpty = framework.string.isEmpty

local commands = {
  linux = { path = '/bin/ping', args = {'-n', '-w 2', '-c 1'} },
  win32 = { path = 'C:/windows/system32/ping.exe', args = {'-n', '1', '-w', '3000'} },
  darwin = { path = '/sbin/ping', args = {'-n', '-t 2', '-c 1'} }
}

local ping_command = commands[los.type()] 
if ping_command == nil then
  io.stderr:write('Your platform is not supported.  We currently support Linux, Windows and OSX\n')
  process:exit(-1)
end

table.insert(ping_command.args, 'www.google.com')

local function parseOutput(context, output) 
  
  assert(output ~= nil, 'parseOutput expect some data')

  if isEmpty(output) then
    context:emit('error', 'Unable to obtain any output.')
    return
  end

  if (string.find(output, "unknown host") or string.find(output, "could not find host.")) then
    context:emit('error', 'The host ' .. context.args[#context.args] .. ' was not found.')
    return
  end

  local index = 0
  local prevIndex = 0
  while true do
    index = string.find(output, '\n', prevIndex+1) 
    if index == nil then break end

    local line = string.sub(output, prevIndex, index-1)
    local _, _, time  = string.find(line, "time=([0-9]*%.?[0-9]+)")
    if(time) then 
      return tonumber(time)
    end
    prevIndex = index
  end

  return -1
end

local data_source = CommandOutputDataSource:new(ping_command)

local params = { pollInterval = 2000 }
params.name = 'Boundary Pingcheck plugin'
params.version = '1.1'
local plugin = Plugin:new(params, data_source)

function plugin:onParseValues(data) 
  local result = {}

  result['PING_RESPONSETIME'] = parseOutput(self, data)

  return result
end

plugin:run()
