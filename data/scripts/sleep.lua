require("scripts/multi_events")
local game_meta = sol.main.get_metatable("game")
local hero_meta = sol.main.get_metatable("hero")
local timer_sleeping
local duration = 10000
local coro_sleeping = nil
local sleeping_animation = nil
local sleeping_animations = {
  {
    animation_in = "happy",
    type = "immediate"
  },
  {
    animation_in = "sad",
    type = "immediate"
  },
  {
    animation_in = "link_tired",
    type = "immediate"
  },
  {
    animation_in = "link_sleeping",
    animation_out = "link_awakening",
    duration = 6400,
    type = "overtime"
  }
}

function hero_meta:launch_sleeping()

  if coro_sleeping ~= nil then
    coro_sleeping.abort()
  end
  local hero = self
  local game = hero:get_game()
  local map = game:get_map()
  if sleeping_animation ~= nil and sleeping_animation.type == 'overtime' then
    map:start_coroutine(function()
      hero:freeze()
      animation(hero, sleeping_animation.animation_out)
      hero:unfreeze()
    end)
  end
  coro_sleeping = map:start_coroutine(function()
    wait(duration)
    if not map:is_cinematic() then
      local index = math.random(#sleeping_animations)
      index = 3
      sleeping_animation = sleeping_animations[index]
      -- Immediate animation
      if sleeping_animation.type == 'immediate' then
        animation(hero, sleeping_animation.animation_in)
        hero:unfreeze()
        hero:launch_sleeping()
      else
        -- Overtime animation
        hero:get_sprite():set_animation(sleeping_animation.animation_in)
        wait(sleeping_animation.duration)
        animation(hero, sleeping_animation.animation_out)
        hero:unfreeze()
      end
    end
  end)

end

hero_meta:register_event("on_state_changed", function(hero, state)

  if state ~= 'free' then
    hero:launch_sleeping()
  end

end)

hero_meta:register_event("on_movement_changed", function(hero,x,y,layer)

  hero:launch_sleeping()

end)

game_meta:register_event("on_dialog_started", function(game, dialog, info)

  hero:launch_sleeping()

end)