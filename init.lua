local framework = require('./modules/framework')
local CommandOutputDataSource = framework.CommandOutputDataSource
local PollerCollection = framework.PollerCollection
local DataSourcePoller = framework.DataSourcePoller
local Plugin = framework.Plugin
local los = require('los')
local table = require('table')
local string = require('string')

local isEmpty = framework.string.isEmpty
local clone = framework.table.clone

local params = framework.params 
params.name = 'Boundary Pingcheck plugin'
params.version = '1.1'

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

local function createPollers (params, ping_command) 
  local pollers = PollerCollection:new() 
  for i, item in ipairs(params.items) do
    
    local cmd = clone(ping_command)
    table.insert(cmd.args, item.host)
    cmd.info = item.source

    local data_source = CommandOutputDataSource:new(cmd)
    local poll_interval = tonumber(item.pollInterval or params.pollInterval) * 1000
    local poller = DataSourcePoller:new(poll_interval, data_source)
    pollers:add(poller)
  end

  return pollers
end

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

local pollers = createPollers(params, ping_command)
local plugin = Plugin:new(params, pollers)

function plugin:onParseValues(data) 
  local result = {}

  local value = parseOutput(self, data['output'])
  result['PING_RESPONSETIME'] = { value = value, source = data['info'] }
  return result
end

plugin:run()
