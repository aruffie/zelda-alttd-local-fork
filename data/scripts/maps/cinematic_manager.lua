local cinematic_manager = {}
local map_meta = sol.main.get_metatable("map")
require("scripts/multi_events")

local quest_w, quest_h = sol.video.get_quest_size()
local black_stripe_h = 32
local black_stripe_top = sol.surface.create(quest_w, black_stripe_h)
local black_stripe_bottom = sol.surface.create(quest_w, black_stripe_h)
local m_top = sol.movement.create("target")
m_top:set_ignore_suspend(true)
local m_bottom = sol.movement.create("target")
m_bottom:set_ignore_suspend(true)
black_stripe_top:fill_color({0, 0, 0})
black_stripe_bottom:fill_color({0, 0, 0})

-- Enable or disable the cinematic mode
function map_meta:set_cinematic_mode(is_cinematic)

  local map = self
  local game = map:get_game()
  local camera = map:get_camera()

  game:set_hud_enabled(not is_cinematic)

  game:set_suspended(is_cinematic)

  -- Prevent or allow the player from pausing the game
  game:set_pause_allowed(not is_cinematic)

  if is_cinematic then
    game.is_cinematic = is_cinematic
    local m_top = sol.movement.create("target")
    m_top:set_target(0, black_stripe_h)
    m_top:start(black_stripe_top)
    local m_bottom = sol.movement.create("target")
    m_bottom:set_target(0, -black_stripe_h)
    m_bottom:start(black_stripe_bottom)
  else
    local m_top = sol.movement.create("target")
    m_top:set_target(0, 0)
    m_top:start(black_stripe_top)
    local m_bottom = sol.movement.create("target")
    m_bottom:set_target(0, 0)
    m_bottom:start(black_stripe_bottom)
  end

end

-- Retrieve the cinematic status

function map_meta:is_cinematic()

    local game = self:get_game()
    return game.is_cinematic

end

map_meta:register_event("on_draw", function(map, dst_surface)
    if map:is_cinematic() then
      -- Draw cinematic black stripes.
        black_stripe_top:draw(dst_surface, 0, -black_stripe_h)
        black_stripe_bottom:draw(dst_surface, 0, quest_h)
    end
end)


return cinematic_manager