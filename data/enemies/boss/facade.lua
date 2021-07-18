----------------------------------
--
-- Facade.
--
-- Immobile enemy that throws flying tiles and pots to the hero, then create holes on tiles where the hero is.
-- Can be hurt with explosions.
--
-- Events : enemy:on_woke_up()
-- 
----------------------------------

-- Global variables
local enemy = ...
local audio_manager = require("scripts/audio_manager")
local map_tools = require("scripts/maps/map_tools")
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local flying_entities = {}
local holes = {}
local earthquake_timer
local is_digging = false
local digging_timer

-- Configuration variables
local before_waking_up_duration = 2000
local before_blinking_duration = 1000
local after_blinking_duration = 300
local earthquake_frequency = 450
local between_throws_duration = 1000
local invisible_minimum_duration = 3000
local invisible_maximum_duration = 5000
local between_holes_duration = 1000
local hole_duration = 1000
local hurt_duration = 500

-- Replace the entity by a flying enemy and throw it to the hero.
local function create_flying_enemy(entity)

  local x, y, layer = entity:get_position()
  local is_tile = entity:get_type() == "dynamic_tile"
  local flying_enemy = map:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_flying_enemy",
    breed = "flying_tile",
    x = x + (is_tile and 8 or 0),
    y = y + (is_tile and 13 or 0),
    layer = layer,
    direction = 0
  })

  -- Changes some flying tile settings depending on its initial type.
  if not is_tile then
    local flying_sprite = flying_enemy:get_sprite()
    flying_enemy:remove_sprite(flying_sprite)
    flying_enemy:create_sprite(entity:get_sprite():get_animation_set())
    enemy:set_hero_weapons_reactions({
      sword = "ignored",
      shield = "ignored"
    })
  end
  flying_enemy:set_damage(is_tile and 4 or 6)

  -- Echo some of the main enemy methods
  enemy:register_event("on_removed", function(enemy)
    if flying_enemy:exists() then
      flying_enemy:remove()
    end
  end)
  enemy:register_event("on_enabled", function(enemy)
    flying_enemy:set_enabled()
  end)
  enemy:register_event("on_disabled", function(enemy)
    flying_enemy:set_enabled(false)
  end)
  enemy:register_event("on_dying", function(enemy)
    if flying_enemy:exists() then
      flying_enemy:remove()
    end
  end)

  flying_enemy:start_attacking()
  entity:remove()

  return flying_enemy
end

-- Create a hole at given position.
local function create_hole(x, y)

  local hole = map:create_custom_entity({
    direction = 0,
    x = x,
    y = y,
    layer = hero:get_layer(),
    width = 16,
    height = 16,
    sprite = "enemies/boss/facade/hole"
  })
  hole:set_drawn_in_y_order(false)
  hole:bring_to_back()
  local hole_sprite = hole:get_sprite()

  -- Abort if the hole would collide with obstacles or another hole.
  if hole:test_obstacles() then
    hole:remove()
    return
  end
  for hole, _ in pairs(holes) do
    if hole:overlaps(x, y) then
      hole:remove()
      return
    end
  end

  -- Disappear after some time.
  function hole:start_disappearing()
    hole:set_modified_ground("traversable")
    hole_sprite:set_animation("disappearing",function()
      holes[hole] = nil
      hole:remove()
    end)
  end

  -- Make the hole appear and disappear after some time.
  hole_sprite:set_animation("appearing", function()
    hole:set_modified_ground("hole")
    hole_sprite:set_animation("stopped")
    sol.timer.start(hole, hole_duration, function()
      hole:start_disappearing()
    end)
  end)

  holes[hole] = true
  return hole
end

-- Remove all holes.
local function remove_holes()

  if is_digging then
    for hole, _ in pairs(holes) do
      hole:start_disappearing()
    end
    digging_timer:stop()
  end
end

