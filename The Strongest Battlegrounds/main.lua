vector3(152, 440, 34), - Center of map
vector3(-25047, 0, -25047), - ball room
vector3(-67, 29, 20339), - fist room
vector3(438, 439, -376) - random hole

local players = game:get_service("Players")
local localplayer = players.local_player

local VK_SHIFT = 0x10
local VK_LSHIFT  = 0xA0
local VK_LCTRL = 0xA0

local POSITIONS = {
	[0x31] = {
		Name = "Center of Map",
		Position = vector3(152, 440, 34),
	},

	[0x32] = {
		Name = "Ball Room",
		Position = vector3(-25047, 0, -25047),
	},

	[0x33] = {
		Name = "Fist Room",
		Position = vector3(-67, 29, 20339),
	},

	[0x34] = {
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
    log.notification("Press Shift + 1-4 to..", "Info")

    for Keycode, Info in pairs(POSITION_TABLE) do
        hook.addkey(Keycode, tostring(Keycode), function()
			local IsLCtrlDown = input.key_down(VK_LCTRL)
            local IsShiftDown = input.key_down(VK_SHIFT) or input.key_down(VK_LSHIFT)

			if not IsShiftDown or not IsLCtrlDown then
				return
			end

            local IsKeyDown = input.key_down(Keycode)
            if not IsKeyDown then return end

            TeleportToPosition(Info.Position)
			log.notification("Teleported to " .. Info.Name, "Info")
        end)
    end
end
