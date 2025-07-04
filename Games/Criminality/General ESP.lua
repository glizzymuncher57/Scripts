local Workspace = game:get_service("Workspace")
local Players = game:get_service("Players")
local Player = Players.local_player
local PlayerGui = Player:find_first_child("PlayerGui")

local BUTTON_SIZE_FORMAT = "                            %s                            "
local FILE_NAME = "CriminalityGENESP.json"

local Map, Filter = Workspace:find_first_child("Map"), Workspace:find_first_child("Filter")
local Folders = {
	BredMakurz = Map and Map:find_first_child("BredMakurz"),
	ATMs = Map and Map:find_first_child("ATMz"),
	SpawnedPiles = Filter and Filter:find_first_child("SpawnedPiles"),
	SpawnedBread = Filter and Filter:find_first_child("SpawnedBread"),
	Shopz = Map and Map:find_first_child("Shopz"),
}
local Parts = {
	ATMs = "MainPart",
	BredMakurz = "MainPart",
	SpawnedPiles = "MeshPart",
	SpawnedBread = "MainPart",
	Shopz = "MainPart",
}

local DATA = {
	OBJECTS = {
		SpawnedPiles = { DisplayName = "Spawned Piles", SinglePart = false },
		SpawnedBread = { DisplayName = "Dropped Cash", SinglePart = true },
		BredMakurz = { DisplayName = "Safes", SinglePart = false },
		ATMs = { DisplayName = "ATMs", SinglePart = false },
		Shopz = { DisplayName = "Dealers", SinglePart = false },
	},
}

local CONFIGURATION = {
	MAIN_SETTINGS = { MaxDistance = 500, Enabled = true, AUTO_PICK = false },
	OBJECT_SETTINGS = {
		SpawnedPiles = { Enabled = true, Color = color(0, 0, 1, 1) },
		SpawnedBread = { Enabled = true, Color = color(1, 1, 0, 1) },
		BredMakurz = { Enabled = true, Color = color(0, 1, 0, 1) },
		ATMs = { Enabled = true, Color = color(1, 0, 0, 1) },
		Shopz = { Enabled = true, Color = color(1, 0.5, 0, 1) },
	},
}

local Picking = false

local GUI_STATE = { GS_OPEN = false, OS_OPEN = false }

local floor, world_to_screen, in_screen, render_add_text = math.floor, world_to_screen, in_screen, render.add_text
local vector2 = vector2

local function GetDistance(pos1, pos2)
	return floor((pos1 - pos2):length())
end

local function ColorToTable(col)
	return { r = col.r, g = col.g, b = col.b, a = col.a }
end

local function TableToColor(tbl)
	return color(tbl.r, tbl.g, tbl.b, tbl.a)
end

local function BoolToString(bool)
	return bool and "1" or "0"
end

local function StringToBool(str)
	return str == "1"
end

local function LoadSettings()
	if not file.exists(FILE_NAME) then
		print("No ESP config file found, using defaults.")
		return false
	end
	local readSuccess, jsonResult = pcall(file.read, FILE_NAME, "binary")
	if not readSuccess then
		print("Failed to read ESP config file:", jsonResult)
		return false
	end
	local parseSuccess, tableResult = pcall(JSON_to_table, jsonResult)
	if not parseSuccess then
		print("Failed to parse ESP config JSON:", tableResult)
		return false
	end
	local main = tableResult.MAIN_SETTINGS
	if main then
		CONFIGURATION.MAIN_SETTINGS.MaxDistance = main.MaxDistance or CONFIGURATION.MAIN_SETTINGS.MaxDistance
		CONFIGURATION.MAIN_SETTINGS.Enabled = main.Enabled ~= nil and StringToBool(main.Enabled)
			or CONFIGURATION.MAIN_SETTINGS.Enabled
		local obj = tableResult.OBJECT_SETTINGS
		if obj then
			for objectName, settings in pairs(CONFIGURATION.OBJECT_SETTINGS) do
				local loaded = obj[objectName]
				if loaded then
					settings.Enabled = loaded.Enabled ~= nil and StringToBool(loaded.Enabled) or settings.Enabled
					settings.Color = loaded.Color and TableToColor(loaded.Color) or settings.Color
				end
			end
		end
	end
	return true
end

local function SaveSettings()
	local configToSave = {
		MAIN_SETTINGS = {
			MaxDistance = CONFIGURATION.MAIN_SETTINGS.MaxDistance,
			Enabled = BoolToString(CONFIGURATION.MAIN_SETTINGS.Enabled),
		},
		OBJECT_SETTINGS = {},
	}
	for objectName, settings in pairs(CONFIGURATION.OBJECT_SETTINGS) do
		configToSave.OBJECT_SETTINGS[objectName] = {
			Enabled = BoolToString(settings.Enabled),
			Color = ColorToTable(settings.Color),
		}
	end
	local success, configJson = pcall(table_to_JSON, configToSave)
	if not success then
		print("Failed to convert settings to JSON:", configJson)
		return
	end
	if file.exists(FILE_NAME) then
		file.overwrite(FILE_NAME, configJson, "binary")
	else
		file.write(FILE_NAME, configJson, "binary")
	end
