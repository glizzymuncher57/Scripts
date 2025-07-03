local camera = game:get_service("Workspace"):find_first_child_class("Camera")
local input = input
local hook = hook

local default_fov = camera.fov
local zoom_fov = 30
local current_fov = default_fov
local transition_speed = 10
local is_zooming = false

log.notification("Loaded. Press Z to zoom.", "Info")

hook.add("render", "zoom_fov", function()
    if input.key_down(0x5A) then
        if not is_zooming then
            default_fov = camera.fov
            is_zooming = true
        end
        local target_fov = zoom_fov
        current_fov = current_fov + (target_fov - current_fov) * transition_speed * (1/60)
        camera:set_fov(current_fov)
    else
        if is_zooming then
            local target_fov = default_fov
            current_fov = current_fov + (target_fov - current_fov) * transition_speed * (1/60)
            camera:set_fov(current_fov)
            if math.abs(current_fov - default_fov) < 0.1 then
                is_zooming = false
                camera:set_fov(default_fov)
            end
        end
    end
end)