-- Start creating holes below the hero each time he goes to another 16x16 tile.
local function start_digging()

  is_digging = true

  digging_timer = sol.timer.start(enemy, between_holes_duration, function()
    local x, y = enemy:get_random_position_in_area(camera)
    local hole = create_hole(x - x % 16 + 8, y - y % 16 + 13)
    return hole and between_holes_duration or 10 -- Create the hole at the 8, 13 position of the current 16x16 case.
  end)
end

-- Behavior on hit by explosion.
local function on_hurt()

  enemy:set_hero_weapons_reactions({explosion = "ignored"})

  -- Custom die if no more life.
  if enemy:get_life() < 2 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    local x, y = sprite:get_xy()
    earthquake_timer:stop()
    remove_holes()
    enemy:start_death(function()
      sprite:set_animation("hurt")
      sol.timer.start(enemy, 3000, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", x, y - 13, "enemies/moldorm_segment_explode", function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, x, y - 13)
            audio_manager:play_sound("enemies/boss_explode")
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", x, y - 13, "enemies/moldorm_segment_explode")
        end)
      end)
      audio_manager:play_sound("enemies/boss_die")
    end)
    return
  end

  -- Else manually hurt.
  enemy:set_life(enemy:get_life() - 1)
  sprite:set_animation("hurt")
  if enemy.on_hurt then
    enemy:on_hurt()
  end

  -- Continue the enemy animation after hurt finishes.
  sol.timer.start(enemy, hurt_duration, function()
    sprite:set_animation("disappearing", function()
      sol.timer.start(enemy, math.random(invisible_minimum_duration, invisible_maximum_duration), function()
        enemy:set_hero_weapons_reactions({explosion = on_hurt})
        sprite:set_animation("appearing", function()
          sprite:set_animation("waiting")
        end)
      end)
    end)
  end)
end

-- Start the enemy fight.
local function start_fighting()

  enemy:set_hero_weapons_reactions({explosion = on_hurt})
  sprite:set_animation("waiting")
  earthquake_timer = sol.timer.start(enemy, earthquake_frequency, function()
    map_tools.start_earthquake({count = 1, amplitude = 2, speed = 10, sound_frequency = earthquake_frequency})
    return true
  end)

  -- Start throwing entities, and then start digging when no more flying entities.
  local index = 0
  local flying_entities_count = #flying_entities
  sol.timer.start(enemy, between_throws_duration, function()
    index = index + 1

    if flying_entities_count < index then
      return
    end
    if not flying_entities[index]:exists() then
      return 10 -- Directly goes to the next flying entity if this one doesn't exist anymore.
    end
    local flying_enemy = create_flying_enemy(flying_entities[index])

    -- Start the digging step once the last flying enemy is dead.
    local is_last_enemy = true
    for i = index + 1, flying_entities_count, 1 do
      if flying_entities[i] and flying_entities[i]:exists() then
        is_last_enemy = false
        break
      end
    end
    if is_last_enemy then
      flying_enemy:register_event("on_dead", function(enemy)
        start_digging()
      end)
    end

    return between_throws_duration
  end)
end

-- Make the enemy wake up.
local function start_waking_up()

  sol.timer.start(enemy, before_waking_up_duration, function()
    sprite:set_animation("appearing", function()
      sprite:set_animation("stopped")
      sol.timer.start(enemy, before_blinking_duration, function()
        sprite:set_animation("blinking", function()
          sprite:set_animation("stopped")
          sol.timer.start(enemy, after_blinking_duration, function()
            if enemy.on_woke_up then
              enemy:on_woke_up()
            end
            start_fighting()
          end)
        end)
      end)
    end)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(5)
  enemy:set_size(96, 72)
  enemy:set_origin(48, 36)
  enemy:set_hurt_style("boss")

  -- Get flying entities and sort them.
  for entity in map:get_entities_in_region(enemy) do
    if entity:get_property("flying_group") == "boss" then
      flying_entities[tonumber(entity:get_property("flying_order"))] = entity
    end
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible()
  enemy:set_damage(0)
  enemy:set_can_attack(false)
  enemy:set_drawn_in_y_order(false) -- Display the enemy as a flat entity.
  enemy:set_obstacle_behavior("flying")
  start_waking_up()
end)
