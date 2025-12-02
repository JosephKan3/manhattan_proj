-- If start is given as arg, run nuclearReactor.lua in a separate process. Otherwise, run az5
local shell = require("shell")
local thread = require("thread")

local args, options = shell.parse(...)

if #args > 0 and args[1] == "start" then
  print("Starting nuclearReactor.lua in background...")
  local proc = thread.create(os.execute, "/home/nuclearReactor.lua")
  proc:detach() -- # detach from current process
  print("nuclearReactor.lua started with thread ID: " .. tostring(proc:id()))
else
  os.execute("/home/az5.lua")

end