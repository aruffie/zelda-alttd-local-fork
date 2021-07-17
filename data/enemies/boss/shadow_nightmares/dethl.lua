----------------------------------
--
-- Dethl.
--
-- Enemy with a big head and two spinning arms. Regularly open his eye which make it vulnerable to arrow and boomerang.
-- Arms are spinning faster as the boss loses life, one arm more than the other.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed(), "main")
local hurt_shader = sol.shader.create("hurt")
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local arms = {}
local walking_box = {}

-- Configuration variables.
local between_arm_part_appearance_duration = 500
local arm_part_distances = {24, 40, 54, 68}
local arm_base_revolution_duration = 4000
local arm_revolution_duration_increase_by_hp = {125, 120}
local eye_opening_minimum_duration = 1000
local eye_opening_maximum_duration = 5000
local eye_opened_duration = 1500
local walking_speed = 16
local walking_acceleration = 8
local walking_deceleration = 8
local hurt_duration = 600
local dying_hurt_duration = 2000

-- Start the enemy movement.
local function start_walking()

  local x, y = enemy:get_position()
  local target_x, target_y = math.random(walking_box.x, walking_box.x2), math.random(walking_box.y, walking_box.y2)
  local angle = enemy:get_angle(target_x, target_y)
  local distance = enemy:get_distance(target_x, target_y)

  -- Start moving to the target with acceleration.
  local movement = enemy:start_impulsion(angle, walking_speed, walking_acceleration, walking_deceleration, distance)

  -- Target a new random point when target reached.
  function movement:on_decelerating()
    start_walking()
  end
end

-- Start shader on each sprites.
local function start_shader(shader)

  head_sprite:set_shader(shader)
  for _, arm in ipairs(arms) do
    for _, sprite in ipairs(arm.sprites) do
      sprite:set_shader(shader)
    end
  end
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt(damage)

  enemy:set_arrow_reaction_sprite(head_sprite, "protected")
  enemy:set_attack_consequence_sprite(head_sprite, "boomerang", "protected")

  -- Die if no more life.
  if enemy:get_life() - damage < 1 then
    enemy:start_death(function()
      start_shader(hurt_shader)
      sol.timer.start(enemy, dying_hurt_duration, function()
        start_shader(nil)

        -- Make sprite disappear one after each others.
        local next_index = #arms[1].sprites
        sol.timer.start(enemy, 400, function()
          if next_index == 0 then
            finish_death()
            return
          end
          for _, arm in ipairs(arms) do
            enemy:remove_sprite(arm.sprites[next_index])
          end
          next_index = next_index - 1
          return true
        end)
      end)
    end)
    return
  end

  -- Manually hurt the enemy then close the eye.
  enemy:set_life(enemy:get_life() - damage)
  start_shader(hurt_shader)
  sol.timer.start(enemy, hurt_duration, function()
    start_shader(nil)
    if head_sprite:get_animation() == "opened" then
      enemy:set_arrow_reaction_sprite(head_sprite, function() hurt(1) end)
      enemy:set_attack_consequence_sprite(head_sprite, "boomerang", function() hurt(16) end)
    end
  end)

  -- Make arms spin faster.
  for i = 1, 2, 1 do
    local current_revolution_duration = arms[i].revolution_duration
    arms[i].revolution_duration = arm_base_revolution_duration - (16 - enemy:get_life()) * arm_revolution_duration_increase_by_hp[i]
    arms[i].spin_time = arms[i].spin_time / current_revolution_duration * arms[i].revolution_duration
  end

  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Make all arm sprites protected to arrow and boomerang.
local function start_head_vulnerable(vulnerable)

  enemy:set_arrow_reaction_sprite(head_sprite, vulnerable and function() hurt(1) end or "protected")
  enemy:set_attack_consequence_sprite(head_sprite, "boomerang", vulnerable and function() hurt(16) end or "protected")
end

-- Open eye periodically.
local function start_eye_opening()

  sol.timer.start(enemy, math.random(eye_opening_minimum_duration, eye_opening_maximum_duration), function()
    head_sprite:set_animation("eye_opening", function()
      head_sprite:set_animation("eye_opened")
      start_head_vulnerable(true)
      sol.timer.start(enemy, eye_opened_duration, function()
        start_head_vulnerable(false)
        head_sprite:set_animation("eye_closing", function()
          head_sprite:set_animation("eye_closed")
          start_eye_opening()
        end)
      end)
    end)
  end)
end

-- Update arm rotation.
local function update_arm(arm)

  arm.spin_time = arm.spin_time + 10 * arm.rotation_sense
  arm.spin_angle = arm.spin_time / arm.revolution_duration * circle
  for i = 1, #arm.sprites, 1 do
    local x, y = arm_part_distances[i] * math.cos(arm.spin_angle), -arm_part_distances[i] * math.sin(arm.spin_angle) - 12
    arm.sprites[i]:set_xy(x, y)
  end
end

-- Make the enemy appear.
local function start_appearing()

  head_sprite:set_animation("appearing", function()
    head_sprite:set_animation("eye_closed")

    -- Create arm part on each arms.
    sol.timer.start(enemy, between_arm_part_appearance_duration, function()
      local part_count = #arms[1].sprites + 1
      for i = 1, 2, 1 do
        local arm = arms[i]
        local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
        table.insert(arm.sprites, sprite)
        sprite:set_animation((part_count == 1 and "arm_big") or (part_count == 4 and "hand") or "arm_small")
        sprite:set_xy(arm_part_distances[#arm.sprites] * math.cos(arm.spin_angle), -arm_part_distances[#arm.sprites] * math.sin(arm.spin_angle) - 12)
      end
      enemy:bring_sprite_to_front(head_sprite)

      -- Make arms start spinning after the first part created.
      if part_count == 1 then
        sol.timer.start(enemy, 10, function()
          for _, arm in ipairs(arms) do
            update_arm(arm)
          end
          return true
        end)
      end
      return part_count < #arm_part_distances
    end)

    -- Open eye periodically and start moving.
    start_eye_opening()
    start_walking()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(16)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Create arms.
  for i = 1, 2, 1 do
    arms[i] = {}
    arms[i].sprites = {}
    arms[i].revolution_duration = arm_base_revolution_duration
    arms[i].spin_angle = quarter
    arms[i].spin_time = arm_base_revolution_duration * 0.25
    arms[i].rotation_sense = i == 1 and 1 or -1
  end

  -- Store walking limit box.
  local camera_x, camera_y, camera_width, camera_height = camera:get_bounding_box()
  walking_box.x = camera_x + 80
  walking_box.y = camera_y + 80
  walking_box.x2 = camera_x + camera_width - 80
  walking_box.y2 = camera_y + camera_height - 80
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "protected",
  	explosion = "protected",
  	sword = "protected",
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "protected",
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = "protected"
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  start_appearing()
end)
