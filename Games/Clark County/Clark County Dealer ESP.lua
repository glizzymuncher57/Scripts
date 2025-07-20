local Players = game:get_service("Players")
local Player = Players.local_player

local DealerColor = color(1, 0, 0, 1)
local PoiColor = color(0, 1, 0, 1)

local PositionData = {
	Dealers = {
		["Lockpick and Thermite"] = vector3(817, 197, 2814),
		["Delino R21"] = vector3(221, 233, 3287),
		["Delino R21A"] = vector3(-2192, 2095, -2142),
		["Hawthorn 500"] = vector3(-2401, 211, -113),
		["AK Dealer"] = vector3(19, 209, 2835),
		["Cobray MP18"] = vector3(-114, 190, -2122),
		["Benneti 17"] = vector3(-1087, 255, -1674),
		["Mustang M45"] = vector3(815, 209, 102),
		["Delino Special"] = vector3(2139, 204, -770),
	},
	PointsOfInterest = {
		["Car Bomb Crafter"] = vector3(-152, 194, -1619),
		["Money Launderer"] = vector3(-1984, 209, -918),
	},
}

local CONFIG = {
	EspActive = false,
	DealerEsp = false,
	PoiEsp = false,
}

local floor = math.floor
local world_to_screen = world_to_screen
local in_screen = in_screen
local render_add_text = render.add_text
local key_down = input.key_down

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
	end)

	return Slider
end

function UIManager.AddCheckbox(UI, Label, Value, ConfigKey)
	local Checkbox = UI:add_checkbox(Label, Value)

	Checkbox:change_callback(function()
		CONFIG[ConfigKey] = Checkbox:get_value()
	end)

	return Checkbox
end

local function GetDistance(pos1, pos2)
	return floor((pos1 - pos2):length())
end

local function CreateEspText(root, name, world_pos, colour)
	local dist = GetDistance(root.position, world_pos)
	if dist <= 5 then
		return
	end
	local screen_pos = world_to_screen(world_pos)
	if not screen_pos or not in_screen(screen_pos) then
		return
	end

	local dist_text = "[" .. dist .. "m]"

	local name_size = render.get_text_size(name)
	local dist_size = render.get_text_size(dist_text)

	local name_pos = vector2(screen_pos.x - (name_size.x / 2), screen_pos.y)
	local dist_pos = vector2(screen_pos.x - (dist_size.x / 2), screen_pos.y + name_size.y + 3)
	local outline_offsets = {
		vector2(-1, -1),
		vector2(-1, 1),
		vector2(1, -1),
		vector2(1, 1),
	}

	for _, offset in ipairs(outline_offsets) do
		render_add_text(name_pos + offset, name, color(0, 0, 0, 1))
	end
	render_add_text(name_pos, name, colour)

	for _, offset in ipairs(outline_offsets) do
		render_add_text(dist_pos + offset, dist_text, color(0, 0, 0, 1))
	end
	render_add_text(dist_pos, dist_text, color(1, 1, 1, 1))
end

local function HandleRendering(data, root, active, colour)
	if not active or not root then
		return
	end

	for name, pos in pairs(data) do
		if pos then
			CreateEspText(root, name, pos, colour)
		end
	end
end

local function Init()
	local EspWindow = UIManager.CreateWindow("ESP Settings", 300, 185)
	UIManager.AddCheckbox(EspWindow, "Enable ESP", CONFIG.EspActive, "EspActive")
	UIManager.AddCheckbox(EspWindow, "Enable Dealer ESP", CONFIG.DealerEsp, "DealerEsp")
	UIManager.AddCheckbox(EspWindow, "Enable POI ESP", CONFIG.PoiEsp, "PoiEsp")
	UIManager.AddButton(EspWindow, "Close", function()
		hook.removeall()
		UIManager.CloseWindow("ESP Settings")
		CONFIG.EspActive = false
		CONFIG.DealerEsp = false
		CONFIG.PoiEsp = false
	end, 69)

	hook.add("render", "esp_render", function()
		if not CONFIG.EspActive then
			return
		end

		local char = Player.character
		if not char:isvalid() then
			return
		end

		local root = char:find_first_child("HumanoidRootPart")
		if not root then
			return
		end

		local s, e = pcall(function()
			HandleRendering(PositionData.Dealers, root, CONFIG.DealerEsp, DealerColor)
			HandleRendering(PositionData.PointsOfInterest, root, CONFIG.PoiEsp, PoiColor)
		end)

		if not s then
			log.add("Error in ESP rendering: " .. e, color(1, 0, 0, 1))
		end
	end)
end

Init()
