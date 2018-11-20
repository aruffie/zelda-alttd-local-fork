local owl_manager = {}

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Function that makes it possible to make the owl appear to launch a dialogue.
function owl_manager:appear(map, step, callback)

    local game = map:get_game()
    local hero = map:get_entity("hero")
    local owl = map:get_entity("owl_"..step)
    local x_hero,y_hero = hero:get_position()
    local x_owl,y_owl, l_owl = owl:get_position()
    local distance_owl = owl:get_distance(hero)
    local owl_shadow = map:create_custom_entity{
      x = x_owl,
      y = y_owl + 32,
      width = 16,
      height = 8,
      direction = 0,
      layer = l_owl ,
      sprite= "npc/owl_shadow"
    }
    map:start_coroutine(function()
      local options = {
        entities_ignore_suspend = {owl, owl_shadow}
      }
      map:set_cinematic_mode(true, options)
      -- Init and launch cinematic mode
      -- Init music
      audio_manager:play_music("08_the_owl")
     -- Init hero
      hero:set_direction(1)
      -- Init owl shadow
      owl_shadow:get_sprite():set_animation("walking")
      owl_shadow:get_sprite():set_direction(1)
     -- Init owl
      owl:set_enabled(true)
      owl:get_sprite():set_animation("walking")
      owl:get_sprite():set_direction(3)
      owl:bring_to_front()
      -- Init movement 1
      local m = sol.movement.create("target")
      m:set_target(x_hero, y_hero - 32)
      m:set_speed(60)
      m:set_ignore_obstacles(true)
      m:set_ignore_suspend(true)
      function m:on_position_changed()
        local x_owl,y_owl = owl:get_position()
        local distance = owl:get_distance(hero)
        local offset = (distance_owl - distance) / distance_owl * 32
        owl_shadow:set_position(x_owl, y_owl + 32 - offset)
      end
      movement(m, owl)
      owl_shadow:set_enabled(false)
      owl:get_sprite():set_animation("talking")
      owl_shadow:get_sprite():set_animation("talking")
      dialog("scripts.meta.map.owl_"..step)
      owl:get_sprite():set_animation("walking")
      owl:get_sprite():set_direction(1)
      owl_shadow:get_sprite():set_animation("walking")
      owl_shadow:get_sprite():set_direction(1)
      -- Init movement 2
      owl_shadow:set_enabled(true)
      local position = map:get_entity("owl_"..step.."_position")
      local m2 = sol.movement.create("target")
      m2:set_target(position)
      m2:set_speed(100)
      m2:set_ignore_obstacles(true)
      m2:set_ignore_suspend(true)
      function m2:on_position_changed()
        local x_owl,y_owl = owl:get_position()
        local distance = owl:get_distance(hero)
        local offset = (distance_owl - distance) / distance_owl * 32
        owl_shadow:set_position(x_owl, y_owl + 32 - offset)
      end
      movement(m2, owl)
      owl:set_enabled(false)
      owl_shadow:set_enabled(false)
      -- Launch callback if exist
      if callback ~= nil then
        callback()
      end
      game:set_value("owl_"..step, true)
      map:set_cinematic_mode(false, options)
    end)

end

-- Function to manage the owls in the dungeons
function owl_manager:init(map)

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