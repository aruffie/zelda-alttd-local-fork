local cinematic_manager = {}
local map_meta = sol.main.get_metatable("map")
require("scripts/multi_events")

local quest_w, quest_h = sol.video.get_quest_size()
local black_stripe_h = 24

-- Enable or disable the cinematic mode
function map_meta:set_cinematic_mode(map, is_cinematic, options)

  local game = map:get_game()
  local camera = map:get_camera()

  game.is_cinematic = is_cinematic
  game:set_hud_enabled(not is_cinematic)

  -- Change size camera
  if is_cinematic then
    local camera_h = quest_h - 2 * black_stripe_h
    camera:set_size(quest_w, camera_h)
    camera:set_position_on_screen(0, black_stripe_h)
  else
    camera:set_size(quest_w, quest_h)
    camera:set_position_on_screen(0, 0)
  end

  local hero = map:get_hero()
  if is_cinematic then
    hero:freeze()
  else
    hero:unfreeze()
  end

  -- Prevent or allow the player from pausing the game
  game:set_pause_allowed(not is_cinematic)

  if not is_cinematic then
    camera:start_tracking(hero)
  end

end

-- Retrieve the cinematic status

function map_meta:is_cinematic()

    return game.is_cinematic

end


return cinematic_manager