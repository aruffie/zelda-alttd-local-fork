-- Variables
local entity = ...
local game = entity:get_game()
local hero = game:get_hero()
local map = entity:get_map()
local sprite = entity:get_sprite()
local is_destroy = false

-- Include scripts
require("scripts/multi_events")
local audio_manager=require("scripts/audio_manager")
-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  entity:set_traversable_by("hero", false)
  entity:set_traversable_by("enemy", false)

end)

-- Event called when the custom entity is initialized.
entity:register_event("on_interaction", function(entity)

  game:start_dialog("_cannot_break_without_boots");

end)

entity:add_collision_test("facing", function(crystal, other, crystal_sprite, other_sprite)

  if is_destroy == false and other:get_type() =="hero" and hero:get_state() == "custom" and hero:get_state_object():get_description()=="running"  then
    audio_manager:play_sound("misc/bush_cut")
    sprite:set_animation('destroy')
    is_destroy = true
    entity:set_traversable_by("hero", true)
    sol.timer.start(entity, 1000, function()
      entity:remove()
    end)
  end

end)