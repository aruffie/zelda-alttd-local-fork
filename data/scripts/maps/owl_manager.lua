local owl_manager = {}

-- Function that makes it possible to make the owl appear to launch a dialogue.
function owl_manager:appear(map, step, callback)

    local game = map:get_game()
    local hero = map:get_entity("hero")
    local owl = map:get_entity("owl_"..step)
    local x_hero,y_hero = hero:get_position()
    map:start_coroutine(function()
      local options = {
        entities_ignore_suspend = {owl}
      }
      map:set_cinematic_mode(true, options)
      -- Init and launch cinematic mode
      -- Init music
      sol.audio.play_music("scripts/meta/map/the_wise_owl")
     -- Init hero
      hero:set_direction(1)
     -- Init owl
      owl:set_enabled(true)
      owl:get_sprite():set_animation("walking")
      owl:get_sprite():set_direction(3)
      -- Init movement 1
      local m = sol.movement.create("target")
      m:set_target(x_hero, y_hero - 32)
      m:set_speed(60)
      m:set_ignore_obstacles(true)
      m:set_ignore_suspend(true)
      movement(m, owl)
      owl:get_sprite():set_animation("talking")
      dialog("scripts.meta.map.owl_"..step)
      owl:get_sprite():set_animation("walking")
      owl:get_sprite():set_direction(1)
      -- Init movement 2
      local position = map:get_entity("owl_"..step.."_position")
      local m2 = sol.movement.create("target")
      m2:set_target(position)
      m2:set_speed(100)
      m2:set_ignore_obstacles(true)
      m2:set_ignore_suspend(true)
      movement(m2, owl)
      owl:set_enabled(false)
      -- Launch callback if exist
      if callback ~= nil then
        callback()
      end
      game:set_value("owl_"..step, true)
      map:set_cinematic_mode(false, options)
    end)

end

-- Function to manage the owls in the dungeons
function owl_manager:manage_map(map)

  local game = map:get_game()
  for beak in map:get_entities("owl") do
    function beak:on_interaction()
        local game = map:get_game()
        if game:has_dungeon_beak_of_stone() then
          beak:get_sprite():set_animation("full")
          game:start_dialog("maps.dungeons." .. game:get_dungeon_index() .. "." .. beak:get_name(), function()
            beak:get_sprite():set_animation("normal")
         end)
        else
          game:start_dialog("maps.dungeons.owl")
        end

      end
  end

end


return owl_manager