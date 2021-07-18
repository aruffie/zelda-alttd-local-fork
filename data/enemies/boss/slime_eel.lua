----------------------------------
--
-- Slime Eel.
--
-- Caterpillar enemy that can arise from apertures in the wall to bite the hero, and use its tail as a flail from the center of the room.
-- Can be partially pulled out the aperture with the hookshot while its mouth is open to reveal the weak point on its first body, hurtable with the sword or thrust attack.
-- Sometimes a small Slime Eel is fully pulled out instead of the enemy, which behaves as a Moldorm.
--
-- Methods : enemy:start_appearing()
--           enemy:start_fighting()
--           enemy:create_aperture(x, y, direction, broken_entity)
--
----------------------------------

-- Global variables.
local enemy = ...
local audio_manager = require("scripts/audio_manager")
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprites = {}
local quarter = math.pi * 0.5
local tail
local apertures = {}
local current_aperture
local is_catched = false

-- Configuration variables.
local arise_speed = 180
local arise_distance = 32
local go_back_speed = 30
local biting_duration = 500
local hidden_minimum_duration = 1000
local hidden_maximum_duration = 2000
local peeking_duration = 1000
local stunned_speed = 5
local stunned_duration = 2500
local return_speed = 88
local grabbing_moldorm_probability = 0.2
local hurt_duration = 600

-- Make the enemy protected against all.
local function start_invulnerable()

  enemy:set_hero_weapons_reactions({
    arrow = "protected",
    boomerang = "protected",
    explosion = "ignored",
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
end

-- Start returning to the aperture in a hurry.
local function start_hurry_back(length, direction)

  local movement = enemy:start_straight_walking((direction + 2) % 4 * quarter, return_speed, length + arise_distance, function()
    for i = 2, #sprites, 1 do
      enemy:remove_sprite(sprites[i])
      sprites[i] = nil
    end
    enemy:start_fighting()
  end)
  movement:set_ignore_obstacles()
  sprites[1]:set_direction(direction)
  tail:start_rising(return_speed)
end

-- Hurt behavior of the enemy.
local function on_hurt()

  for _, sprite in ipairs(sprites) do
    if sprite.base_animation == "weak" then
      enemy:set_attack_consequence_sprite(sprite, "sword", "protected")
      enemy:set_thrust_reaction_sprite(sprite, "protected")
    end
  end
  sol.timer.stop_all(enemy)
  enemy:stop_movement()
  tail:stop_moving()

  -- Custom die if only one more life point.
  if enemy:get_life() < 2 then

    enemy:start_death(function()
      local sorted_tied_sprites = {}
      for i = #sprites, 2, -1 do
        sprites[i]:set_animation(sprites[i].base_animation .. "_hurt")
        table.insert(sorted_tied_sprites, sprites[i])
      end
      sprites[1]:set_animation("hurt")

      -- Start a chained explosion starting by the tail end to the tail base, then to main enemy head.
      function tail:on_dead()
        enemy:start_sprite_explosions(sorted_tied_sprites, "entities/explosion_boss", 0, 0, "enemies/moldorm_segment_explode", function()
          sol.timer.start(enemy, 1500, function()
            enemy:start_brief_effect("entities/explosion_boss")
            audio_manager:play_sound("enemies/boss_explode")
            finish_death()
          end)
        end)
      end
      tail:start_exploding()
      audio_manager:play_sound("enemies/boss_die")
    end)
    return
  end

  -- Manually hurt to not trigger the built-in behavior.
  enemy:set_life(enemy:get_life() - 1)
  sprites[1]:set_animation("hooked_hurt")
  for i = 2, #sprites, 1 do
    sprites[i]:set_animation(sprites[i].base_animation .. "_hurt")
  end
  if enemy.on_hurt then
    enemy:on_hurt()
  end

  -- Then return hidding to the aperture in a hurry.
  sol.timer.start(enemy, hurt_duration, function()
    start_hurry_back((#sprites - 1) * 22 + 26, sprites[1]:get_direction())
    sprites[1]:set_animation("walking")
    for i = 2, #sprites, 1 do
      if sprites[i].base_animation == "weak" then
        enemy:set_attack_consequence_sprite(sprites[i], "sword", on_hurt)
        enemy:set_thrust_reaction_sprite(sprites[i], on_hurt)
      end
      sprites[i]:set_animation(sprites[i].base_animation)
    end
  end)
end

-- Create a body sprite to the enemy.
local function create_body_sprite(is_weak)

  local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")

  if is_weak then
    sprite.base_animation = "weak"
    enemy:set_attack_consequence_sprite(sprite, "sword", on_hurt)
    enemy:set_thrust_reaction_sprite(sprite, on_hurt)
  else
    sprite.base_animation = "body"
  end
  sprite:set_animation(sprite.base_animation)

  return sprite
end

-- Grab a moldorm from the aperture.
local function start_grabbing_moldorm()

  enemy:set_invincible()
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  tail:stop_moving()
  local moldorm = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_moldorm",
    breed = "boss/projectiles/eel_moldorm",
    direction = sprites[1]:get_direction()
  })
  moldorm:start_catched(40, 256) -- TODO Get hookshot speed dynamically

  function moldorm:on_dead()
    tail:start_rising()
    enemy:start_fighting()
  end
end

-- Make the enemy vertically pulled by the hookshot, and pull the tail by the same length.
local function start_pulled(length, speed, direction)

  -- Randomly grab a moldorm from the aperture.
  if math.random() < grabbing_moldorm_probability then
    start_grabbing_moldorm()
    tail:start_pulled()
    return
  end

  -- Make body parts follow the head, creating it if needed.
  local head_gap = (direction == 1) and 26 or -26
  local sprite_gap = (direction == 1) and 22 or -22
  local body_count = math.ceil((length + arise_distance) / 24)
  local function follow_head(enemy)
    for i = 2, body_count, 1 do
      if not sprites[i] then
        sprites[i] = create_body_sprite(i == 2)
      end
      sprites[i]:set_xy(0, head_gap + sprite_gap * (i - 2))
    end
  end

  -- Start grabbing the head.
  local grabbing_movement = enemy:start_straight_walking(direction * quarter, speed, length, function()

    -- Slowly go back while stunned.
    local stunned_movement = enemy:start_straight_walking((direction + 2) % 4 * quarter, stunned_speed)
    stunned_movement:set_ignore_obstacles()
    stunned_movement.on_position_changed = follow_head
    sprites[1]:set_direction(direction)
    sprites[1]:set_animation("hooked")
    tail:start_rising(stunned_speed)

    -- Then return to aperture at an higher speed after some time.
    sol.timer.start(enemy, stunned_duration, function()
      start_hurry_back(length, direction)
    end)
  end)
  grabbing_movement:set_ignore_obstacles()
  grabbing_movement.on_position_changed = follow_head
  sprites[1]:set_animation("hooked")

  -- Also pull the tail to the ground.
  tail:start_pulled(length, speed)
end

-- Make the enemy actually catched or just bounce depending on the hookshot position and direction.
local function on_catched()

  enemy:set_hero_weapons_reactions({hookshot = "ignored"})

  -- Hook the enemy head if it is in front of the hero.
  local hookshot = game:get_item("hookshot")
  local width = enemy:get_size()
  hookshot:catch_entity(nil) -- Make the hookshot go back.
  if (sprites[1]:get_direction() + 2) % 4 == hero:get_direction() and enemy:is_aligned(hero, width) then
    
    local _, y = enemy:get_position()
    local _, hero_y = hero:get_position()
    local direction = sprites[1]:get_direction()
    local length = math.abs(hero_y - y) - (direction == 3 and 32 or 20)
    local speed = 256 -- TODO Get hooshot speed dynamically
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    start_pulled(length, speed, direction)
  end
end

-- Make the enemy vulnerable to hookshot only.
local function start_catchable()

  enemy:set_hero_weapons_reactions({
    arrow = "protected",
    boomerang = "protected",
    explosion = "ignored",
    sword = "protected",
    thrown_item = "protected",
    fire = "protected",
    jump_on = "ignored",
    hammer = "protected",
    hookshot = on_catched,
    magic_powder = "ignored",
    shield = "protected",
    thrust = "protected"
  })
end

-- Make the enemy arise from an aperture.
local function start_arising(x, y, direction, on_finished_callback)

  enemy:set_position(x, y)
  local movement = enemy:start_straight_walking(direction * quarter, arise_speed, arise_distance, function()
    sol.timer.start(enemy, biting_duration, function()
      enemy:set_hero_weapons_reactions({hookshot = "ignored"})
      local movement = enemy:start_straight_walking((direction + 2) % 4 * quarter, go_back_speed, arise_distance, function()
        if on_finished_callback then
          on_finished_callback()
        end
      end)
      movement:set_ignore_obstacles()
      sprites[1]:set_direction(direction)
      sprites[1]:set_animation("walking")
    end)
  end)
  movement:set_ignore_obstacles()
  sprites[1]:set_animation("biting")
end

-- Make the enemy tail appear.
enemy:register_event("start_appearing", function(enemy)

  tail = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_tail",
    breed = "boss/projectiles/eel_flail",
    direction = 2
  })
  tail:start_brief_effect("entities/effects/boulder_explosion", "default", -24, -24)
  tail:start_brief_effect("entities/effects/boulder_explosion", "default", -24, 24)
  tail:start_brief_effect("entities/effects/boulder_explosion", "default", 24, -24)
  tail:start_brief_effect("entities/effects/boulder_explosion", "default", 24, 24)
end)

