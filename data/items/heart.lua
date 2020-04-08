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

    print(pickable:get_falling_height())
    print('ok2')
  if pickable:get_falling_height() ~= 0 then
        print(pickable:get_falling_height())
    print('ok')
    -- Replace the default falling movement by a special one.
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
    m:start(pickable)
  end

end

