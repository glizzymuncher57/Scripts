-- Services
local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

-- Configuration
local CONFIG = {
	Tolerance = 27, -- Distance tolerance for clicking.
	WaitWhenClicked = 50, -- Wait time when clicked (miliseconds)
	WaitWhenNotClicked = 0, -- Wait time when not clicked (miliseconds)
	REPEAT_CYCLE = 3,
	CMP_WAIT = 300,
	WAIT_BETWEEN_DIG = 500, -- Wait time between the mouse clicking and the script checking if the ui is valid (miliseconds)

	ADVANCED_MOVEMENT_ENABLED = false,
	MOVEMENT_REPEAT_Z = 3,
	MOVEMENT_REPEAT_X = 3,
}

-- State
local DEBUG = true
local DIGGING = false
local AUTO_MODE = false
local CURRENT_MOVEMENT_PATTERN = 1
local CURRENT_MOVEMENT_PATTERN_REPEAT = 0
local UI_OPEN = {
	MovementSettings = false,
	DigSettings = false,
}

-- Constants
local FILE_NAME = "DigConfig.json"
local WEBHOOK =
	"https://discord.com/api/webhooks/1391934377725788221/Ap2ipogx3L6fZQR2FtQBgAJm_Vt7deYqiattCDP9zSj82klrYjswvhH3uRGGwX-un_rY" -- yes this is an exposed hook Lol!
local MOVEMENT_KEYS = { 0x57, 0x44, 0x53, 0x41 } -- W, D, S, A
local MOVEMENT_PATTERNS = {}

-- Cached Internals
local nil_instance = nil_instance
local abs = math.abs
local floor = math.floor
local simulate_mouse_click = input.simulate_mouse_click
local file = file
local post = http.post

-- Utility Functions
local function LogWebhook(...)
	local embed = {
		content = "[DIG]: " .. tostring(...),
	}

	post(WEBHOOK, table_to_JSON(embed), function(_, status)
		if status == 200 then
			print("Error logged successfully.")
		else
			print("Failed to log error. Status code: " .. tostring(status))
		end
	end)
end

local function LogFunc(...)
	if DEBUG then
		log.add("[DIG]: " .. tostring(...), color(1, 0, 0, 1))
	end
end

local function LogNoti(...)
	log.notification("[DIG]: " .. tostring(...), "Info")
end

local function SafeCall(func, funcName, ...)
	local success, result = pcall(func, ...)
	if not success then
		LogWebhook(("Error in %s: %s"):format(tostring(funcName), tostring(result)))
		return nil
	end
	return result
end

local function CheckElements(Elements)
	for _, Element in pairs(Elements) do
		if not Element:isvalid() then
			LogFunc(Element.name or "FAILED_TO_LOAD_NAME" .. " is invalid or does not exist.")
			return false
		end
	end

	return true
end

local function RestoreGlobals()
	DIGGING = false
	AUTO_MODE = false
	CURRENT_MOVEMENT_PATTERN = 1
	CURRENT_MOVEMENT_PATTERN_REPEAT = 0
	UI_OPEN.MovementSettings = false
	UI_OPEN.DigSettings = false
end

local function CreatePaddedText(text, desired_width)
	local text_length = string.len(text)
	local total_padding = math.max(0, desired_width - text_length)
	local left_padding = math.floor(total_padding / 2)
	local right_padding = total_padding - left_padding

	-- Create the padded string
	return string.rep(" ", left_padding) .. text .. string.rep(" ", right_padding)
end

local function CanDig()
	return Player.character
		and Player.character:find_first_child_class("Tool")
		and Player.character:find_first_child_class("Tool").name:lower():find("shovel")
end

local function IsDigging()
	return PlayerGui and PlayerGui:find_first_child("Dig") and PlayerGui:find_first_child("Dig"):isvalid()
end

--// Configuration Functions
local function SaveConfiguration()
	local ConfigString = table_to_JSON(CONFIG)
	if not ConfigString then
		LogFunc("Failed to convert configuration to JSON string.")
		return
	end

	if file.exists(FILE_NAME) then
		file.overwrite(FILE_NAME, ConfigString, "binary")
	else
		file.write(FILE_NAME, ConfigString, "binary")
	end
end

