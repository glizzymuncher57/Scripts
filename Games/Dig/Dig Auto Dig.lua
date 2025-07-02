local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

local DEBUG = true
local DIGGING = false
local FILE_NAME = "DigConfig.json"

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
local file = file

-- Util based functions
local function LogFunc(...)
	if DEBUG then
		log.add("[DIG]: " .. tostring(...), color(1, 0, 0, 1))
	end
end

local function LogNoti(...)
	log.notification("[DIG]: " .. tostring(...), "Info")
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

--// Config related functions
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

	local ReadSuccess, JsonResult = pcall(file.read, FILE_NAME, "binary")
	if not ReadSuccess then
		LogFunc("Failed to read configuration file: " .. JsonResult)
		return false
	end

	local ParseSuccess, TableResult = pcall(JSON_to_table, JsonResult)
	if not ParseSuccess then
		LogFunc("Failed to parse configuration JSON: " .. TableResult)
		return false
	end

	-- looks fucking awful but it is what it is.
	CONFIG = {
		Tolerance = TableResult.Tolerance or CONFIG.Tolerance,
		WaitWhenClicked = TableResult.WaitWhenClicked or CONFIG.WaitWhenClicked,
		WaitWhenNotClicked = TableResult.WaitWhenNotClicked or CONFIG.WaitWhenNotClicked,
	}

	return true
end

-- Main Digging Function
local function StartTheDiggering()
	-- probably heavily unoptimised to check for the ui every loop but it shouldn't make that much of a diff.
	while DIGGING do
		local DigUI = PlayerGui:find_first_child("Dig")
		local Area_Strong = DigUI:find_first_descendant("Area_Strong")
		local PlayerBar = DigUI:find_first_descendant("PlayerBar")

		if not CheckElements({ DigUI, Area_Strong, PlayerBar }) then
			LogFunc("One or more required UI elements became invalid.")
			DIGGING = false
			return
		end

		local success, err = pcall(function()
			local PlayerBarPos = PlayerBar.gui_position + (PlayerBar.gui_size / 2)
			local Area_StrongPos = Area_Strong.gui_position + (Area_Strong.gui_size / 2)
			local Distance = abs(PlayerBarPos.x - Area_StrongPos.x)

			local Clicked = false
			if Distance <= CONFIG.Tolerance then
				simulate_mouse_click(MOUSE1)
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
	local function CreateUI()
		if file.exists(FILE_NAME) then
			LogNoti(LoadConfiguration() and "Configuration loaded!." or "Failed to load configuration!")
		end

		local ui = gui.create("Dig Settings", false)
		ui:set_pos(100, 100)
		ui:set_size(400, 200)

		local slider = ui:add_slider("slider1", "Tolerance - Supports Decimals", 0, 150, CONFIG.Tolerance)
		slider:change_callback(function()
			CONFIG.Tolerance = slider:get_value()
			SaveConfiguration()
		end)

		-- hello stylua format this one as well please bro
		local slider2 =
			ui:add_slider("slider2", "Wait When Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenClicked)
		slider2:change_callback(function()
			CONFIG.WaitWhenClicked = floor(slider2:get_value())
			SaveConfiguration()
		end)

		-- stylua is such a weird formatter bruh
		local slider3 = ui:add_slider(
			"slider3",
			"Wait When Not Clicked - Doesn't Support Decimals",
			0,
			200,
			CONFIG.WaitWhenNotClicked
		)
		slider3:change_callback(function()
			CONFIG.WaitWhenNotClicked = floor(slider3:get_value())
			SaveConfiguration()
		end)
	end

	local function InputManager(Keydown)
		DIGGING = Keydown

		if DIGGING then
			spawn(function()
				StartTheDiggering()
			end)
		end
	end

	CreateUI()
	hook.addkey(0x51, "MAIN_KEY_LISTENER", InputManager)
end

local S, E = pcall(Initialise)
if not S then
	LogFunc("Error during initialisation: " .. tostring(E))
end
