----------------------------------
--
-- Master Stalfos.
--
-- Start by falling from the ceiling, then strike, walk or jump to hero depending on the distance between them.
-- The body part is invicible and doesn't hurt, the shield and the sword parts are also invicible and hurt, and the head one is vulnerable and hurt.
-- Can only be defeated by a sword hit on the head to make it collapse, then an explosion that touches the body or head part.
-- May start the "dialog" property dialog after falling if any.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head, sword, shield
local body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_on_ground = false

-- Configuration variables
local falling_duration = 1000
local seeking_duration = 750
local waiting_duration = 1000
local aiming_duration = 200
local collapsed_duration = 1500
local shaking_duration = 1000
local dizzy_duration = 500
local hurt_duration = 1000
local striking_duration = 750
local walking_speed = 32
local walking_maximum_duration = 1000
local jumping_maximum_speed = 150
local jumping_height = 32
local jumping_duration = 650
local strike_triggering_distance = 32
local walking_triggering_distance = 60

-- Echo some of the reference_sprite events and methods to the given sprite.
local function synchronize_sprite(sprite, reference_sprite)

  reference_sprite:register_event("on_direction_changed", function(reference_sprite)
    sprite:set_direction(reference_sprite:get_direction())
  end)
  reference_sprite:register_event("on_animation_changed", function(reference_sprite, name)
    if sprite:has_animation(name) then
      sprite:set_animation(name)
    end
  end)
  reference_sprite:register_event("set_xy", function(reference_sprite, x, y)
    sprite:set_xy(x, y)
  end)
end

-- Create a sub enemy, then echo some of the enemy and sprite events and methods to it.
local function create_sub_enemy(sprite_name)

  local x, y, layer = enemy:get_position()
  local sub_enemy = map:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_" .. sprite_name,
    breed = "empty", -- Workaround: Breed is mandatory but a non-existing one seems to be ok to create an empty enemy though.
    x = x,
    y = y,
    layer = layer,
    direction = body_sprite:get_direction()
  })
  enemy:start_welding(sub_enemy)
  sub_enemy:set_drawn_in_y_order(false) -- Display this enemy as a flat entity.
  sub_enemy:bring_to_front()

  -- Create the sub enemy sprite, and synchronize it on the body one.
  local sub_sprite = sub_enemy:create_sprite("enemies/boss/master_stalfos/" .. sprite_name)
  sub_sprite:synchronize(body_sprite)
  synchronize_sprite(sub_sprite, body_sprite)

  return sub_enemy
end

-- Update the direction depending on hero position.
local function update_direction()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  body_sprite:set_direction(hero_x < x and 2 or 0)
end

-- Start the custom hurt and check if the custom death as to be started.
local function hurt(damage)

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      body_sprite:set_animation("hurt")
      sol.timer.start(enemy, 1500, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", 0, -20, function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, 0, -20)
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", 0, -20)
        end)
      end)
    end)
    return
  end

  -- TODO Repulse and keep the exact same behavior as if not hurt, just replace one of the 4 possible animation by its hurt equivalent at the same frame.
  enemy:set_life(enemy:get_life() - damage)
  --[[
  set_sprites_animation("hurt")
  sol.timer.start(enemy, hurt_duration, function()
    set_sprites_animation("walking")
  end)
  --]]
  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Collapse for some time when the head is hit by sword and make the body vulnerable to explosions, then shake for time and finally restore and restart.
local function on_head_hurt()

  -- TODO Repulse and let the jump finish if any before collapsing.

  -- Make all enemy parts harmless and body vulnerable to explosions.
  enemy:stop_all()
  head:set_can_attack(false)
  sword:set_can_attack(false)
  shield:set_can_attack(false)

  enemy:set_hero_weapons_reactions("ignored", {
    explosion = function() hurt(1) end,
  })
  head:set_hero_weapons_reactions("ignored")
  sword:set_hero_weapons_reactions("ignored")
  shield:set_hero_weapons_reactions("ignored")

  -- TODO Only start the collapse animation on the body part. The other one fall on ground as they are when touched.

  body_sprite:set_animation("collapse", function()
    sol.timer.start(enemy, collapsed_duration, function()
      body_sprite:set_animation("shaking")
      sol.timer.start(enemy, shaking_duration, function()
        body_sprite:set_animation("restore", function()

          -- Add a small extra time after the restore to be hurt by the explosion.
          body_sprite:set_animation("waiting")
          sol.timer.start(enemy, dizzy_duration, function()
            enemy:restart()
          end)
        end)
      end)
    end)
  end)
