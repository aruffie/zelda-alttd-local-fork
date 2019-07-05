require("scripts/multi_events")
local game_meta = sol.main.get_metatable("game")
local hero_meta = sol.main.get_metatable("hero")
local timer_sleeping
local duration = 15000
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
  if not map:is_sideview() then
    if sleeping_animation ~= nil and sleeping_animation.type == 'overtime' then
      map:start_coroutine(function()
          local sa = sleeping_animation
          sleeping_animation = nil
          hero:freeze()
          animation(hero:get_sprite("tunic"), sa.animation_out)
          hero:unfreeze()
        end)
    end
    if hero:get_state() == 'free' then
      coro_sleeping = map:start_coroutine(function()
          suspendable_wait(duration)
          local index = math.random(#sleeping_animations)
          sleeping_animation = sleeping_animations[index]
          -- Immediate animation
          if sleeping_animation.type == 'immediate' then
            animation(hero:get_sprite("tunic"), sleeping_animation.animation_in)
            hero:unfreeze()
            hero:launch_sleeping()
            sleeping_animation = nil
          else
            -- Overtime animation
            hero:get_sprite():set_animation(sleeping_animation.animation_in)
            wait(sleeping_animation.duration)
            animation(hero:get_sprite("tunic"), sleeping_animation.animation_out)
            hero:unfreeze()
            sleeping_animation = nil
          end
        end)
    end
  end
end

hero_meta:register_event("on_state_changed", function(hero, state)

    if state == 'free' then
      hero:launch_sleeping()
    else
      if coro_sleeping ~= nil then
        coro_sleeping.abort()
      end
    end

  end)

hero_meta:register_event("on_movement_changed", function(hero,x,y,layer)

    hero:launch_sleeping()

  end)