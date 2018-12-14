-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local animation_launch = false
local sprite = entity:get_sprite()
local wallturn_teletransporter = map:get_entity("wallturn_teletransporter")

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  entity:set_traversable_by(false)
  entity:add_collision_test("touching", function(wall, hero)
    if animation_launch == false and hero:get_type() == "hero" then
      animation_launch = true
      local x_t, y_t= wallturn_teletransporter:get_position()
      local map_id = map:get_id()
      hero:set_enabled(false)
      sprite:set_animation("revolving_tunic_1")
      audio_manager:play_sound("misc/dungeon_one_way_door")
      function sprite:on_animation_finished(animation)
        if animation == "revolving_tunic_1" or animation == "revolving_tunic_2" or animation == "revolving_tunic_2" then
          sprite:set_animation("stopped")
          entity:set_traversable_by(true)
          hero:set_position(x_t, y_t)
          hero:set_enabled(true)
          hero:set_direction(1)
          local movement = sol.movement.create("path")
          movement:set_path{2,2,2,2,2,2,2,2}
          movement:set_ignore_obstacles(true)
          movement:start(hero, function()
            hero:freeze()
            hero:unfreeze()
            entity:set_traversable_by(false)
            animation_launch = false
          end)
        end
      end
    end

  end)

end)