end

local outline_offsets = {
	vector2(-1, -1),
	vector2(-1, 1),
	vector2(1, -1),
	vector2(1, 1),
}

local function CreateEspText(root, name, world_pos, objColor)
	local dist = GetDistance(root.position, world_pos)
	if dist <= 5 then
		return
	end
	local screen_pos = world_to_screen(world_pos)
	if not screen_pos or not in_screen(screen_pos) then
		return
	end
	local dist_text = ("[%dm]"):format(dist)
	local name_size, dist_size = render.get_text_size(name), render.get_text_size(dist_text)
	local name_pos = vector2(screen_pos.x - name_size.x / 2, screen_pos.y)
	local dist_pos = vector2(screen_pos.x - dist_size.x / 2, screen_pos.y + name_size.y + 3)
	for _, offset in ipairs(outline_offsets) do
		render_add_text(name_pos + offset, name, color(0, 0, 0, 1))
	end
	render_add_text(name_pos, name, objColor)
	for _, offset in ipairs(outline_offsets) do
		render_add_text(dist_pos + offset, dist_text, color(0, 0, 0, 1))
	end
	render_add_text(dist_pos, dist_text, color(1, 1, 1, 1))
end

local function IsPicking()
	return PlayerGui
		and PlayerGui:find_first_child("LockpickGUI")
		and PlayerGui:find_first_child("LockpickGUI"):isvalid()
end

local function DoThePicking()
	if Picking then
		return
	end

	Picking = true
	local Reactivate_When_Finished = MAIN_SETTINGS.CONFIGURATION.Enabled
	MAIN_SETTINGS.CONFIGURATION.Enabled = false

	-- Declare stuff out of loop
	local LockpickGui = PlayerGui:find_first_child("LockpickGUI"):find_first_child("MF"):find_first_child("LP_Frame")
	local Bars = LockpickGui:find_first_child("Frames")
	local Line = LockpickGui:find_first_child("Line")

	local NumberOfBars = 0
	local CurrentBarNum = 1

	for _, v in pairs(Bars:get_children()) do
		if v:isvalid() and v.name:find("B") then
			NumberOfBars = NumberOfBars + 1
		end
	end

	while IsPicking() do
		local BarFrame = Bars:find_first_child("B" .. CurrentBarNum)
		local CurrentBar = BarFrame:find_first_child("Bar"):find_first_child("Selection")

		local CurrentBarPos = CurrentBar.gui_position + (CurrentBar.gui_size / 2)
		local LinePos = Line.gui_position + (Line.gui_size / 2)
		local Distance = math.abs(CurrentBarPos.y - LinePos.y)
		local PosV = BarFrame:find_first_child("Bar"):find_first_child("PosV")

		local Clicked = false
		if Distance <= 15 then
			CurrentBarNum = CurrentBarNum + 1
			input.simulate_mouse_click(MOUSE1)
			Clicked = true
		end

		wait(Clicked and 500 or 10)
	end

	Picking = false
	if Reactivate_When_Finished then
		MAIN_SETTINGS.CONFIGURATION.Enabled = true
	end
end

