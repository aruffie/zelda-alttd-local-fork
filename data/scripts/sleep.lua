require("scripts/multi_events")
local game_meta = sol.main.get_metatable("game")
local hero_meta = sol.main.get_metatable("hero")
local timer_sleeping
local duration = 10000
local sleeping_animations = {"happy", "sad"}

function hero_meta:launch_timer_sleeping()
  if timer_sleeping ~= nil then
    timer_sleeping:stop()
  end
  local hero = self
  local game = hero:get_game()
  local sprite = self:get_sprite()
  timer_sleeping = sol.timer.start(self, duration, function()
    if not game:is_cinematic() then
      local animation = sleeping_animations[math.random(#sleeping_animations)]
      sprite:set_animation(animation, function()
        hero:unfreeze()
        hero:launch_timer_sleeping()
      end)
     end
    return true
  end)
end

hero_meta:register_event("on_state_changed", function(hero, state)

  if state ~= 'free' then
    hero:launch_timer_sleeping()
  end

end)

hero_meta:register_event("on_movement_changed", function(hero,x,y,layer)

  hero:launch_timer_sleeping()

end)
