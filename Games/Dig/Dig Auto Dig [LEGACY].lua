local Player = game:get_service("Players").local_player
local PlayerGui = Player and Player:find_first_child("PlayerGui")

local DEBUG = true
local DIGGING = false

local CONFIG = {
    Tolerance = 25, -- Distance tolerance for clicking. 
    WaitWhenClicked = 65, -- Wait time when clicked (miliseconds)
    WaitWhenNotClicked = 10 -- Wait time when not clicked (miliseconds)
}

local function logFunc(...)
    if DEBUG then
        log.notification(..., "Info")
    end
end

local function ReturnFirstDescendant(Parent, Name)
    for _, Descendant in pairs(Parent:get_descendants()) do
        if Descendant.name == Name then
            return Descendant
        end
    end

    return nil_instance
end

local function StartTheDiggering()
    -- probably heavily unoptimised to check for the ui every loop but it shouldn't make that much of a diff.
    while DIGGING do
        local DigUI = PlayerGui:find_first_child("Dig")
        if not DigUI:isvalid() then 
            logFunc("Dig UI became invalid") 
            DIGGING = false
            return 
        end

        local Area_Strong = ReturnFirstDescendant(DigUI, "Area_Strong")
        if not Area_Strong:isvalid() then 
            logFunc("Area_Strong became invalid") 
            DIGGING = false
            return 
        end

        local PlayerBar = ReturnFirstDescendant(DigUI, "PlayerBar")
        if not PlayerBar:isvalid() then 
            logFunc("PlayerBar became invalid") 
            DIGGING = false
            return 
        end
        
        local success, err = pcall(function()
            local PlayerBarPos = PlayerBar.gui_position + (PlayerBar.gui_size / 2)
            local Area_StrongPos = Area_Strong.gui_position + (Area_Strong.gui_size / 2)
            local Distance = math.abs(PlayerBarPos.x - Area_StrongPos.x)
            
            local Clicked = false
            if Distance <= CONFIG.Tolerance then
                input.simulate_mouse_click(MOUSE1)
                Clicked = true
            end

            wait(Clicked and CONFIG.WaitWhenClicked or CONFIG.WaitWhenNotClicked)
        end)

        if not success then
            logFunc("Error in dig loop: " .. tostring(err))
            DIGGING = false
            return
        end
    end
end

hook.addkey(0x51, "womp", function(KD)
    DIGGING = KD
    logFunc("Digging toggled: " .. tostring(DIGGING))

    if DIGGING then
        spawn(StartTheDiggering)
    end
end)
