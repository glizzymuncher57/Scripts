--[[
        ESP For Dealers and Points of Interest
        Binds:
            LCtrl + LShift + 1 - Toggle ESP
            LCtrl + LShift + 2 - Toggle Dealer ESP
            LCtrl + LShift + 3 - Toggle POI ESP
    ]]

local Players = game:get_service("Players")
local Player = Players.local_player

local EspActive = true
local PoiEsp = false
local DealerEsp = false

local DealerColor = color(1, 0, 0, 1)
local PoiColor = color(0, 1, 0, 1)

local VK_LSHIFT = 0xA0
local VK_LCTRL = 0xA2

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

local Hotkeys = {
	[0x31] = {
		name = "ESP",
		toggle = function()
			EspActive = not EspActive
			return EspActive
		end,
	},
	[0x32] = {
		name = "Dealer ESP",
		toggle = function()
			DealerEsp = not DealerEsp
			return DealerEsp
		end,
	},
	[0x33] = {
		name = "POI ESP",
		toggle = function()
			PoiEsp = not PoiEsp
			return PoiEsp
		end,
	},
}

local floor = math.floor
local world_to_screen = world_to_screen
local in_screen = in_screen
local render_add_text = render.add_text
local key_down = input.key_down

local function GetDistance(pos1, pos2)
	return floor((pos1 - pos2):length())
end

local function CreateEspText(root, name, world_pos, is_dealer)
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
	render_add_text(name_pos, name, is_dealer and DealerColor or PoiColor)

	for _, offset in ipairs(outline_offsets) do
		render_add_text(dist_pos + offset, dist_text, color(0, 0, 0, 1))
	end
	render_add_text(dist_pos, dist_text, color(1, 1, 1, 1))
end

local function HandleRendering(data, root, active, is_dealer)
	if not active or not root then
		return
	end

	for name, pos in pairs(data) do
		if pos then
			CreateEspText(root, name, pos, is_dealer)
		end
	end
end

local function RegisterInputs()
	for key, hk in pairs(Hotkeys) do
		hook.addkey(key, tostring(key), function()
			if not key_down(VK_LCTRL) or not key_down(VK_LSHIFT) or not key_down(key) then
				return
			end

			local new_state = hk.toggle()
			log.notification("Toggled " .. hk.name .. " to " .. tostring(new_state), "Info")
		end)
	end
end

local function Init()
	RegisterInputs()

	hook.add("render", "esp_render", function()
		if not EspActive then
			return
		end

		local char = Player.character
		local root = char and char:find_first_child("HumanoidRootPart")
		if not root then
			return
		end

		local s, e = pcall(function()
			HandleRendering(PositionData.Dealers, root, DealerEsp, true)
			HandleRendering(PositionData.PointsOfInterest, root, PoiEsp, false)
		end)

		if not s then
			log.add("Error in ESP rendering: " .. e, color(1, 0, 0, 1))
		end
	end)
end

Init()
