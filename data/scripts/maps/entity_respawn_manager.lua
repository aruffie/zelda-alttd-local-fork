-- This script restores entities when called
-- When taking separators prefixed by "auto_separator", the following entities are restored:
-- - Enemies prefixed by "auto_enemy".
-- - Destructibles prefixed by "auto_destructible".
-- - Blocks prefixed by "auto_block".
-- And the following entities are destroyed:
-- - Bombs.

local entity_respawn_manager = {}
local light_manager_fsa = require("scripts/lights/light_manager")
local light_manager=require("scripts/maps/light_manager")
require("scripts/multi_events")

function entity_respawn_manager:init(map)

  local saved_entities={
    enemies = {},
    unstable_floors = {},
    torches = {}, 
    destructibles = {},
    moving_platforms = {},
    twin_platforms = {},
    blocks = {},
    custom_entities = {},
  }
  local game=map:get_game()

  -- Clean the saved_entities.enemies table on given enemy dead, if needed.
  local function clean_on_dead(enemy)

    local function on_dead(enemy)
      if not enemy:get_property("can_resurrect") then
        saved_entities.enemies[enemy] = nil
      end
    end

    enemy:register_event("on_dead", function(enemy)
      on_dead(enemy)
    end)
  end

  -- Recreate a previously existing enemy.
  local function recreate_enemy(enemy)

    local enemy_place = saved_entities.enemies[enemy]
    local new_enemy = map:create_enemy({ -- TODO modifiy create_enemy to add enemy to light manager
      x = enemy_place.x,
      y = enemy_place.y,
      layer = enemy_place.layer,
      breed = enemy_place.breed,
      animation_set = enemy_place.animation_set,
      direction = enemy_place.direction,
      name = enemy_place.name,
      properties = enemy_place.properties
    })
    clean_on_dead(new_enemy)

    -- Add enemy to the light manager of fsa mode, since it has been recreated
    light_manager_fsa:add_occluder(new_enemy)
    new_enemy:set_treasure(unpack(enemy_place.treasure))

    -- TODO Replace event recopy by dynamic setup.
    new_enemy.on_symbol_fixed = enemy.on_symbol_fixed -- For Vegas enemies
    if enemy.on_flying_tile_dead ~= nil then
      new_enemy.on_flying_tile_dead = enemy.on_flying_tile_dead -- For Flying tiles enemies
    end

    -- Remove the initial enemy once the new one is created.
    enemy:remove()

    return new_enemy
  end

  -- Function called when a separator was just taken.
  function entity_respawn_manager:respawn_enemies(map)

    -- Enable and restart all enemies in the new active region, or recreate them if not exists anymore and should respawn.
    local recreated_enemies = {}
    for enemy, enemy_place in pairs(saved_entities.enemies) do
      if enemy:is_in_same_region(map:get_hero()) then
        if enemy:exists() and enemy:get_sprite():get_animation() ~= "killed" then -- TODO Find another way to reset a dying enemy without recreate it to preserve events and name.
          enemy:set_enabled(true)
          enemy:set_position(enemy_place.x, enemy_place.y, enemy_place.layer)
          enemy:set_life(enemy_place.life)
        else
          recreated_enemies[enemy] = recreate_enemy(enemy)
        end
      end
    end

    -- Update the saved entities table after the loop on the actual table.
    for enemy, new_enemy in pairs(recreated_enemies) do
      saved_entities.enemies[new_enemy] = saved_entities.enemies[enemy]
      saved_entities.enemies[enemy] = nil
    end
  end

  function entity_respawn_manager:reset_torches(map)
    local hero=map:get_hero()
    local found=false

    for _, torch in pairs(saved_entities.torches) do
      torch:set_lit(false)
      if torch:is_in_same_region(hero) then --TODO take account of dungeon 6 pre-boss torches
