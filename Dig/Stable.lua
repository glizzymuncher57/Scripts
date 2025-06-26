local Workspace = game:get_service("Workspace")
local World = Workspace:find_first_child("World")
local Map = World and World:find_first_child("Map")

local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

local DEBUG = true
local DIGGING = false

local CONFIG = {
	Tolerance = 27, -- Distance tolerance for clicking.
	WaitWhenClicked = 50, -- Wait time when clicked (miliseconds)
	WaitWhenNotClicked = 0, -- Wait time when not clicked (miliseconds)
}

-- Cached Internals
local nil_instance = nil_instance
local abs = math.abs
local floor = math.floor
local simulate_mouse_click = input.simulate_mouse_click

-- Util based functions
local function LogFunc(...)
	if DEBUG then
		log.add(..., color(1, 0, 0, 1))
	end
end

local function ReturnFirstDescendant(Parent, Name)
	for _, Descendant in pairs(Parent:get_descendants()) do
		if Descendant.name == Name then
			return Descendant
		end
	end

	return nil_instance
end

-- Main Digging Function
local function StartTheDiggering()
	-- probably heavily unoptimised to check for the ui every loop but it shouldn't make that much of a diff.
	while DIGGING do
		local DigUI = PlayerGui:find_first_child("Dig")
		if not DigUI:isvalid() then
			LogFunc("Dig UI became invalid")
			DIGGING = false
			return
		end

		local Area_Strong = ReturnFirstDescendant(DigUI, "Area_Strong")
		if not Area_Strong:isvalid() then
			LogFunc("Area_Strong became invalid")
			DIGGING = false
			return
		end

		local PlayerBar = ReturnFirstDescendant(DigUI, "PlayerBar")
		if not PlayerBar:isvalid() then
			LogFunc("PlayerBar became invalid")
			DIGGING = false
			return
		end

		local success, err = pcall(function()
			local PlayerBarPos = PlayerBar.gui_position + (PlayerBar.gui_size / 2)
			local Area_StrongPos = Area_Strong.gui_position + (Area_Strong.gui_size / 2)
			local Distance = abs(PlayerBarPos.x - Area_StrongPos.x)

			local Clicked = false
			if Distance <= CONFIG.Tolerance then
				input.simulate_mouse_click(MOUSE1)
				Clicked = true
			end

			wait(Clicked and CONFIG.WaitWhenClicked or CONFIG.WaitWhenNotClicked)
		end)

		if not success then
			LogFunc("Error in dig loop: " .. tostring(err))
			DIGGING = false
			return
		end
	end
end

local function Initialise()
	local ui = gui.create("Dig Settings", false)
	ui:set_pos(100, 100)
	ui:set_size(400, 200)

	local slider = ui:add_slider("slider1", "Tolerance - Supports Decimals", 0, 150, CONFIG.Tolerance)
	slider:change_callback(function()
		CONFIG.Tolerance = slider:get_value()
	end)

	local slider2 =
		ui:add_slider("slider2", "Wait When Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenClicked)
	slider2:change_callback(function()
		CONFIG.WaitWhenClicked = floor(slider2:get_value())
	end)

	local slider3 =
		ui:add_slider("slider3", "Wait When Not Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenNotClicked)
	slider3:change_callback(function()
		CONFIG.WaitWhenNotClicked = floor(slider3:get_value())
	end)

	hook.addkey(0x51, "Dig", function(KD)
		DIGGING = KD

		if DIGGING then
			coroutine.resume(coroutine.create(StartTheDiggering))
		end
	end)
end

local S, E = pcall(Initialise)
if not S then
	LogFunc(E)
end
