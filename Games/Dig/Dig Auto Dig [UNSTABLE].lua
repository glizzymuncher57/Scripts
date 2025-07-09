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
	AUTO_MODE = false,
	ADVANCED_MOVEMENT_ENABLED = false,
	MOVEMENT_REPEAT_Z = 3,
	MOVEMENT_REPEAT_X = 3,
}

-- State
local DEBUG = true
local DIGGING = false
local CURRENT_MOVEMENT_PATTERN = 1
local CURRENT_MOVEMENT_PATTERN_REPEAT = 0
local LAST_SELL_TIME = 0
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
	CURRENT_MOVEMENT_PATTERN = 1
	CURRENT_MOVEMENT_PATTERN_REPEAT = 0
	LAST_SELL_TIME = 0
	UI_OPEN.MovementSettings = false
	UI_OPEN.DigSettings = false
end

local function CanDig()
	return Player.character
			and Player.character:find_first_child_class("Tool")
			and Player.character:find_first_child_class("Tool").name:lower():find("shovel")
		or Player.character:find_first_child_class("Tool").name == "Beast Slayer"
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

	for Setting, Value in pairs(CONFIG) do
		CONFIG[Setting] = ParseResult[Setting] or Value
	end

	return true
end

-- Sell Functions
local function ReturnSellInventoryPosition()
	local Inventory = PlayerGui:find_first_child("Backpack")
	if not Inventory:isvalid() then
		LogFunc("Inventory UI is not valid or does not exist.")
		return nil_instance
	end

	local SellButton = Inventory:find_first_descendant("SellInventory")
	if not SellButton:isvalid() then
		LogFunc("Sell Inventory button is not valid or does not exist.")
		return nil_instance
	end

	local SellButtonCenter = SellButton.gui_position + (SellButton.gui_size / 2)

	return {
		x = math.floor(SellButtonCenter.x),
		y = math.floor(SellButtonCenter.y),
	}
end

local function SellInventory()
	if not PlayerGui:find_first_child("Backpack") then
		LogFunc("Inventory UI not open or invalid.")
		return false
	end

	input.simulate_press(0x47)
	wait(300)
	local SellPosition = ReturnSellInventoryPosition()
	input.set_mouse_position(vector2(SellPosition.x, SellPosition.y))
	wait(300)
	simulate_mouse_click(MOUSE1)
	wait(300)

	input.simulate_press(0x47)
	LAST_SELL_TIME = get_unixtime()
	wait(300)
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

-- Interface and Input functions

-- UI "Library"
-- UI Manager Implementation
local UIManager = {
	ActiveWindows = {},
	DefaultPadding = 15,
	DefaultButtonWidth = 100,
}

