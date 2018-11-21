-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  item:set_shadow("small")
  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)
  item:set_sound_when_picked(nil)
  
end

function item:on_obtaining(variant, savegame_variable)

  audio_manager:play_sound("items/get_item")
  item:get_game():add_life(4)
  
end

function item:on_pickable_created(pickable)

  if pickable:get_falling_height() ~= 0 then
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

