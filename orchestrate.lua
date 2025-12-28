local shell = require("shell")
local thread = require("thread")
local event = require("event")

local args, options = shell.parse(...)

-- Helper function to read address from file
local function readAddress(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local raw = f:read("*a")
  f:close()
  if not raw then
    return nil
  end
  local cleaned = raw:match("^%s*(.-)%s*$")
  if cleaned == "" then
    return nil
  end
  return cleaned
end

-- Check if secondary reactor is configured
-- Discover reactor configurations. Preference order:
-- 1) `reactors.txt` where each non-empty line is: <transposerAddr> <powerButtonAddr>
-- 2) fallback to primary files + legacy secondary files for backward compatibility
local reactors = {}
local function readReactorsList(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local list = {}
  for line in f:lines() do
    local cleaned = line:match("^%s*(.-)%s*$")
    if cleaned ~= "" then
      local taddr, paddr = cleaned:match('^(%S+)%s+(%S+)')
      if not taddr then taddr = cleaned end
      table.insert(list, {transposer = taddr, powerbutton = paddr})
    end
  end
  f:close()
  return #list > 0 and list or nil
end

local listed = readReactorsList("reactors.txt")
if listed then
  reactors = listed
else
  local primaryTransposer = readAddress("transposer_address.txt")
  local primaryPowerButton = readAddress("power_button_address.txt")
  if primaryTransposer and primaryPowerButton then
    table.insert(reactors, {transposer = primaryTransposer, powerbutton = primaryPowerButton})
  end
  local secondaryTransposer = readAddress("secondary_transposer_address.txt")
  local secondaryPowerButton = readAddress("secondary_power_button_address.txt")
  if secondaryTransposer and secondaryPowerButton then
    table.insert(reactors, {transposer = secondaryTransposer, powerbutton = secondaryPowerButton})
  end
end

if #args > 0 and args[1] == "start" then
  print("Starting nuclearReactor.lua in background...")
  
  -- Create reactor threads for every configured reactor
  local reactor_threads = {}
  if #reactors == 0 then
    -- No configuration found, start a single default reactor (old behavior)
    reactor_threads[1] = thread.create(function()
      os.execute("/home/nuclearReactor.lua")
    end)
  else
    for i, cfg in ipairs(reactors) do
      print(string.format("Starting nuclearReactor.lua for reactor %d...", i))
      local cmd
      if cfg.transposer and cfg.powerbutton then
        cmd = string.format("/home/nuclearReactor.lua %s %s", cfg.transposer, cfg.powerbutton)
      elseif cfg.transposer then
        cmd = string.format("/home/nuclearReactor.lua %s", cfg.transposer)
      else
        cmd = "/home/nuclearReactor.lua"
      end
      reactor_threads[i] = thread.create(function()
        os.execute(cmd)
      end)
    end
  end
  
  local cleanup_thread = thread.create(function()
    event.pull("interrupted")
    print("Interrupt received - initiating AZ5 shutdown...")
  end)
  
  local input_thread = thread.create(function()
    print("Press Enter to stop the reactor...")
    io.read()
    print("User requested shutdown - initiating AZ5 shutdown...")
  end)
  
  local monitor_thread = thread.create(function()
    while true do
      -- If any reactor thread stops, trigger shutdown
      for i, rt in ipairs(reactor_threads) do
        if rt:status() ~= "running" then
          print(string.format("Reactor %d thread no longer running - initiating AZ5 shutdown...", i))
          return
        end
      end
      os.sleep(0.5)
    end
  end)
  
  -- Wait for any thread to complete
  local finished_thread = thread.waitForAny({cleanup_thread, input_thread, monitor_thread})
  
  -- Kill all reactor threads and helpers
  for _, rt in ipairs(reactor_threads) do
    if rt and rt:status() == "running" then
      rt:kill()
    end
  end
  cleanup_thread:kill()
  input_thread:kill()
  monitor_thread:kill()
  
  -- Run AZ5 emergency shutdown
  os.execute("/home/az5.lua")
  
else
  os.execute("/home/az5.lua")
end