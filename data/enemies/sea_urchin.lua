-- Lua script of enemy sea urchin.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local sprite = enemy:create_sprite("enemies/sea_urchin")
local game = enemy:get_game()
local map = game:get_map()

enemy:register_event("on_created", function(enemy)

  enemy:set_traversable(false)
  enemy:set_life(1)
  enemy:set_damage(2)
  enemy:set_hurt_style("normal")
  enemy:set_attacking_collision_mode("touching")
  enemy:set_default_behavior_on_hero_shield("block_push")
  enemy:set_pushed_by_shield_property("sound_id", "enemies/sea_urchin_push" .. math.random(2))
  
end)

function sprite:on_animation_finished(animation)

  if animation == "bite" then
    enemy:set_animation("walking")
  end

end