local players = game:get_service("Players")
local localplayer = players.local_player

local VK_LCTRL = 0xA2

local POSITIONS = {
	[0x5A] = {
		Name = "Center of Map",
		Position = vector3(152, 440, 34),
	},

	[0x58] = {
		Name = "Ball Room",
		Position = vector3(1064, 146, 23020),
	},

	[0x43] = {
		Name = "Fist Room",
		Position = vector3(-67, 29, 20339),
	},

	[0x56] = {
		Name = "Random Hole",
		Position = vector3(438, 439, -376),
	},
}

local function GetPosition(Index)
	return POSITION_TABLE[Index] or vector3(152, 440, 34)
end

local function TeleportToPosition(vector3position)
	if localplayer and localplayer.character then
		local humanoidrootpart = localplayer.character:find_first_child("HumanoidRootPart")
		if not humanoidrootpart then
			return
		end

		humanoidrootpart:set_position(vector3position)
	end
end

local function Init()
	log.notification("teleport to teleport to an area.", "Info")
	log.notification("Press LCTRL + Z, X, C, V.", "Info")

	for Keycode, Info in pairs(POSITIONS) do
		hook.addkey(Keycode, tostring(Keycode), function(keydown)
			local IsLCtrlDown = input.key_down(VK_LCTRL)
			if not IsLCtrlDown then
				return
			end

			if not keydown then
				return
			end

			TeleportToPosition(Info.Position)
			log.notification("Teleported to " .. Info.Name, "Info")
		end)
	end
end

Init()
