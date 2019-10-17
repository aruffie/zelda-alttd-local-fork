-- Variables
local seagull = ...
local game = seagull:get_game()
local map = game:get_map()
local sprite = seagull:get_sprite()
local hero = game:get_hero()
local movement
local x
local y
local layer
local is_escape = false
local is_move = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
seagull:register_event("on_created", function()

  x,y,layer = seagull:get_position()
  seagull:set_can_traverse(true)
  sol.timer.start(seagull, 50, function()
    if hero:get_distance(seagull) < 24 and is_escape == false and is_move == false then
      seagull:escape_hero()
    end
    if hero:get_distance(x,y) > 50 and is_escape == true and is_move == false  then
      seagull:join_origin()
    end
    return true
  end)

end)

function seagull:escape_hero()

  is_move = true
  audio_manager:play_sound("misc/seagull")
  -- Set the sprite.
  sprite:set_animation("walking")
  sprite:set_direction(1)
  -- Set the movement.
  movement = sol.movement.create("straight")
  movement:set_speed(100)
  movement:set_max_distance(320)
  movement:set_ignore_obstacles(true)
  movement:start(seagull)
  function movement:on_finished()
    is_escape = true
    is_move = false
  end
  
end

function seagull:join_origin()

  is_move = true
  -- Set the sprite.
  sprite:set_animation("walking")
  sprite:set_direction(3)
  -- Set the movement.
  movement = sol.movement.create("target")
  movement:set_target(x, y)
  movement:set_speed(100)
  movement:set_ignore_obstacles(true)
  movement:start(seagull)
  function movement:on_finished()
    sprite:set_animation("stopped")
    is_escape = false
    is_move = false
    audio_manager:play_entity_sound(seagull, "misc/seagull")
  end
  
end

