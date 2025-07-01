--// Services
local workspace   = game:get_service("Workspace")
local players     = game:get_service("Players")

--// Variables
local localplayer = players.local_player

--// Constants
local VK_SHIFT   = 0x10 -- Shift
local VK_LSHIFT  = 0xA0 -- LShift
local POSITION_TABLE = {
    [0x31] = {
        position  = vector3(83, 3, -13),
        name      = "Seeds/Selling",
        BIND_NAME = "1"
    },
    [0x32] = {
        position  = vector3(-82, 3, -1),
        name      = "Bee Event",
        BIND_NAME = "2"
    },
    [0x33] = {
        position  = vector3(-278, 3, -15),
        name      = "Gear/Pet Shop",
        BIND_NAME = "3"
    },
    [0x34] = {
        position  = vector3(35, 3, 73),
        name      = "Farm 1",
        BIND_NAME = "4"
    },
    [0x35] = {
        position  = vector3(35, 3, -118),
        name      = "Farm 2",
        BIND_NAME = "5"
    },
    [0x36] = {
        position  = vector3(-100, 3, 73),
        name      = "Farm 3",
        BIND_NAME = "6"
    },
    [0x37] = {
        position  = vector3(-100, 3, -118),
        name      = "Farm 4",
        BIND_NAME = "7"
    },
    [0x38] = {
        position  = vector3(-235, 3, 73),
        name      = "Farm 5",
        BIND_NAME = "8"
    },
    [0x39] = {
        position  = vector3(-235, 3, -118),
        name      = "Farm 6",
        BIND_NAME = "9"
    },
}

-- get position by index
local function GetPosition(Index)
    return POSITION_TABLE[Index] or vector3(-82, 3, -1)
end

-- teleport player to position
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
    log.notification("Press Shift + 1-9 to..", "Info")

    for Keycode, Position in pairs(POSITION_TABLE) do
        hook.addkey(Keycode, tostring(Keycode), function()
            local IsShiftDown = input.key_down(VK_SHIFT) or input.key_down(VK_LSHIFT)
            if not IsShiftDown then return end

            local IsKeyDown = input.key_down(Keycode)
            if not IsKeyDown then return end

            TeleportToPosition(Position.position)
        end)
    end
end

Init()