local function LoadConfiguration()
	if not file.exists(FILE_NAME) then
		return false
	end

	local ReadResult = SafeCall(file.read, "LoadConfiguration", FILE_NAME, "binary")
	if not ReadResult then
		LogFunc("Failed to read configuration file: " .. ReadResult)
		return false
	end

	local ParseResult = SafeCall(JSON_to_table, "LoadConfiguration", ReadResult)
	if not ParseResult then
		return false
	end

	-- looks fucking awful but it is what it is.
	CONFIG = {
		Tolerance = ParseResult.Tolerance or CONFIG.Tolerance,
		WaitWhenClicked = ParseResult.WaitWhenClicked or CONFIG.WaitWhenClicked,
		WaitWhenNotClicked = ParseResult.WaitWhenNotClicked or CONFIG.WaitWhenNotClicked,
		REPEAT_CYCLE = ParseResult.REPEAT_CYCLE or CONFIG.REPEAT_CYCLE,
		CMP_WAIT = ParseResult.CMP_WAIT or CONFIG.CMP_WAIT,
		ADVANCED_MOVEMENT_ENABLED = ParseResult.ADVANCED_MOVEMENT_ENABLED or CONFIG.ADVANCED_MOVEMENT_ENABLED,
		MOVEMENT_REPEAT_Z = ParseResult.MOVEMENT_REPEAT_Z or CONFIG.MOVEMENT_REPEAT_Z,
		MOVEMENT_REPEAT_X = ParseResult.MOVEMENT_REPEAT_X or CONFIG.MOVEMENT_REPEAT_X,
		WAIT_BETWEEN_DIG = ParseResult.WAIT_BETWEEN_DIG or CONFIG.WAIT_BETWEEN_DIG,
	}

	return true
end

-- Movement Functions
local function ExecuteMovementPattern()
	if MOVEMENT_PATTERNS[CURRENT_MOVEMENT_PATTERN] then
		MOVEMENT_PATTERNS[CURRENT_MOVEMENT_PATTERN]()
	end

	CURRENT_MOVEMENT_PATTERN_REPEAT = CURRENT_MOVEMENT_PATTERN_REPEAT + 1

	local REPEATS = CONFIG.REPEAT_CYCLE

	if CONFIG.ADVANCED_MOVEMENT_ENABLED then
		if CURRENT_MOVEMENT_PATTERN == 1 or CURRENT_MOVEMENT_PATTERN == 3 then
			REPEATS = CONFIG.MOVEMENT_REPEAT_Z
		elseif CURRENT_MOVEMENT_PATTERN == 2 or CURRENT_MOVEMENT_PATTERN == 4 then
			REPEATS = CONFIG.MOVEMENT_REPEAT_X
		end
	end

	if CURRENT_MOVEMENT_PATTERN_REPEAT == REPEATS then
		CURRENT_MOVEMENT_PATTERN = CURRENT_MOVEMENT_PATTERN % #MOVEMENT_KEYS + 1
		CURRENT_MOVEMENT_PATTERN_REPEAT = 0
	end

	simulate_mouse_click(MOUSE1)
	wait(CONFIG.WAIT_BETWEEN_DIG)

	if not IsDigging() then
		LogNoti("Digging UI is not valid or does not exist.")
		ExecuteMovementPattern()
		return false
	end

	return true
end

local function CreateMovementPattern(key_code)
	return function()
		wait(500)
		input.simulate_press_down(key_code)
		wait(CONFIG.CMP_WAIT)
		input.simulate_press_up(key_code)
		wait(500)
		return true
	end
end

local function InitialiseMovementPatterns()
	for i, key in ipairs(MOVEMENT_KEYS) do
		MOVEMENT_PATTERNS[i] = CreateMovementPattern(key)
	end
end

--// Digging Functions
local function StartDigging()
	local DIGUI = PlayerGui:find_first_child("Dig")
	if not DIGUI:isvalid() then
		LogFunc("Dig UI is not valid or does not exist.")
		DIGGING = false
		return
	end

	local Area_Strong = DIGUI:find_first_descendant("Area_Strong")
	local PlayerBar = DIGUI:find_first_descendant("PlayerBar")

	if not CheckElements({ Area_Strong, PlayerBar }) then
		LogFunc("One or more required UI elements are invalid.")
		DIGGING = false
		return
	end

	while DIGGING and IsDigging() do
		if not CheckElements({ DIGUI, Area_Strong, PlayerBar }) then
			LogFunc("One or more required UI elements became invalid.")
			DIGGING = false
			return true
		end

		local PlayerBarPos = PlayerBar.gui_position + (PlayerBar.gui_size / 2)
		local Area_StrongPos = Area_Strong.gui_position + (Area_Strong.gui_size / 2)
		local Distance = abs(PlayerBarPos.x - Area_StrongPos.x)

		local Clicked = false
		if Distance <= CONFIG.Tolerance then
			simulate_mouse_click(MOUSE1)
			Clicked = true
		end

		wait(Clicked and CONFIG.WaitWhenClicked or CONFIG.WaitWhenNotClicked)
	end

	DIGGING = false
end

