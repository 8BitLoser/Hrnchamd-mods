--[[
    Mod: Daggerfallwind
    Author: Hrnchamd
    Version: 0.2
]]--

local quantizer = math.pi / 8.0
local flattener = 0.75
local textScaling = 2.2

local function lerp(a, b, t)
	return (1 - t) * a + t * b
end

local function flatten(ref, node)
	local look_to = ref.position - tes3.player.position
	local player_z = math.atan2(look_to.x, look_to.y)
	local dz = ref.orientation.z - player_z
	local dzq = math.round(dz / quantizer) * quantizer
	local m = tes3matrix33.new()
	local r = tes3matrix33.new()
	local s = tes3matrix33.new()
	
	m:toRotationZ(dzq - dz + ref.orientation.z)
	s:toIdentity()
	local sz = math.sin(player_z)
	local cz = math.cos(player_z)
	s.x.x = 1 - flattener * sz * sz
	s.x.y = 0 - flattener * cz * sz
	s.y.x = 0 - flattener * sz * cz
	s.y.y = 1 - flattener * cz * cz

	local race = ref.object.race
	r:toIdentity()
	if race then
		if ref.object.female then
			r.x.x = race.weight.female
			r.y.y = r.x.x
			r.z.z = race.height.female
		else
			r.x.x = race.weight.male
			r.y.y = r.x.x
			r.z.z = race.height.male
		end
	end

	node.rotation = s * m * r
end

local function flattenAll(e)
	for _, cell in pairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences() do
			local t = ref.object.objectType
			if t == tes3.objectType.npc or t == tes3.objectType.creature then
				local node = ref.sceneNode
				if node then
					flatten(ref, node)
					node.rotation.x.z = 1e-6
				end
			end
		end
	end
end

local function unflattenAll()
	for _, cell in pairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences(tes3.objectType.npc) do
			local node = ref.sceneNode
			local mobile = ref.mobile
			if node and mobile and mobile.animationController then
				node.rotation = mobile.animationController.groundPlaneRotation
			end
		end
	end
end

----------------------------


local dungeoncore
local expire_timer

local function loadTextNoiseTexture()
	dungeoncore = niSourceTexture.createFromPath("Textures\\__textgrit.dds")
end

local function pointSampleTextures(e)
	-- Skip UI nifs
	if string.sub(e.path, 1, 4) == "menu" then return end

	-- Set all maps to point sample + use mips
	for child in table.traverse(e.node.children) do
		local prop = child.texturingProperty
		if prop then
			for _, map in pairs(prop.maps) do
				if map then
					map.filterMode = ni.texturingPropertyFilterMode.nearestMipNearest
				end
			end
		end
	end
	e.node:updateProperties()
end

local function onTimer(e)
	local menu = tes3ui.findHelpLayerMenu("DaggerfallNotify")
	if menu then
		menu.visible = false
	end
	expire_timer = nil
end

local function onNewNotify(e)
	local text = e.element.children[2].children[2].children[1].text
	local timeout = 1.6 * e.element:getPropertyFloat("MenuNotify_timestamp")
	
	local menu = tes3ui.findHelpLayerMenu("DaggerfallNotify")
	local label

	if not menu then
		menu = tes3ui.createHelpLayerMenu{ id = "DaggerfallNotify" }
		menu.alpha = 1
		menu.absolutePosAlignY = 1
		menu.minWidth = menu.maxWidth
		menu.minHeight = 80
		
		label = menu:createLabel{ id = "MenuNotify_message", text = text }
		label.widthProportional = 1
		label.height = 80
		label.wrapText = true
		label.justifyText = tes3.justifyText.center
		label.color = { 0.8863, 0.5895, 0.2980 }
		
		label.parent.contentPath = nil
		label.parent.paddingTop = 15
	else
		label = menu:findChild("MenuNotify_message")
		label.text = text
	end

	e.element.visible = false
	menu.visible = true
	menu:updateLayout()

	local textNode = label.sceneNode
	textNode.scale = textScaling
	textNode.translation.x = (0.5 * (1 - textScaling)) * menu.maxWidth

	local textShape = textNode.children[1]
	textShape.texturingProperty = textShape.texturingProperty:clone()
	textShape.texturingProperty.baseMap.filterMode = 0
	textShape.texturingProperty.darkMap = niTexturingPropertyMap.new()
	textShape.texturingProperty.darkMap.texture = dungeoncore
	textShape.texturingProperty.darkMap.filterMode = 0

	textNode:update()
	textShape:updateProperties()
	
	if expire_timer then
		expire_timer:cancel()
		expire_timer = nil
	end
	expire_timer = timer.start{ type = timer.real, duration = timeout, callback = onTimer, iterations = 1, persist = false }
end

local function init()
	loadTextNoiseTexture()
	mge.shaders.load{ name = "DaggerfallMod" }

	event.register(tes3.event.meshLoaded, pointSampleTextures)
	event.register(tes3.event.simulate, unflattenAll)
	event.register(tes3.event.cameraControl, flattenAll)
	event.register(tes3.event.uiActivated, onNewNotify, { filter = "MenuNotify1" })
	event.register(tes3.event.uiActivated, onNewNotify, { filter = "MenuNotify2" })
	event.register(tes3.event.uiActivated, onNewNotify, { filter = "MenuNotify3" })
	mwse.log("daggerfall-flattener [beta] initialized.")
end
event.register(tes3.event.initialized, init)
