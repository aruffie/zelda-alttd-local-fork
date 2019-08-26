-- Variables
local fire = ...
local sprite
local enemies_touched = { }

-- Include scripts
local audio_manager = require("scripts/audio_manager")

fire:set_size(8, 8)
fire:set_origin(4, 5)
sprite = fire:get_sprite() or fire:create_sprite("entities/fire")
sprite:set_direction(fire:get_direction())

-- Remove the sprite if the animation finishes.
-- Use animation "flying" if you want it to persist.
function sprite:on_animation_finished()
  
  fire:remove()
  
end

-- Returns whether a destructible is a bush.
local function is_bush(destructible)

  local sprite = destructible:get_sprite()
  if sprite == nil then
    return false
  end

  local sprite_id = sprite:get_animation_set()
  return sprite_id == "entities/destructibles/bush" or sprite_id:match("^entities/destructibles/bush_")
end

-- Returns whether a destructible is a bush.
local function is_ice_block(entity)

  local sprite = entity:get_sprite()
  if sprite == nil then
    return false
  end
  local sprite_id = sprite:get_animation_set()
  return sprite_id == "entities/destructibles/block_ice"
end

local function bush_collision_test(fire, other)

  if other:get_type() ~= "destructible" and other:get_type() ~= "custom_entity" then
    return false
  end
  if not (is_bush(other) or is_ice_block(other)) then
    return
  end
  -- Check if the fire box touches the one of the bush.
  -- To do this, we extend it of one pixel in all 4 directions.
  local x, y, width, height = fire:get_bounding_box()
  return other:overlaps(x - 1, y - 1, width + 2, height + 2)
end

-- Traversable rules.
fire:set_can_traverse("crystal", true)
fire:set_can_traverse("crystal_block", true)
fire:set_can_traverse("hero", true)
fire:set_can_traverse("jumper", true)
fire:set_can_traverse("stairs", false)
fire:set_can_traverse("stream", true)
fire:set_can_traverse("switch", true)
fire:set_can_traverse("teletransporter", true)
fire:set_can_traverse_ground("deep_water", true)
fire:set_can_traverse_ground("shallow_water", true)
fire:set_can_traverse_ground("hole", true)
fire:set_can_traverse_ground("lava", true)
fire:set_can_traverse_ground("prickles", true)
fire:set_can_traverse_ground("low_wall", true)
fire:set_can_traverse(true)
fire.apply_cliffs = true

-- Burn bushes.
fire:add_collision_test(bush_collision_test, function(fire, entity)
  local map = fire:get_map()

  if entity:get_type() == "destructible" or entity:get_type() == "custom_entity" then
    if not (is_bush(entity) or is_ice_block(entity)) then
      return
    end
    local bush = entity

    local bush_sprite = entity:get_sprite()
    if (is_bush(bush) and bush_sprite:get_animation() ~= "on_ground")
      or (is_ice_block(bush) and bush_sprite:get_animation() ~= "normal") then
      -- Possibly already being destroyed.
      return
    end
    if is_ice_block(bush) then --Remove ice blocks, but do not stop the movement.
      bush:melt()
      --audio_manager:play_sound("items/magic_powder_ignite")
      return
    end
    fire:stop_movement()
    sprite:set_animation("stopped")
    --audio_manager:play_sound("flame")


    -- TODO remove this when the engine provides a function destructible:destroy()
    local bush_sprite_id = bush_sprite:get_animation_set()
    local bush_x, bush_y, bush_layer = bush:get_position()
    local treasure = { bush:get_treasure() }
    if treasure ~= nil then
      local pickable = map:create_pickable({
        x = bush_x,
        y = bush_y,
        layer = bush_layer,
        treasure_name = treasure[1],
        treasure_variant = treasure[2],
        treasure_savegame_variable = treasure[3],
      })
    end

    audio_manager:play_sound(bush:get_destruction_sound())
    bush:remove()

    local bush_destroyed_sprite = fire:create_sprite(bush_sprite_id)
    local x, y = fire :get_position()
    bush_destroyed_sprite:set_xy(bush_x - x, bush_y - y)
    bush_destroyed_sprite:set_animation("destroy")
  end
end)

-- Going off animation and remove
function fire:extinguish()

  fire:stop_movement()
  sprite:set_animation("going_off")
  function sprite:on_animation_finished()
    fire:remove()
  end
end

-- Hurt enemies.
fire:add_collision_test("sprite", function(fire, entity)

  if entity:get_type() == "enemy" and not enemies_touched[entity] and entity:get_fire_reaction(entity) ~= "ignored" then
    local enemy = entity
    enemies_touched[enemy] = true
    local reaction = enemy:get_fire_reaction()

    -- Only remove the entity if fire has no effect on the enemy.
    if reaction == "protected" then
      fire:remove()
      return
    end

    -- Freeze the enemy and push it back.
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    enemy:set_invincible()
    local enemy_x, enemy_y, _ = enemy:get_position()
    local fire_x, fire_y, _ = fire:get_position()
    local movement = sol.movement.create("straight")
    movement:set_speed(256)
    movement:set_angle(math.atan2(fire_y - enemy_y, enemy_x - fire_x))
    movement:set_max_distance(32)
    movement:set_smooth(false)
    movement:start(enemy)

    -- Remove the projectile and make the enemy burn.
    fire:extinguish()
    local enemy_sprite = enemy:get_sprite()
    if enemy_sprite:has_animation("burning") then
      enemy_sprite:set_animation("burning")
    else
      local burning_sprite = enemy:create_sprite("entities/effects/flame", "burning")
      function burning_sprite:on_animation_finished()
        enemy:remove_sprite(burning_sprite)
      end
    end
    audio_manager:play_sound("items/sword_slash4") -- TODO
    
    -- Then call the enemy:receive_attack_consequence after a delay.
    sol.timer.start(sol.main, 1000, function()
      if enemy then
        enemy:restart() -- Restore damage settings before calling receive_attack_consequence().
        local is_pushed_back_when_hurt = enemy:is_pushed_back_when_hurt()
        enemy:set_pushed_back_when_hurt(false) -- Avoid pushing back again.
        enemy:receive_attack_consequence("fire", reaction)
        enemy:set_pushed_back_when_hurt(is_pushed_back_when_hurt)
      end
    end)
  end
end)

function fire:on_obstacle_reached()
  fire:extinguish()
end