local function CreateSettingsInterface()
	local Menu = gui.create("Criminality General ESP", false)
	Menu:set_pos(100, 100)
	Menu:set_size(325, 200)

	Menu:add_button(BUTTON_SIZE_FORMAT:format("General Settings"), function()
		if GUI_STATE.GS_OPEN then
			return
		end
		GUI_STATE.GS_OPEN = true
		local GeneralSettingsMenu = gui.create("Criminality General ESP Settings", false)
		GeneralSettingsMenu:set_pos(400, 100)
		GeneralSettingsMenu:set_size(325, 200)
		GeneralSettingsMenu:add_button(BUTTON_SIZE_FORMAT:format("  Toggle ESP  "), function()
			CONFIGURATION.MAIN_SETTINGS.Enabled = not CONFIGURATION.MAIN_SETTINGS.Enabled
			SaveSettings()
		end)
		GeneralSettingsMenu:add_button(BUTTON_SIZE_FORMAT:format("  Close  "), function()
			gui.remove("Criminality General ESP Settings")
			GUI_STATE.GS_OPEN = false
		end)
		local AutoLockpickCheckbox =
			GeneralSettingsMenu:add_checkbox("Auto Lockpick Enabled", CONFIGURATION.MAIN_SETTINGS.AUTO_PICK)
		AutoLockpickCheckbox:change_callback(function()
			CONFIGURATION.MAIN_SETTINGS.AUTO_PICK = AutoLockpickCheckbox:get_value()
		end)
		local MaxDistanceSlider =
			GeneralSettingsMenu:add_slider("Max Distance", 100, 9999, CONFIGURATION.MAIN_SETTINGS.MaxDistance)
		MaxDistanceSlider:change_callback(function()
			CONFIGURATION.MAIN_SETTINGS.MaxDistance = MaxDistanceSlider:get_value()
			SaveSettings()
		end)
	end)

	Menu:add_button(BUTTON_SIZE_FORMAT:format("Object Settings"), function()
		if GUI_STATE.OS_OPEN then
			return
		end
		GUI_STATE.OS_OPEN = true
		local ObjectSettingsMenu = gui.create("Criminality General ESP Object Settings", false)
		ObjectSettingsMenu:set_pos(100, 275)
		ObjectSettingsMenu:set_size(350, 420)
		for objectFolderName, objectSettings in pairs(CONFIGURATION.OBJECT_SETTINGS) do
			local objectData = DATA.OBJECTS[objectFolderName]
			local ToggleObjectESP = ObjectSettingsMenu:add_checkbox(
				"Toggle " .. (objectData.DisplayName or objectFolderName),
				objectSettings.Enabled
			)
			ToggleObjectESP:change_callback(function()
				objectSettings.Enabled = ToggleObjectESP:get_value()
				SaveSettings()
			end)
			local ColorMenu = ObjectSettingsMenu:add_color(
				(objectData.DisplayName or objectFolderName) .. " Color",
				objectSettings.Color
			)
			ColorMenu:change_callback(function()
				objectSettings.Color = ColorMenu:get_color()
				SaveSettings()
			end)
		end
		ObjectSettingsMenu:add_button(BUTTON_SIZE_FORMAT:format("  Close  "), function()
			gui.remove("Criminality General ESP Object Settings")
			GUI_STATE.OS_OPEN = false
		end)
	end)

	Menu:add_button(BUTTON_SIZE_FORMAT:format("  Remove ESP  "), function()
		hook.remove("render", "Crim_Gen_ESP")
		gui.remove("Criminality General ESP")
		gui.remove("Criminality General ESP Settings")
		gui.remove("Criminality General ESP Object Settings")
		GUI_STATE.GS_OPEN, GUI_STATE.OS_OPEN = false, false
	end)
end

local function HandleRenderHook()
	local Root = Player.character and Player.character:find_first_child("HumanoidRootPart")
	if not (Root and Root:isvalid() and CONFIGURATION.MAIN_SETTINGS.Enabled) then
		return
	end
	for objectFolderName, objectSettings in pairs(CONFIGURATION.OBJECT_SETTINGS) do
		if not objectSettings.Enabled then
			goto continue
		end
		local MapObject = Folders[objectFolderName]
		if not (MapObject and MapObject:isvalid()) then
			goto continue
		end
		local objectData, partName = DATA.OBJECTS[objectFolderName], Parts[objectFolderName]
		for _, Object in pairs(MapObject:get_children()) do
			if Object and Object:isvalid() then
				local IsSinglePart = objectData.SinglePart
				local ObjectPart = IsSinglePart and Object
					or Object:find_first_child(partName)
					or Object:find_first_child_class("BasePart")
				if not (ObjectPart and ObjectPart:isvalid()) then
					goto inner_continue
				end
				local Distance = GetDistance(ObjectPart.position, Root.position)
				if Distance > CONFIGURATION.MAIN_SETTINGS.MaxDistance then
					goto inner_continue
				end

				if objectFolderName == "BredMakurz" then
					local Values = Object:find_first_child("Values")
					if Values and Values:isvalid() then
						local Broken = Values:find_first_child("Broken")
						if Broken and Broken:isvalid() and Broken:get_value_bool() then
							goto inner_continue
						end
					end
					local safeName = Object.name:match("^(%w+)") or Object.name
					local displayName = ({
						Register = "Cash Register",
						SmallSafe = "Small Safe",
						MediumSafe = "Medium Safe",
					})[safeName] or safeName
					CreateEspText(Root, displayName, ObjectPart.position, objectSettings.Color)
				elseif objectFolderName == "Shopz" then
					local Type = Object:find_first_child("Type")
					if Type and Type:isvalid() then
						local TypeString = Type:get_value_string()
						local DisplayName = ({
							IllegalStore = "Illegal Dealer",
							LegalStore = "Armory Dealer",
						})[TypeString] or TypeString
						CreateEspText(Root, DisplayName, ObjectPart.position, objectSettings.Color)
					end
				else
					CreateEspText(
						Root,
						objectData.DisplayName or objectFolderName,
						ObjectPart.position,
						objectSettings.Color
					)
				end
			end
			::inner_continue::
		end
		::continue::
	end
end

local function Initialise()
	if not LoadSettings() then
		print("Failed to load settings, using defaults.")
	end
	CreateSettingsInterface()
	hook.add("render", "Crim_Gen_ESP", function()
		local s, e = pcall(HandleRenderHook)
		if not s then
			print("Error occurred while rendering ESP:", e)
		end

		local s, e = pcall(function()
			if not IsPicking() then
				return
			end

			if CONFIGURATION.MAIN_SETTINGS.AUTO_PICK then
				if not Picking then
					DoThePicking()
				end
			else
				Picking = false
			end
		end)

		if not s then
			print("Error occurred while handling picking:", e)
		end
	end)
end

Initialise()
