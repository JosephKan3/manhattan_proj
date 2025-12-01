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
local methodArgs = {select(2, table.unpack(args))}

-- Resolve argument type
local function parseArg(v)
    if v == nil then return nil end
    if v == "true" then return true end
    if v == "false" then return false end
    local num = tonumber(v)
    if num ~= nil then return num end
    return v
end

for i = 1, #methodArgs do
    methodArgs[i] = parseArg(methodArgs[i])
end
-- Execute method
local ok, result
if #methodArgs > 0 then
    ok, result = pcall(reactor[methodName], table.unpack(methodArgs))
else
    ok, result = pcall(reactor[methodName])
end

-- Show result or error
if not ok then
    error("Execution failed: " .. tostring(result))
else
    term.write("Method '" .. methodName .. "' executed successfully")
    if result ~= nil then
        if type(result) == "table" then
            term.write(" → ")
            -- Recursively print table contents
            local function printTable(t, indent)
                indent = indent or ""
                for k, v in pairs(t) do
                    if type(v) == "table" then
                        term.write("\n" .. indent .. tostring(k) .. ": ")
                        printTable(v, indent .. "  ")
                    else
                        term.write("\n" .. indent .. tostring(k) .. ": " .. tostring(v))
                    end
                end
            end
            printTable(result, "  ")
        else
            term.write(" → " .. tostring(result))
        end
    end
    term.write("\n")
end