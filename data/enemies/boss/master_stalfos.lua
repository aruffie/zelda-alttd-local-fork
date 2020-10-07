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
local head, shield, sword
local legs_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed()) -- Use legs sprite as the reference one as it is the only one that doesn't collapse.
local body_sprite, head_sprite, shield_sprite, sword_sprite
local quarter = math.pi * 0.5
local is_upstairs = true
local is_jumping = false
local is_collapse_upcoming = false

-- Configuration variables
local falling_duration = 1000
local seeking_duration = 750
local waiting_duration = 1000
local aiming_duration = 200
local stunned_duration = 500
local collapsed_duration = 2000
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
local collapse_speed = 66
local restore_speed = 24
local body_height = 20
local head_height = 20
local shield_height = 20
local sword_height = 20

-- Make the given sprite move.
local function sprite_collapse(sprite, height, direction, speed, callback)

  local movement = sol.movement.create("straight")
  movement:set_max_distance(height)
  movement:set_angle(direction * math.pi / 2)
  movement:set_speed(speed)
  movement:set_ignore_obstacles(true)
  movement:start(sprite, callback)

  return movement
end

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
  reference_sprite:register_event("set_paused", function(reference_sprite, paused)
    sprite:set_paused(paused)
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
    direction = legs_sprite:get_direction()
  })
  enemy:start_welding(sub_enemy)
  enemy:set_visible(false) -- Create sub enemies as not visible since enemy is supposed to fall from the ceiling.
  sub_enemy:set_drawn_in_y_order(false) -- Display the sub enemy as a flat entity.
  sub_enemy:bring_to_front()

  -- Create the sub enemy sprite, and synchronize it on the body one.
  local sub_sprite = sub_enemy:create_sprite("enemies/boss/master_stalfos/" .. sprite_name)
  sub_sprite:synchronize(legs_sprite)
  synchronize_sprite(sub_sprite, legs_sprite)

  return sub_enemy, sub_sprite
end

-- Update the direction depending on hero position.
local function update_direction()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  legs_sprite:set_direction(hero_x < x and 2 or 0)
end

-- Make upper parts of the enemy collapse to the ground.
local function start_collapse()

  enemy:stop_all()
  is_collapse_upcoming = false

  -- Start the collapse of each parts, starting by the shield and sword, then head and body a little after.
  legs_sprite:set_paused()
  sol.timer.start(enemy, stunned_duration, function()
    sprite_collapse(shield_sprite, shield_height, 3, collapse_speed)
    sprite_collapse(sword_sprite, sword_height, 3, collapse_speed)

    sol.timer.start(enemy, 100, function()
      sprite_collapse(head_sprite, head_height, 3, collapse_speed)
      sprite_collapse(body_sprite, body_height, 3, collapse_speed, function()

        -- Wait for some time then shake.
        sol.timer.start(enemy, collapsed_duration, function()

          -- TODO
          sol.timer.start(enemy, shaking_duration, function()

            -- Restore the enemy from its collapse.
            sprite_collapse(head_sprite, head_height, 1, restore_speed)
            sprite_collapse(shield_sprite, shield_height, 1, restore_speed)
            sprite_collapse(sword_sprite, sword_height, 1, restore_speed)
            sprite_collapse(body_sprite, body_height, 1, restore_speed, function()

              -- Add a small extra dizzy time after the restore to be hurt by the explosion.
              sol.timer.start(enemy, dizzy_duration, function()
                enemy:restart()
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

-- Start the custom hurt and check if the custom death as to be started.
local function hurt(damage)

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      legs_sprite:set_animation("hurt")
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

  is_collapse_upcoming = true

  -- Make all enemy parts harmless and body vulnerable to explosions.
  if not is_jumping then
    enemy:stop_all()
  else
    -- Let timers and movements run if jumping in progress.
    enemy:set_can_attack(false)
    enemy:set_invincible()
  end
  head:set_can_attack(false)
  shield:set_can_attack(false)
  sword:set_can_attack(false)

  enemy:set_hero_weapons_reactions("ignored", {
    explosion = function() hurt(1) end,
  })
  head:set_hero_weapons_reactions("ignored")
  shield:set_hero_weapons_reactions("ignored")
  sword:set_hero_weapons_reactions("ignored")

  -- Repulse the enemy and make it collapse.
  enemy:start_pushed_back(hero, 200, 100, function()

    -- Let a possible jump finish before collapse.
    if not is_jumping then
      start_collapse()
    end
  end)
end

-- Make the boss fall from the ceiling.
local function start_falling()

  local _, enemy_y = enemy:get_position()
  local _, camera_y = map:get_camera():get_position()
  enemy:set_visible()
  legs_sprite:set_animation("jumping")
  legs_sprite:set_direction(0)

  -- Fall from ceiling.
  enemy:start_throwing(enemy, falling_duration, enemy_y - camera_y, nil, nil, nil, function()
    is_upstairs = false
    legs_sprite:set_animation("waiting")

    -- Start the dialog if any, else look left and right.
    local dialog = enemy:get_property("dialog")
    if dialog then
      game:start_dialog(dialog)
      enemy:restart()
    else
      sol.timer.start(enemy, seeking_duration, function()
        legs_sprite:set_direction(2)
        sol.timer.start(enemy, seeking_duration, function()
          legs_sprite:set_direction(0)
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
  legs_sprite:set_animation("aiming")
  update_direction()

  sol.timer.start(enemy, aiming_duration, function()
    legs_sprite:set_animation("striking")
    sol.timer.start(enemy, striking_duration, function()
      enemy:restart()
    end)
  end)
end

-- Make the enemy walk to the hero, then strike.
local function start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  legs_sprite:set_animation("walking")

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

  is_jumping = true

  local distance = enemy:get_distance(hero)
  local angle = enemy:get_angle(hero)
  legs_sprite:set_animation("jumping")
  update_direction()

  enemy:start_jumping(jumping_duration, jumping_height, angle, math.min(distance / jumping_duration * 1000, jumping_maximum_speed), function()
    if not is_collapse_upcoming then
      enemy:restart()
    else
      start_collapse() -- Start a collapse possibly delayed by a running jump.
    end
  end)
end

-- Decide if the enemy should strike, walk or jump, depending on the distance to the hero.
local function start_waiting()

  legs_sprite:set_animation("waiting")
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
  enemy:set_drawn_in_y_order(false) -- Display the legs and body part as a flat entity.

  -- Add body sprite to the main enemy as they behaves the same way.
  body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
  synchronize_sprite(body_sprite, legs_sprite)
  enemy:bring_sprite_to_front(body_sprite)
  
  -- Create head, shield and sword sub enemies.
  head, head_sprite = create_sub_enemy("head")
  shield, shield_sprite = create_sub_enemy("shield")
  sword, sword_sprite = create_sub_enemy("sword")
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
  shield:set_hero_weapons_reactions("protected")
  shield:set_can_attack(true)
  shield:set_damage(4)

  sword:set_hero_weapons_reactions("protected")
  sword:set_can_attack(true)
  sword:set_damage(4)

  -- States.
  is_jumping = false
  is_collapse_upcoming = false
  if not is_upstairs then
    start_waiting()
  else
    start_falling()
  end
end)
