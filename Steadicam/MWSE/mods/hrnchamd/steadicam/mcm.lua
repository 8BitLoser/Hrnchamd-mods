--[[
	Mod: Steadicam
	Author: Hrnchamd
	Version: 1.0
]]--

local this = {}

local versionString = "v1.0"
local configPath = "Steadicam"
local configDefault = {
	configVersion = 1,

	bodyInertia = true,
	bodyInertiaDamping = 25,

	freeLookKeybind	= {
		keyCode = tes3.scanCode.n,
		isShiftDown = false,
		isControlDown = false,
		isAltDown = false
	}
}

local presets = {
	default = {
		firstPersonLookDamping = 4,
		freeLookDamping = 80,
		thirdPersonLookDamping = 250,
		thirdPersonFollowDamping = 143
	},
	close = {
		firstPersonLookDamping = 2,
		freeLookDamping = 20,
		thirdPersonLookDamping = 50,
		thirdPersonFollowDamping = 83
	},
	smooth = {
		firstPersonLookDamping = 15,
		freeLookDamping = 150,
		thirdPersonLookDamping = 450,
		thirdPersonFollowDamping = 200
	},
	loose = {
		firstPersonLookDamping = 120,
		freeLookDamping = 250,
		thirdPersonLookDamping = 2500,
		thirdPersonFollowDamping = 250
	}
}

function this.registerModConfig()
	table.copy(presets.default, configDefault)
	table.copy(mwse.loadConfig(configPath, configDefault), this.config)

	local template = mwse.mcm.createTemplate("Steadicam")
	template.onClose = function()
		mwse.saveConfig(configPath, this.config)

		if this.sensitivityChanged then
			tes3.game:savePlayerOptions()
			this.sensitivityChanged = nil
		end
	end
	
	local refreshPage = function()
		local pageBlock = template.elements.pageBlock
		pageBlock:destroyChildren()
		template.currentPage:create(pageBlock)
	end

	local page = template:createSideBarPage{
		postCreate = function(self)
			local block = self.elements.sideToSideBlock
			block.children[1].widthProportional = 1.25
			block.children[2].widthProportional = 0.75
			block:getTopLevelMenu():updateLayout()
		end,
		sidebarComponents = {
			mwse.mcm.createInfo{ text = "Hover over a control for a help tip." },
		},
		components = {
			{
				class = "Info",
				label = "Steadicam " .. versionString,
				paddingBottom = 10
			},
			{
				class = "Category",
				label = "Presets",
				postCreate = function(self)
					local container = self.elements.subcomponentsContainer
					container.flowDirection = tes3.flowDirection.leftToRight
					container.autoWidth = true
					container.widthProportional = nil
				end,
				components = {
					{
						class = "Button",
						buttonText = "Default",
						description = "Reset settings to default.",
						callback = function(self)
							table.copy(presets.default, this.config)
							refreshPage()
						end
					},
					{
						class = "Button",
						buttonText = "Close",
						description = "Set camera to follow the mouse more closely than the default preset.",
						callback = function(self)
							table.copy(presets.close, this.config)
							refreshPage()
						end
					},
					{
						class = "Button",
						buttonText = "Smooth",
						description = "Set camera to follow the mouse more smoothly than the default preset.",
						callback = function(self)
							table.copy(presets.smooth, this.config)
							refreshPage()
						end
					},
					{
						class = "Button",
						buttonText = "Loose",
						description = "Set camera to swoop around like a drunk migratory bird.",
						callback = function(self)
							table.copy(presets.loose, this.config)
							refreshPage()
						end
					}
				}
			},

			{
				class = "Category",
				label = "Camera angle",
				components = {
					{
						class = "Slider",
						label = "First person smoothness",
						description = "The smoothness of the first person view when looking around.",
						min = 1, max = 250, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "firstPersonLookDamping", table = this.config }
					},
					{
						class = "Slider",
						label = "First person free-look smoothness",
						description = "The smoothness of the first person view when looking around.",
						min = 1, max = 250, step = 1, jump = 10,
						variable = mwse.mcm:createTableVariable{ id = "freeLookDamping", table = this.config }
					},
					{
						class = "Slider",
						label = "Third person smoothness",
						description = "The smoothness of the third person view when looking around.",
						min = 1, max = 1000, step = 1, jump = 10,
						variable = mwse.mcm:createTableVariable{ id = "thirdPersonLookDamping", table = this.config }
					}
				}
			},

			{
				class = "Category",
				label = "Camera following",
				components = {
					{
						class = "Slider",
						label = "Third person motion smoothness",
						description = "The smoothness of the position of the third person camera as it follows the player. Higher smoothness will make the camera lag behind when the player is moving quickly.",
						min = 1, max = 250, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "thirdPersonFollowDamping", table = this.config }
					}
				}
			},

			{
				class = "Category",
				label = "Body",
				components = {
					{
						class = "OnOffButton",
						label = "Body inertia",
						description = "In first person view, controls if the player's body and arms has added inertia. They will take a short time to react to camera changes.",
						variable = mwse.mcm:createTableVariable{ id = "bodyInertia", table = this.config }
					},
					{
						class = "Slider",
						label = "Body inertia smoothness",
						description = "The reaction time of the body and arms to changes in look direction.",
						min = 10, max = 100, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "bodyInertiaDamping", table = this.config }
					}
				}
			},

			{
				class = "Category",
				label = "Controls",
				components = {
					{
						class = "KeyBinder",
						label = "Toggle free look key",
						description = "Press to toggle free look mode. The mouse will control the camera without changing movement direction. Works in both first and third person.",
						paddingBottom = 10,
						min = 1, max = 250, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{
							id = "freeLookKeybind",
							table = this.config,
							defaultSetting = { keyCode = tes3.scanCode.n }
						}
					},
					{
						class = "Slider",
						label = "Horizontal mouse sensitivity",
						description = "A finer control of the game's mouse sensitivity.",
						min = 1, max = 500, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "proxySensitivityX", table = this },
						callback = function(e)
							tes3.worldController.mouseSensitivityX = 0.00001 * this.proxySensitivityX
							this.sensitivityChanged = true
						end
					},
					{
						class = "Slider",
						label = "Vertical mouse sensitivity",
						description = "A finer control of the game's mouse sensitivity.",
						min = 1, max = 500, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "proxySensitivityY", table = this },
						callback = function(e)
							tes3.worldController.mouseSensitivityY = 0.00001 * this.proxySensitivityY
							this.sensitivityChanged = true
						end
					}
				}
			}
		}
	}

	this.proxySensitivityX = 100000 * tes3.worldController.mouseSensitivityX
	this.proxySensitivityY = 100000 * tes3.worldController.mouseSensitivityY

	template:register()
	mwse.log("[Steadicam] " .. versionString .. " loaded successfully.")
end

return this