local function CreateDigSettingsUI()
	local ui = gui.create("Dig Settings", false)
	ui:set_pos(100, 100)
	ui:set_size(400, 380)

	local slider = ui:add_slider("Tolerance - Supports Decimals", 0, 150, CONFIG.Tolerance)
	slider:change_callback(function()
		CONFIG.Tolerance = slider:get_value()
		SaveConfiguration()
	end)

	local slider2 = ui:add_slider("Wait When Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenClicked)
	slider2:change_callback(function()
		CONFIG.WaitWhenClicked = floor(slider2:get_value())
		SaveConfiguration()
	end)

	local slider3 = ui:add_slider("Wait When Not Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenNotClicked)
	slider3:change_callback(function()
		CONFIG.WaitWhenNotClicked = floor(slider3:get_value())
		SaveConfiguration()
	end)

	local CMPREPEAT = ui:add_slider("CMP Repeat Cycle - WHOLE NUMBERS ONLY.", 1, 10, CONFIG.REPEAT_CYCLE)
	CMPREPEAT:change_callback(function()
		CONFIG.REPEAT_CYCLE = floor(CMPREPEAT:get_value())
		SaveConfiguration()
	end)

	local CMPWAIT = ui:add_slider("CMP Wait Time - WHOLE NUMBERS ONLY.", 0, 1000, CONFIG.CMP_WAIT)
	CMPWAIT:change_callback(function()
		CONFIG.CMP_WAIT = floor(CMPWAIT:get_value())
		SaveConfiguration()
	end)

	local WaitBetweenDig = ui:add_slider("Wait Between Dig - WHOLE NUMBERS ONLY.", 300, 1000, CONFIG.WAIT_BETWEEN_DIG)
	WaitBetweenDig:change_callback(function()
		CONFIG.WAIT_BETWEEN_DIG = floor(WaitBetweenDig:get_value())
		SaveConfiguration()
	end)

	local automode = ui:add_checkbox("Auto Start Digging", AUTO_MODE)
	automode:change_callback(function()
		AUTO_MODE = automode:get_value()
	end)
end

local function CreateMovementSettingsUI()
	local Movement_Settings = gui.create("Movement Settings", false)
	Movement_Settings:set_pos(475, 100)
	Movement_Settings:set_size(400, 200)

	local AdvancedMovement =
		Movement_Settings:add_checkbox("Enable Advanced Movement", CONFIG.ADVANCED_MOVEMENT_ENABLED)
	AdvancedMovement:change_callback(function()
		CONFIG.ADVANCED_MOVEMENT_ENABLED = AdvancedMovement:get_value()
		SaveConfiguration()
	end)

	local MovementRepeatZ =
		Movement_Settings:add_slider("Movement Repeat FORWARD/BACKWARD", 1, 10, CONFIG.MOVEMENT_REPEAT_Z)
	MovementRepeatZ:change_callback(function()
		CONFIG.MOVEMENT_REPEAT_Z = floor(MovementRepeatZ:get_value())
		SaveConfiguration()
	end)

	local MovementRepeatX = Movement_Settings:add_slider("Movement Repeat LEFT/RIGHT", 1, 10, CONFIG.MOVEMENT_REPEAT_X)
	MovementRepeatX:change_callback(function()
		CONFIG.MOVEMENT_REPEAT_X = floor(MovementRepeatX:get_value())
		SaveConfiguration()
	end)
end

-- Interface and Input functions
local function CreateSettingsUI()
	local MainUI = gui.create("Digging Manager", true)
	MainUI:set_pos(475, 280)
	MainUI:set_size(400, 200)

	local DigSettings = MainUI:add_button(CreatePaddedText("Dig Settings", 97), function()
		UI_OPEN.DigSettings = not UI_OPEN.DigSettings
		if UI_OPEN.DigSettings then
			CreateDigSettingsUI()
		else
			gui.remove("Dig Settings")
		end
	end)

	local MovementSettings = MainUI:add_button(CreatePaddedText("Movement Settings", 88), function()
		UI_OPEN.MovementSettings = not UI_OPEN.MovementSettings
		if UI_OPEN.MovementSettings then
			CreateMovementSettingsUI()
		else
			gui.remove("Movement Settings")
		end
	end)

	local Close = MainUI:add_button(CreatePaddedText("Close", 104), function()
		gui.remove("Digging Manager")
		gui.remove("Dig Settings")
		gui.remove("Movement Settings")
		hook.removekey(0x51, "MAIN_KEY_LISTENER")
	end)
end

local function HandleInput(Keydown)
	if not Keydown then
		return
	end

	if not CanDig() then
		LogNoti("You need a shovel to dig!")
		return
	end

	DIGGING = not DIGGING
	if DIGGING then
		spawn(function()
			if AUTO_MODE then
				CURRENT_MOVEMENT_PATTERN = 1
				CURRENT_MOVEMENT_PATTERN_REPEAT = 0

				while AUTO_MODE and CanDig() and not menu_active() do
					DIGGING = true
					SafeCall(ExecuteMovementPattern, "Movement Manager")
					SafeCall(StartDigging, "Digging Manager")
					wait(300)
				end
			else
				SafeCall(spawn, "Start Digging", StartDigging)
			end
		end)
	end
end

-- Initialisation
local function Initialise()
	LoadConfiguration()
	RestoreGlobals()
	InitialiseMovementPatterns()
	hook.addkey(0x51, "MAIN_KEY_LISTENER", HandleInput)
	CreateSettingsUI()
end

SafeCall(Initialise, "Initialisation")
