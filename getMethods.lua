local component = require("component")
local shell = require("shell")

local term = require("term")
local args, options = shell.parse(...)

local function getMethods(componentName)
	local methods = component.methods(component[componentName].address)

	print("-------------------------------------------------------")
	print("------------            " .. componentName .. "            -------------")
	print("-------------------------------------------------------")
	for method, _ in pairs(methods) do
		print("*****************************************************")
		print(method .. " : " .. tostring(component[componentName][method]))
	end
	print("*****************************************************\n \n \n")
end

local function printUsage()
	print("This is a script to get functions provided by various components.")
	print("Components are not limited to actual components provided by opencomputers.")
	print("Try it on blocks from other mods. Such as an applied energistics export bus.\n")
	print("Usage: \n getMethods all >> filename\n getMethods componentName | less\n eg: getMethods export_bus >> export_bus.txt")
	print("If you use the pipe to less ( '| less' ), arrow keys to navigate, q to exit")
end

if type(args[1]) == "string" then
	if args[1] == "all" then
		local seenTypes = {}
		for _, componentName in pairs(component.list()) do
			if not seenTypes[componentName] then
				seenTypes[componentName] = true
				getMethods(componentName)
			end
		end
		return
	else
		local success, error = pcall(getMethods, args[1])
		if success then
			return
		else
			print("Not a valid component\n\n")
			printUsage()
			return
		end
	end
else
	printUsage()
	return
end
