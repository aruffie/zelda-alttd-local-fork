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
    --print "NO SPRITE FOUND. ABORT"
    return false
  end
  --print "SPRITE OK"
  local sprite_id = sprite:get_animation_set()
  return sprite_id == "entities/destructibles/block_ice"
end

local function bush_collision_test(fire, other)

  if other:get_type() ~= "destructible" and other:get_type() ~= "custom_entity" then
    --print "NOT THE DESIRED TYPE. EXIT"
    return false
  end
  --print "TYPE OK"
  --print("is bush ? "..(is_bush(other) and "yes" or "no")..", is ice block ? "..(is_ice_block(other) and "yes" or "no"))
  if not (is_bush(other) or is_ice_block(other)) then
    --print "NOT A BUSH OR AN ICE BLOCK. EXIT"
    return
  end
  -- print "BUSH OR ICE BLOCK DETECTED"
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
  print "TEST OK"
  local map = fire:get_map()

  if entity:get_type() == "destructible" or entity:get_type() == "custom_entity" then
    if not (is_bush(entity) or is_ice_block(entity)) then
      print "NOT A COMPATIBLE BLOCK. EXIT"
      return
    end
    local bush = entity

    local bush_sprite = entity:get_sprite()
    if (is_bush(bush) and bush_sprite:get_animation() ~= "on_ground")
      or (is_ice_block(bush) and bush_sprite:get_animation() ~= "normal") then
      -- Possibly already being destroyed.
      print "ALREADY DESTROYED. EXIT"
      return
    end
    if is_ice_block(bush) then --Remove ice blocks, but do not stop the movement.
      print ("MELT ME DOWN !")
      bush:remove()
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

-- Hurt enemies.
fire:add_collision_test("sprite", function(fire, entity)

  if entity:get_type() == "enemy" then
    local enemy = entity
    if enemies_touched[enemy] then
      -- If protected we don't want to play the sound repeatedly.
      return
    end
    enemies_touched[enemy] = true
    local reaction = enemy:get_fire_reaction(enemy_sprite)
    enemy:receive_attack_consequence("fire", reaction)

    sol.timer.start(fire, 200, function()
      fire:remove()
    end)
  end
  if entity:get_type() == "enemy" then
    local enemy = entity
    if enemies_touched[enemy] then
      -- If protected we don't want to play the sound repeatedly.
      return
    end
    enemies_touched[enemy] = true
    local reaction = enemy:get_fire_reaction(enemy_sprite)
    enemy:receive_attack_consequence("fire", reaction)

    sol.timer.start(fire, 200, function()
      fire:remove()
    end)
  end
end)

function fire:on_obstacle_reached()
  fire:remove()
end
