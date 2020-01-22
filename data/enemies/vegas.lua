-- Variables
local enemy = ...
local sprite
local symbol_fixed = false

-- Include scripts
require("scripts/multi_events")

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_damage(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_invincible(false)
  enemy:set_attack_consequence("sword", 1)
  enemy:set_arrow_reaction(1)
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attack_consequence("fire", 1)
  enemy:set_attack_consequence("thrown_item", 1)
  enemy:set_default_behavior_on_hero_shield("normal_shield_push")

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  
end)

-- The enemy was stopped for some reason and should restart.
enemy:register_event("on_restarted", function(enemy)

  if symbol_fixed then
    sprite:set_animation("immobilized")
    enemy:set_can_attack(false)
    return
  end
  enemy:set_can_attack(true)
  local movement = sol.movement.create("random_path")
  movement:set_speed(48)
  movement:start(enemy)
  -- Random symbol initially.
  sprite:set_direction(math.random(4) - 1)
  -- Switch symbol repeatedly.
  sol.timer.start(enemy, 500, function()
    if sprite:get_animation() ~= "walking" then
      return false
    end
    local direction4 = sprite:get_direction()
    sprite:set_direction((direction4 + 1) % 4)
    return true
  end)

end)

enemy:register_event("on_hurt", function()

  enemy:set_symbol_fixed(true)
  enemy:set_life(1)
  if enemy.on_symbol_fixed ~= nil then
    enemy:on_symbol_fixed()
  end
  
end)

function enemy:is_symbol_fixed()
  
  return symbol_fixed
  
end

function enemy:set_symbol_fixed(fixed)

  if fixed == symbol_fixed then
    return
  end

  symbol_fixed = fixed
  if not fixed then
    enemy:restart()
  end
  
end

enemy:register_event("on_shield_collision", function(enemy, shield)

  enemy:hurt(1)

end)
