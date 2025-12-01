local component = require("component")
local shell = require("shell")
local term = require("term")

local args, options = shell.parse(...)
local reactor = component.reactor_chamber

-- Validate component
if not reactor then
    error("reactor_chamber component not found")
end

-- Validate arguments
if #args < 1 then
    term.write("Usage: reactor <method> [value]\n")
    term.write("Example: reactor setActive true\n")
    return
end

-- Extract method and optional argument
local methodName = args[1]
local methodArg = args[2]

-- Resolve argument type
local function parseArg(v)
    if v == nil then return nil end
    if v == "true" then return true end
    if v == "false" then return false end
    local num = tonumber(v)
    if num ~= nil then return num end
    return v
end

local parsedArg = parseArg(methodArg)

-- Execute method
local ok, result
if parsedArg ~= nil then
    ok, result = pcall(reactor[methodName], parsedArg)
else
    ok, result = pcall(reactor[methodName])
end

-- Show result or error
if not ok then
    error("Execution failed: " .. tostring(result))
else
    term.write("Method '" .. methodName .. "' executed successfully")
    if result ~= nil then
        term.write(" → " .. tostring(result))
    end
    term.write("\n")
end