-- Make the enemy start the fighting step.
enemy:register_event("start_fighting", function(enemy)

  enemy:set_invincible()
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  tail:start_spinning()

  sol.timer.start(enemy, math.random(hidden_minimum_duration, hidden_maximum_duration), function()

    -- Make the enemy immobile and peek out from the aperture for some time.
    local x, y, direction = unpack(apertures[math.random(1, 4)])
    enemy:set_position(x, y + (direction == 1 and -10 or 10))
    enemy:set_can_attack(true)
    enemy:set_visible()
    start_invulnerable()
    sprites[1]:set_animation("peeking")
    sprites[1]:set_direction(direction)

    -- Then arise from the hole after some time to bite.
    sol.timer.start(enemy, peeking_duration, function()
      start_catchable()
      start_arising(x, y, direction, function()
        enemy:start_fighting()
      end)
    end)
  end)
end)

-- Make the enemy create an apperture on the map from where the enemy can show up later while hidden on walls.
enemy:register_event("create_aperture", function(enemy, x, y, direction, broken_entity)

  table.insert(apertures, {x, y, direction})

  -- Make the enemy arise from the aperture, and possibly break the entity if given.
  start_invulnerable()
  start_arising(x, y, direction, function()
    enemy:set_invincible()
    enemy:set_visible(false)
    enemy:set_can_attack(false)
  end)
  enemy:set_visible()
  enemy:start_brief_effect("entities/effects/boulder_explosion", "default", 0, direction == 1 and -32 or 32)
  broken_entity:remove()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)
  enemy:set_hurt_style("boss")
  enemy:set_visible(false)

  sprites[1] = enemy:create_sprite("enemies/" .. enemy:get_breed())
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  is_catched = false
  enemy:set_invincible()
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(6)
  enemy:set_obstacle_behavior("flying") -- Don't fall in holes.
  enemy:set_pushed_back_when_hurt(false)
end)
