----------------------------------
--
-- Arm Mimic.
--
-- Copy and reverse hero moves.
-- Sword only hurt him if the hero direction is not the enemy opposite direction.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local is_pushed_back = false

-- Only hurt the enemy if the sword attack is a spin attack, else push the enemy back.
local function on_sword_attack_received(damage)

  if hero:get_sprite():get_animation() == "spin_attack" then
    enemy:hurt(damage)

  elseif not is_pushed_back then
    is_pushed_back = true
    enemy:start_pushed_back(hero, 200, 100, sprite, nil, function()
      is_pushed_back = false
    end)
  end
end

-- Copy and reverse hero moves if he is moving, not hurt and if the enemy not dying.
hero:register_event("on_movement_changed", function(hero)

  if not enemy:exists() or not enemy:is_enabled() then
    return
  end

  local movement = hero:get_movement()
  if movement and movement:get_speed() > 0 and hero:get_state() ~= "hurt" and enemy:get_life() > 0 then
    enemy:start_straight_walking(movement:get_angle() + math.pi, movement:get_speed())
    sprite:set_direction((movement:get_direction4() + 2) % 4) -- Always keep the hero opposite movement direction, not sprite direction.
  else
    enemy:restart()
  end
end)

-- Workaround: Stop the enemy on hero states that doesn't trigger hero:on_movement_changed() event.
hero:register_event("on_state_changing", function(hero, state_name, next_state_name)

  if next_state_name == "sword swinging" then
    enemy:restart()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    sword = function() on_sword_attack_received(1) end,
    hookshot = "immobilized",
    boomerang = "immobilized",
    jump_on = "ignored"})

  -- States.
  sprite:set_animation("immobilized")
  enemy:stop_movement()
  enemy:set_can_attack(true)
  enemy:set_damage(12)
end)
