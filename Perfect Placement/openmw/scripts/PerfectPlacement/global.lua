--[[
	Mod: Perfect Placement OpenMW
	Author: Hrnchamd
	Version: 2.2beta
]]--

local async = require('openmw.async')

local movement = nil

return {
	eventHandlers = {
		["PerfectPlacement:Move"] = function(e)
			movement = { activeObj = e.activeObj, position = e.newPosition, rotation = e.newRotation }
		end,
		["PerfectPlacement:Drop"] = function(e)
			movement = { activeObj = e.activeObj, position = e.newPosition, rotation = e.newRotation }
		end,
	},
	engineHandlers = {
		onUpdate = function(dt)
			if movement then
				movement.activeObj:teleport(movement.activeObj.cell, movement.position, movement.rotation)
				movement = nil
			end
		end
	}
}