local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

local DEBUG = true
local DIGGING = false
local AUTO_MODE = false
local FILE_NAME = "DigConfig.json"

local cmP = 1
local activeCmp = false

local cmPs = {
	[1] = function()
		wait(800)
		input.simulate_press_down(0x57)
		wait(500)
		input.simulate_press_up(0x57)

		return true
	end,
	[2] = function()
		wait(800)
		input.simulate_press_down(0x44)
		wait(500)
		input.simulate_press_up(0x44)

		return true
	end,
	[3] = function()
		wait(800)
		input.simulate_press_down(0x53)
		wait(500)
		input.simulate_press_up(0x53)

		return true
	end,
	[4] = function()
		wait(800)
		input.simulate_press_down(0x41)
		wait(500)
		input.simulate_press_up(0x41)

		return true
	end,
}

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

local function safeSpawn(fn)
	local success, err = pcall(fn)
	if not success then
		log.add("Runtime error: " .. tostring(err), color(255, 0, 0))
	end
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

local function IsDigging()
	return PlayerGui and PlayerGui:find_first_child("Dig") and PlayerGui:find_first_child("Dig"):isvalid()
end

local function initCMP()
	if cmPs[cmP] then
		local cmpmove = cmPs[cmP]()
		if cmpmove then
			activeCmp = false
		end
	end

	if cmP < 4 then
		cmP = cmP + 1
	else
		cmP = 1
	end

	simulate_mouse_click(MOUSE1)
	wait(300)

	if not IsDigging() then
		initCMP()
		return
	end

	DIGGING = true
	return
end

-- Main Digging Function
local function StartTheDiggering()
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

	log.notification("Digging stopped.", "Info")
	DIGGING = false
end

local function Initialise()
	local function CreateUI()
		if file.exists(FILE_NAME) then
			LogNoti(LoadConfiguration() and "Configuration loaded!." or "Failed to load configuration!")
		end

		local ui = gui.create("Dig Settings", false)
		ui:set_pos(100, 100)
		ui:set_size(400, 300)

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

		local slider3 =
			ui:add_slider("Wait When Not Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenNotClicked)
		slider3:change_callback(function()
			CONFIG.WaitWhenNotClicked = floor(slider3:get_value())
			SaveConfiguration()
		end)

		local automode = ui:add_checkbox("Auto Start Digging", AUTO_MODE)
		automode:change_callback(function()
			AUTO_MODE = automode:get_value()
		end)

		local Close = ui:add_button("Close", function()
			gui.remove("Dig Settings")
			hook.removeall()

			DIGGING = false
			AUTO_MODE = false
		end)
	end

	local function InputManager(Keydown)
		if not Keydown then
			return
		end

		DIGGING = not DIGGING

		log.notification(tostring(DIGGING), "Info")
		if DIGGING then
			spawn(function()
				if AUTO_MODE then
					while AUTO_MODE do
						log.notification("Digging in progress...", "Info")

						initCMP()
						log.notification("Digging started!", "Info")
						StartTheDiggering()
						log.notification("Waiting for next cycle...", "Info")
						wait(300)
					end
				else
					spawn(StartTheDiggering)
				end
			end)
		end
	end

	hook.addkey(0x51, "MAIN_KEY_LISTENER", InputManager)
	CreateUI()
end

local S, E = pcall(Initialise)
if not S then
	LogFunc("Error during initialisation: " .. tostring(E))
end
