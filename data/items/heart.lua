-- Lua script of item "heart".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_shadow("small")
  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)
  item:set_sound_when_picked(nil)
  
end

function item:on_obtaining(variant, savegame_variable)

  -- Sound
  if item:get_game():get_life() == item:get_game():get_max_life() then
    audio_manager:play_sound("items/get_item")
  else
    -- Life
    item:get_game():add_life(4)
  end
  
end

-- Event called when a pickable treasure representing this item
-- is created on the map.
function item:on_pickable_created(pickable)

  if pickable:get_falling_height() == 0 then
    -- Not falling: don't animate the heart.
    pickable:get_sprite():set_frame(24)
  else
    -- Replace the default falling movement by a special one.
    local main_sprite = pickable:get_sprite()
    local shadow_sprite = pickable:create_sprite("entities/shadow")
    pickable:bring_sprite_to_back(shadow_sprite)
    local trajectory = {
      { 0,  0},
      { 0, -2},
      { 0, -2},
      { 0, -2},
      { 0, -2},
      { 0, -2},
      { 0,  0},
      { 0,  0},
      { 1,  1},
      { 1,  1},
      { 1,  0},
      { 1,  1},
      { 1,  1},
      { 0,  0},
      {-1,  0},
      {-1,  1},
      {-1,  0},
      {-1,  1},
      {-1,  0},
      {-1,  1},
      { 0,  1},
      { 1,  1},
      { 1,  1},
      {-1,  0}
    }
    local m = sol.movement.create("pixel")
    m:set_trajectory(trajectory)
    m:set_delay(100)
    m:set_loop(false)
    m:set_ignore_obstacles(true)

    m:start(main_sprite, function()
      if pickable:exists() then
        pickable:remove_sprite(shadow_sprite)
      end
    end)
  end

end

