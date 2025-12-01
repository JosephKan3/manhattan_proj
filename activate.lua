-- Function to turn the reactor_chamber component on

local component = require("component")
local shell = require("shell")

local term = require("term")
local args, options = shell.parse(...)

local reactor_chamber = component.reactor_chamber
reactor_chamber.setActive(true)