-- Function to turn the reactor_chamber component on

local component = require("component")
local shell = require("shell")

local args, options = shell.parse(...)

-- Helper to read reactors.txt (power button is second token)
local function readReactorsList(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local list = {}
	for line in f:lines() do
		local cleaned = line:match("^%s*(.-)%s*$")
		if cleaned ~= "" then
			local taddr, paddr = cleaned:match('^(%S+)%s+(%S+)')
			if paddr then
				table.insert(list, paddr)
			else
				table.insert(list, cleaned)
			end
		end
	end
	f:close()
	return #list > 0 and list or nil
end

local function readAddress(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local raw = f:read("*a")
	f:close()
	if not raw then return nil end
	local cleaned = raw:match("^%s*(.-)%s*$")
	return cleaned ~= "" and cleaned or nil
end

local function activateAddress(addr)
	local ok, compAddr = pcall(component.get, addr)
	if not ok or not compAddr then
		print("Could not find component for address: " .. tostring(addr))
		return false
	end
	local success, proxy = pcall(component.proxy, compAddr)
	if not success or not proxy then
		print("Could not proxy component: " .. tostring(addr))
		return false
	end
	for side = 0, 5 do
		proxy.setOutput(side, 15)
	end
	print("Activated reactor via power button: " .. tostring(addr))
	return true
end

-- Behaviour:
-- `activate.lua all` -> activate all reactors from reactors.txt (or legacy files)
-- `activate.lua <index>` -> activate reactor at index in reactors.txt
-- `activate.lua <address>` -> activate specific address
local reactors = readReactorsList("reactors.txt")
if args[1] == "all" then
	if reactors then
		for i, addr in ipairs(reactors) do activateAddress(addr) end
	else
		local primary = readAddress("power_button_address.txt")
		local secondary = readAddress("secondary_power_button_address.txt")
		if primary then activateAddress(primary) end
		if secondary then activateAddress(secondary) end
	end
elseif tonumber(args[1]) then
	local idx = tonumber(args[1])
	if reactors and reactors[idx] then
		activateAddress(reactors[idx])
	else
		print("No reactor at index " .. tostring(idx))
	end
elseif args[1] then
	activateAddress(args[1])
else
	-- default: activate primary (legacy)
	local primary = readAddress("power_button_address.txt")
	if primary then
		activateAddress(primary)
	else
		print("No primary power button found. Use 'activate all' or run setup.lua")
	end
end