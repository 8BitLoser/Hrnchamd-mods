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
			movement = { active = e.active, position = e.newPosition, rotation = e.newRotation }
		end,
		["PerfectPlacement:Drop"] = function(e)
			movement = { active = e.active, position = e.newPosition, rotation = e.newRotation }
		end,
	},
	engineHandlers = {
		onUpdate = function(dt)
			if movement then
				movement.active:teleport(movement.active.cell, movement.position, movement.rotation)
				movement = nil
			end
		end
	}
}