--        debug_print ("found "..(torch:get_name() or "<something>")..". XY: ", torch:get_position())
        found=true
      end
    end
    light_manager:update_light_level(map)

    if map.torches_remaining~=nil then
      for torch_group, remaining in pairs(map.torches_remaining) do
        map.torches_remaining[torch_group]=map:get_entities_count(torch_group) 
      end
    end
  end
  function entity_respawn_manager:reset_twin_platforms()
    for _, platform in pairs(saved_entities.twin_platforms) do
      platform:reset()
    end
  end
  function entity_respawn_manager:reset_moving_platforms()
    for _, platform in pairs(saved_entities.moving_platforms) do
      platform:reset()
    end
  end

  function entity_respawn_manager:reset_bombs()
    -- Destroy bombs.
    game:get_item("bombs_counter"):remove_bombs_on_map()
  end

  -- Blocks.
  function entity_respawn_manager:reset_blocks(map)
    for _, block_place in ipairs(saved_entities.blocks) do
      local block=block_place.block
      if not block:is_in_same_region(map:get_hero()) then
        if block:exists() then
          -- Reset blocks in regions no longer visible.
          block:reset()
          block.is_moved = false
        else
          local block=map:create_block({
              name=block_place.name, 
              x=block_place.x,
              y=block_place.y,
              layer=block_place.layer,
              direction=block_place.direction,
              sprite=block_place.sprite, 
              pushable=block_place.pushable, 
              pullable=block_place.pullable,
              max_moves=block_place.max_moves,
              properties=block_place.properties,
            })
        end
      end
    end
    --Reset counters for block riddles
    if map.blocks_remaining then
      for block_group in pairs(map.blocks_remaining) do 
        if block_group then
          map.blocks_remaining[block_group]=map:get_entities_count(block_group)
        end
      end
    end
  end

  -- custom entities.
  function entity_respawn_manager:reset_custom_entities(map)
    for _, entity_place in ipairs(saved_entities.custom_entities) do
      local entity=entity_place.entity
      if not entity:is_in_same_region(map:get_hero()) then
        if entity:exists() then
          entity:remove()
        end

        local entity=map:create_custom_entity({
            name=entity_place.name,
            direction=entity_place.direction,
            x=entity_place.x,
            y=entity_place.y,
            layer=entity_place.layer,
            sprite=entity_place.sprite,
            width=entity_place.width,
            model=entity_place.model,
            height=entity_place.height,
            properties=entity_place.properties,
          })
        entity:set_tiled(entity_place.tiled)
        entity_place.entity=entity
      end
    end
  end

  function entity_respawn_manager:reset_unstable_floors(map)
    --Unstable floors
    for _, floor_place in ipairs(saved_entities.unstable_floors) do
      local floor=floor_place.floor
      if not floor:exists() then
        if not floor:is_in_same_region(map:get_hero()) then
          if floor:get_type()=="dynamic_tile" then

            local floor=map:create_dynamic_tile({
                name=floor_place.name,
                x=floor_place.x,
                y=floor_place.y,
                layer=floor_place.layer,
                pattern=floor_place.pattern, 
                width=floor_place.width,
                height=floor_place.height,
                properties=floor_place.properties,
              })
            floor:set_tileset(floor_place.tileset)
            floor_place.floor=floor

          elseif floor:get_type()=="custom_entity" then
            local floor=map:create_custom_entity({
                name=floor_place.name,
                direction=floor_place.direction,
                x=floor_place.x,
                y=floor_place.y,
                layer=floor_place.layer,
                sprite=floor_place.sprite,
                width=floor_place.width,
                model=floor_place.model,
                height=floor_place.height,
                properties=floor_place.properties,
              })
            floor:set_tiled(floor_place.tiled)
            floor_place.floor=floor
          end
        end
      end
    end
  end

  function entity_respawn_manager:reset_destructibles(map)
    -- Destructibles.
    for _, destructible_place in ipairs(saved_entities.destructibles) do
      local destructible = destructible_place.destructible

      if not destructible:exists() then
        -- Re-create destructibles in all regions except the active one.
        if not destructible:is_in_same_region(map:get_hero()) then
          local destructible = map:create_destructible({
              x = destructible_place.x,
              y = destructible_place.y,
              layer = destructible_place.layer,
              name = destructible_place.name,
              sprite = destructible_place.sprite,
              destruction_sound = destructible_place.destruction_sound,
              weight = destructible_place.weight,
              can_be_cut = destructible_place.can_be_cut,
              can_explode = destructible_place.can_explode,
              can_regenerate = destructible_place.can_regenerate,
              damage_on_enemies = destructible_place.damage_on_enemies,
              properties=destructible_place.properties,
              ground = destructible_place.ground,
            })
          -- We don't recreate the treasure.
          destructible_place.destructible = destructible
          destructible:bring_to_back() -- Workaround : Ensure the created destructible is under a possible invisible entity such as lights, to let it liftable.
        end
      end
    end
  end

  function entity_respawn_manager:reset_enemies(map)

    -- Disable all enemies when leaving a zone. Disable instead of remove to not trigger map puzzles based on enemy removal.
    for enemy in map:get_entities_by_type("enemy") do
      if saved_entities.enemies[enemy] and enemy:is_in_same_region(map:get_hero()) then
        sol.timer.stop_all(enemy)
        enemy:stop_movement()
        enemy:set_enabled(false)
      end
    end
  end


  local function get_entity_sprite_name(entity)
    local sprite = entity:get_sprite()
    return sprite ~= nil and sprite:get_animation_set() or ""
  end

  -- Store the position and properties of given enemy.
  local function save_enemy(enemy)

    if not string.match(enemy:get_breed() or "", "projectiles") then -- Workaround : Don't save projectile enemies that may be created inside main enemy scripts.
      local x, y, layer = enemy:get_position()
      local sprite = enemy:get_sprite()
      saved_entities.enemies[enemy] = {
        x = x,
        y = y,
        layer = layer,
        breed = enemy:get_breed(),
        animation_set = enemy:get_sprite():get_animation_set(),
        direction = sprite and sprite:get_direction() or 0,
        name = enemy:get_name(),
        treasure = { enemy:get_treasure() },
        properties = enemy:get_properties(),
        life = enemy:get_life()
      }
      clean_on_dead(enemy)
    end

    if not enemy:is_in_same_region(map:get_hero()) then
      sol.timer.stop_all(enemy)
      enemy:stop_movement()
      enemy:set_enabled(false)
    end
  end

  function entity_respawn_manager:save_entities(map)
    for entity in map:get_entities() do
      if entity:exists() then
        local x, y, layer = entity:get_position()
        local width, height = entity:get_size()
        local entity_type=entity:get_type()
        --debug_print ("checking in a(n) ".. entity_type)
        
        if entity_type=="enemy" then
          save_enemy(entity)
        end

        if entity_type=="custom_entity" then
          local model=entity:get_model()
          if model=="unstable_floor" then
            local tile_name=entity:get_name().."_unstable_associate_"
            local associated_tile=map:get_entity(tile_name)
            -- Store the position and properties of unstable floors.
            if associated_tile then
              local x,y,layer=associated_tile:get_position()
              saved_entities.unstable_floors[#saved_entities.unstable_floors + 1] = {
                x = x,
                y = y,
                layer = layer,
                name = associated_tile:get_name(),
                pattern = associated_tile:get_pattern_id(),
                width=width,
                height=height,
                tileset=associated_tile:get_tileset(),
                properties=associated_tile:get_properties(),
                floor=associated_tile, 
              }
            else 
              debug_print("Warning : could not find unstable floor tile "..tile_name)
            end

            saved_entities.unstable_floors[#saved_entities.unstable_floors + 1] = {
              x = x,
              y = y,
              layer = layer,
              name = entity:get_name(),
              sprite=get_entity_sprite_name(entity), 
              width=width,
              height=height,
              model=entity:get_model(),
              direction=entity:get_direction(), 
              tiled=entity:is_tiled(),
              properties=entity:get_properties(),
              floor=entity,
            }
          end
          
          if model=="platform_moving" then
            saved_entities.moving_platforms[#saved_entities.moving_platforms + 1] = entity
          end
          if model=="platform_balance" then
            saved_entities.twin_platforms[#saved_entities.twin_platforms + 1] = entity
          end

          if entity:get_model()=="torch" then
            saved_entities.torches[#saved_entities.torches + 1] = entity
          end 
        end

        if entity_type=="block" and entity:is_pushable() then
          local x, y, layer = entity:get_position()
          saved_entities.blocks[#saved_entities.blocks + 1] = {
            x = x,
            y = y,
            layer = layer,
            name = entity:get_name(),
            sprite = get_entity_sprite_name(entity),
            pushable=entity:is_pushable(),
            pullable=entity:is_pullable(),
            max_moves=entity:get_max_moves(),
            properties=entity:get_properties(),
            block = entity,
          }
        end
        -- Store the position and properties of destructibles.
        if entity_type=="destructible" then
          saved_entities.destructibles[#saved_entities.destructibles + 1] = {
            x = x,
            y = y,
            layer = layer,
            name = entity:get_name(),
            treasure = { entity:get_treasure() },
            sprite = get_entity_sprite_name(entity),
            destruction_sound = entity:get_destruction_sound(),
            weight = entity:get_weight(),
            can_be_cut = entity:get_can_be_cut(),
            can_explode = entity:get_can_explode(),
            can_regenerate = entity:get_can_regenerate(),
            damage_on_enemies = entity:get_damage_on_enemies(),
            ground = entity:get_modified_ground(),
            properties=entity:get_properties(),
            destructible = entity,
          }
        end

        if entity:get_property("auto_respawn")=="true" then
        -- Store the position and properties of custom entities
          if entity_type=="custom_entity" and entity:get_model()~="unstable_floor" and entity:get_model()~="torch" and entity:get_model()~= "platform_moving" and entity:get_model()~= "platform_balance" then
            saved_entities.custom_entities[#saved_entities.custom_entities + 1] = {
              x = x,
              y = y,
              layer = layer,
              name = entity:get_name(),
              sprite=get_entity_sprite_name(entity), 
              width=width,
              height=height,
              model=entity:get_model(),
              direction=entity:get_direction(), 
              tiled=entity:is_tiled(),
              properties=entity:get_properties(),
              entity=entity,
            }
            if not entity:is_in_same_region(map:get_hero()) then
              entity:remove()
            end

          end
        end
      end
    end
  end

  function entity_respawn_manager:respawn_entities(map)
    self:reset_bombs()
    self:reset_blocks(map)
    self:reset_custom_entities(map)
    self:reset_moving_platforms()
    self:reset_twin_platforms()
    self:reset_unstable_floors(map)
    self:reset_destructibles(map)
    self:reset_enemies(map) -- originally triggered by separator:on_activating
    self:respawn_enemies(map) -- originally triggered by separator:on_activated
    self:reset_torches(map)
    self:reset_bombs()
  end
end

return entity_respawn_manager

