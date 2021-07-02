-- Variables
local entity = ...
local game = entity:get_game()
local map = game:get_map()
local sprite = entity:get_sprite()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")


-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  entity:set_traversable_by(false)
  entity:add_collision_test("overlapping", function(pig, explosion)
    if explosion:get_type() == "explosion" or (explosion:get_type() == "custom_entity" and explosion:get_model() == "explosion") then
      audio_manager:play_sound("misc/secret1")
      sprite:set_animation("destroyed")
      sprite:register_event("on_animation_finished", function(sprite, animation)
        if animation == "destroyed" then
          sprite:set_animation("stopped")
          game:set_value("statue_pig_exploded", true)
          entity:set_traversable_by(true)
        end
      end)
    end
  end)

end)