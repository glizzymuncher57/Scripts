local entities = game:get_service("Workspace"):find_first_child("Zombies")
local hook = hook

hook.add("init_custom_entity", "asdasdasd", function()
    for _, e in pairs(entities:get_children()) do
        if e:isvalid() then
            add_entity(
                e.name,
                e:find_first_child("Head") or e:find_first_child_class("Part"),
                e:find_first_child("Humanoid"),
                true,
                vector3(1, 0, 1),
                vector3(1, 1, 1)
            )
        end
    end
end)
