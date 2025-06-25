local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

local DEBUG = true
local DIGGING = false
local MODE = "Coroutine" -- Default mode, can be changed in the UI.

local CONFIG = {
	Tolerance = 27, -- Distance tolerance for clicking.
	WaitWhenClicked = 125, -- Wait time when clicked (miliseconds)
	WaitWhenNotClicked = 25, -- Wait time when not clicked (miliseconds)
}

local function logFunc(...)
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

local function StartTheDiggering()
	-- probably heavily unoptimised to check for the ui every loop but it shouldn't make that much of a diff.
	while DIGGING do
		local DigUI = PlayerGui:find_first_child("Dig")
		if not DigUI:isvalid() then
			logFunc("Dig UI became invalid")
			DIGGING = false
			return
		end

		local Area_Strong = ReturnFirstDescendant(DigUI, "Area_Strong")
		if not Area_Strong:isvalid() then
			logFunc("Area_Strong became invalid")
			DIGGING = false
			return
		end

		local PlayerBar = ReturnFirstDescendant(DigUI, "PlayerBar")
		if not PlayerBar:isvalid() then
			logFunc("PlayerBar became invalid")
			DIGGING = false
			return
		end

		local success, err = pcall(function()
			local PlayerBarPos = PlayerBar.gui_position + (PlayerBar.gui_size / 2)
			local Area_StrongPos = Area_Strong.gui_position + (Area_Strong.gui_size / 2)
			local Distance = math.abs(PlayerBarPos.x - Area_StrongPos.x)

			local Clicked = false
			if Distance <= CONFIG.Tolerance then
				input.simulate_mouse_click(MOUSE1)
				Clicked = true
			end

			wait(Clicked and CONFIG.WaitWhenClicked or CONFIG.WaitWhenNotClicked)
		end)

		if not success then
			logFunc("Error in dig loop: " .. tostring(err))
			DIGGING = false
			return
		end
	end
end

local ui = gui.create("Dig Settings", false)
ui:set_pos(100, 100)
ui:set_size(400, 250)

local slider = ui:add_slider("slider1", "Tolerance - Supports Decimals", 0, 150, CONFIG.Tolerance)
slider:change_callback(function()
	CONFIG.Tolerance = slider:get_value()
end)

local slider2 = ui:add_slider("slider2", "Wait When Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenClicked)
slider2:change_callback(function()
	CONFIG.WaitWhenClicked = math.floor(slider2:get_value())
end)

local slider3 =
	ui:add_slider("slider3", "Wait When Not Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenNotClicked)
slider3:change_callback(function()
	CONFIG.WaitWhenNotClicked = math.floor(slider3:get_value())
end)

local combo1 = ui:add_combo("combo1", "Dig Mode", { "Coroutine - Press Q (can't be untoggled.)", "Thread - Hold Q" }, 1)
combo1:change_callback(function()
	local Index = combo:get_value()

	MODE = (Index == 1) and "Coroutine" or "Thread"
end)

hook.addkey(0x51, "womp", function(KD)
	DIGGING = KD

	if DIGGING then
		if MODE == "Coroutine" then
			coroutine.resume(coroutine.create(StartTheDiggering))
		else
			spawn(StartTheDiggering)
		end
	end
end)