end

-- Make the boss fall from the ceiling.
local function start_falling()

  local _, enemy_y = enemy:get_position()
  local _, camera_y = map:get_camera():get_position()
  enemy:set_visible()
  body_sprite:set_animation("jumping")
  body_sprite:set_direction(0)

  -- Fall from ceiling.
  enemy:start_throwing(enemy, falling_duration, enemy_y - camera_y, nil, nil, nil, function()
    is_on_ground = true
    body_sprite:set_animation("waiting")

    -- Start the dialog if any, else look left and right.
    local dialog = enemy:get_property("dialog")
    if dialog then
      game:start_dialog(dialog)
      enemy:restart()
    else
      sol.timer.start(enemy, seeking_duration, function()
        body_sprite:set_direction(2)
        sol.timer.start(enemy, seeking_duration, function()
          body_sprite:set_direction(0)
          sol.timer.start(enemy, seeking_duration, function()
            enemy:restart()
          end)
        end)
      end)
    end
  end)
end

-- Make the enemy strike with his sword.
local function start_striking()

  -- Aim for some time, then strike. 
  body_sprite:set_animation("aiming")
  update_direction()

  sol.timer.start(enemy, aiming_duration, function()
    body_sprite:set_animation("striking")
    sol.timer.start(enemy, striking_duration, function()
      enemy:restart()
    end)
  end)
end

-- Make the enemy walk to the hero, then strike.
local function start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  body_sprite:set_animation("walking")

  -- Start the timer of the maximum walk time, and restart once finished.
  local timer = sol.timer.start(enemy, walking_maximum_duration, function()
    movement:stop()
    enemy:restart()
  end)

  -- If the distance is lower than the strike distance, restart.
  function movement:on_position_changed()
    update_direction()

    local distance = enemy:get_distance(hero)
    if distance < strike_triggering_distance then
      timer:stop()
      movement:stop()
      enemy:restart()
    end
  end
end

-- Start jumping to the hero.
local function start_jumping()

  local distance = enemy:get_distance(hero)
  local angle = enemy:get_angle(hero)
  body_sprite:set_animation("jumping")
  update_direction()

  enemy:start_jumping(jumping_duration, jumping_height, angle, math.min(distance / jumping_duration * 1000, jumping_maximum_speed), function()
    enemy:restart()
  end)
end

-- Decide if the enemy should strike, walk or jump, depending on the distance to the hero.
local function start_waiting()

  body_sprite:set_animation("waiting")
  update_direction()

  -- Strike right now if the hero is near enough, else wait and decide later to walk or jump.
  local distance = enemy:get_distance(hero)
  if distance < strike_triggering_distance then
    start_striking()
  else
    sol.timer.start(enemy, waiting_duration, function()
      distance = enemy:get_distance(hero)
      if distance < walking_triggering_distance then
        start_walking()
      else
        start_jumping()
      end
    end)
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_visible(false)

  enemy:set_life(12)
  enemy:set_size(32, 16)
  enemy:set_origin(16, 13)
  enemy:start_shadow("enemies/boss/master_stalfos/shadow")
  enemy:set_drawn_in_y_order(false) -- Display this enemy as a flat entity.

  -- Add legs sprite to the main enemy as they behaves the same way.
  local legs_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/legs")
  synchronize_sprite(legs_sprite, body_sprite)
  enemy:bring_sprite_to_back(legs_sprite)
  
  -- Create head, sword and shield sub enemies.
  head = create_sub_enemy("head")
  sword = create_sub_enemy("sword")
  shield = create_sub_enemy("shield")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- The body part is invincible and doesn't hurt the hero.
  enemy:set_invincible()
  enemy:set_can_attack(false)
  enemy:set_damage(0)

  -- The head part collapse on sword hit and can hurt the hero.
  head:set_hero_weapons_reactions("ignored", {
    sword = on_head_hurt
  })
  head:set_can_attack(true)
  head:set_damage(4)

  -- The sword and shield are both protected to hero weapons and can hurt the hero.
  sword:set_hero_weapons_reactions("protected")
  sword:set_can_attack(true)
  sword:set_damage(4)

  shield:set_hero_weapons_reactions("protected")
  shield:set_can_attack(true)
  shield:set_damage(4)

  -- States.
  if is_on_ground then
    start_waiting()
  else
    start_falling()
  end
end)