function UIManager.CreatePaddedText(Text, Width)
	Width = Width or UIManager.DefaultButtonWidth
	local Padding = math.max(0, Width - #Text)
	local Left = math.floor(Padding / 2)
	local Right = Padding - Left
	return string.rep(" ", Left) .. Text .. string.rep(" ", Right)
end

function UIManager.CreateWindow(Title, SizeX, SizeY, PosX, PosY)
	if UIManager.ActiveWindows[Title] then
		gui.remove(Title)
	end

	local UI = gui.create(Title, false)
	UI:set_pos(PosX or 100, PosY or 100)
	UI:set_size(SizeX, SizeY)

	UIManager.ActiveWindows[Title] = UI
	return UI
end

function UIManager.CloseWindow(Title)
	if UIManager.ActiveWindows[Title] then
		gui.remove(Title)
		UIManager.ActiveWindows[Title] = nil
	end
end

function UIManager.ToggleWindow(Title, CreateFunc)
	if UIManager.ActiveWindows[Title] then
		UIManager.CloseWindow(Title)
		return false
	else
		CreateFunc()
		return true
	end
end

function UIManager.AddButton(UI, Text, Callback, Width)
	return UI:add_button(UIManager.CreatePaddedText(Text, Width), Callback)
end

function UIManager.AddSlider(UI, Label, Min, Max, Value, IsInt, ConfigKey)
	local Slider = UI:add_slider(Label, Min, Max, Value)

	Slider:change_callback(function()
		local Val = IsInt and math.floor(Slider:get_value()) or Slider:get_value()
		CONFIG[ConfigKey] = Val
		SaveConfiguration()
	end)

	return Slider
end

function UIManager.AddCheckbox(UI, Label, Value, ConfigKey)
	local Checkbox = UI:add_checkbox(Label, Value)

	Checkbox:change_callback(function()
		CONFIG[ConfigKey] = Checkbox:get_value()
		SaveConfiguration()
	end)

	return Checkbox
end

local function CreateDigSettingsUI()
	local UI = UIManager.CreateWindow("Dig Settings", 400, 380)
	UIManager.AddSlider(UI, "Tolerance - Supports Decimals", 0, 150, CONFIG.Tolerance, false, "Tolerance")
	UIManager.AddSlider(UI, "Wait When Clicked", 0, 200, CONFIG.WaitWhenClicked, true, "WaitWhenClicked")
	UIManager.AddSlider(UI, "Wait When Not Clicked", 0, 200, CONFIG.WaitWhenNotClicked, true, "WaitWhenNotClicked")
	UIManager.AddSlider(UI, "Repeat Movement Cycle", 1, 10, CONFIG.REPEAT_CYCLE, true, "REPEAT_CYCLE")
	UIManager.AddSlider(UI, "Movement Cycle Keypress Time", 0, 1000, CONFIG.CMP_WAIT, true, "CMP_WAIT")
	UIManager.AddSlider(UI, "Wait Between Dig", 300, 1000, CONFIG.WAIT_BETWEEN_DIG, true, "WAIT_BETWEEN_DIG")
	UIManager.AddCheckbox(UI, "Auto Start Digging", CONFIG.AUTO_MODE, "AUTO_MODE")
end

local function CreateMovementSettingsUI()
	local UI = UIManager.CreateWindow("Movement Settings", 400, 200, 475, 100)
	UIManager.AddCheckbox(UI, "Enable Advanced Movement", CONFIG.ADVANCED_MOVEMENT_ENABLED, "ADVANCED_MOVEMENT_ENABLED")
	UIManager.AddSlider(
		UI,
		"Movement Repeat FORWARD/BACKWARD",
		1,
		10,
		CONFIG.MOVEMENT_REPEAT_Z,
		true,
		"MOVEMENT_REPEAT_Z"
	)
	UIManager.AddSlider(UI, "Movement Repeat LEFT/RIGHT", 1, 10, CONFIG.MOVEMENT_REPEAT_X, true, "MOVEMENT_REPEAT_X")
end

local function CreateSettingsUI()
	local UI = UIManager.CreateWindow("Digging Manager", 400, 200, 475, 280)

	UIManager.AddButton(UI, "Dig Settings", function()
		UI_OPEN.DigSettings = UIManager.ToggleWindow("Dig Settings", CreateDigSettingsUI)
	end, 97)

	UIManager.AddButton(UI, "Movement Settings", function()
		UI_OPEN.MovementSettings = UIManager.ToggleWindow("Movement Settings", CreateMovementSettingsUI)
	end, 88)

	UIManager.AddButton(UI, "Close", function()
		UIManager.CloseWindow("Digging Manager")
		UIManager.CloseWindow("Dig Settings")
		UIManager.CloseWindow("Movement Settings")
		hook.removekey(0x51, "MAIN_KEY_LISTENER")
	end, 104)
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
			if CONFIG.AUTO_MODE then
				CURRENT_MOVEMENT_PATTERN = 1
				CURRENT_MOVEMENT_PATTERN_REPEAT = 0
				LAST_SELL_TIME = 0

				while CONFIG.AUTO_MODE and CanDig() and not menu_active() do
					DIGGING = true
					SafeCall(ExecuteMovementPattern, "Movement Manager")
					SafeCall(StartDigging, "Digging Manager")

					if (get_unixtime() - LAST_SELL_TIME) >= 15 then
						wait(500)
						SellInventory()
						LAST_SELL_TIME = get_unixtime()
					end
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
