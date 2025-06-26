local Workspace = game:get_service("Workspace")
local World = Workspace:find_first_child("World")
local Map = World and World:find_first_child("Map")

local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

local DEBUG = true
local DIGGING = false
local USE_COROUTINE = true
local SPECIAL_SPOT_ESP = false
local SPECIAL_SPOT_PREFIX = "SpecialSpot"
local SPECIAL_SPOT_COLOUR = color(1, 1, 1, 1)


local abs = math.abs
local floor = math.floor
local world_to_screen = world_to_screen
local in_screen = in_screen
local render_add_text = render.add_text

local CONFIG = {
	Tolerance = 27, -- Distance tolerance for clicking.
	WaitWhenClicked = 50, -- Wait time when clicked (miliseconds)
	WaitWhenNotClicked = 0, -- Wait time when not clicked (miliseconds)
}

local function LogFunc(...)
	if DEBUG then
		log.add(..., color(1, 0, 0, 1))
	end
end

local function GetDistance(pos1, pos2)
	return floor((pos1 - pos2):length())
end

local function CreateEspText(root, name, world_pos)
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
	render_add_text(name_pos, name, SPECIAL_SPOT_COLOUR)

	for _, offset in ipairs(outline_offsets) do
		render_add_text(dist_pos + offset, dist_text, color(0, 0, 0, 1))
	end
	render_add_text(dist_pos, dist_text, color(1, 1, 1, 1))
end

local function ReturnFirstDescendant(Parent, Name)
	for _, Descendant in pairs(Parent:get_descendants()) do
		if Descendant.name == Name then
			return Descendant
		end
	end

	return nil_instance
end

local function GetColorForSpot(SpotName) end

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

local ui = gui.create("Dig Settings", false)
ui:set_pos(100, 100)
ui:set_size(400, 400)

local slider = ui:add_slider("slider1", "Tolerance - Supports Decimals", 0, 150, CONFIG.Tolerance)
slider:change_callback(function()
	CONFIG.Tolerance = slider:get_value()
end)

local slider2 = ui:add_slider("slider2", "Wait When Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenClicked)
slider2:change_callback(function()
	CONFIG.WaitWhenClicked = floor(slider2:get_value())
end)

local slider3 =
	ui:add_slider("slider3", "Wait When Not Clicked - Doesn't Support Decimals", 0, 200, CONFIG.WaitWhenNotClicked)
slider3:change_callback(function()
	CONFIG.WaitWhenNotClicked = floor(slider3:get_value())
end)

local checkbox1 = ui:add_checkbox("checkbox1", "Use Coroutine", USE_COROUTINE)
checkbox1:change_callback(function()
	USE_COROUTINE = checkbox1:get_value()
end)

local checkbox2 = ui:add_checkbox("checkbox2", "Special Spot ESP", SPECIAL_SPOT_ESP)
checkbox2:change_callback(function()
	SPECIAL_SPOT_ESP = checkbox2:get_value()
end)

local function Initialise()
	spawn(function()
		hook.add("render", "DigESP", function()
			if not SPECIAL_SPOT_ESP then
				return
			end

			for _, PotentialSpot in pairs(Map:get_children()) do
				if PotentialSpot.name:sub(1, #SPECIAL_SPOT_PREFIX) == SPECIAL_SPOT_PREFIX then
					local Part = PotentialSpot:find_first_child("PositionPart")
					if Part:isvalid() then
						CreateEspText(
							Player.character:find_first_child("HumanoidRootPart"),
							PotentialSpot.name,
							Part.position
						)
					end
				end
			end
		end)

		hook.addkey(0x51, "womp", function(KD)
			DIGGING = KD

			if DIGGING then
				if USE_COROUTINE then
					coroutine.resume(coroutine.create(StartTheDiggering))
				else
					spawn(StartTheDiggering)
				end
			end
		end)
	end)
end

local S,E = pcall(Initialise)
if not S then
    LogFunc(E)
end
