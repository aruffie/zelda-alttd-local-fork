-- This script restores entities when there are separators in a map.
-- When taking separators prefixed by "auto_separator", the following entities are restored:
-- - Enemies prefixed by "auto_enemy".
-- - Destructibles prefixed by "auto_destructible".
-- - Blocks prefixed by "auto_block".
-- And the following entities are destroyed:
-- - Bombs.

local separator_manager = {}
local light_manager_fsa = require("scripts/lights/light_manager")
require("scripts/multi_events")

function separator_manager:init(map)

  local enemy_places = {}
  local unstable_floors_places = {}
  local destructible_places = {}
  local block_places = {}
  local entity_places = {}
  map.blocks_remaining = {}
  local game = map:get_game()


  -- Function called when a separator was just taken.
  local function separator_on_activated(separator)

    local hero = map:get_hero()
    -- Enemies.
    for enemy, enemy_place in pairs(enemy_places) do

      if enemy:get_breed() ~= "boss/skeleton" then
        -- First remove any enemy.
        if enemy:exists() then
          enemy:remove()
        end

        -- Re-create enemies in the new active region.
        if enemy:is_in_same_region(hero) then

          local new_enemy = map:create_enemy({ --TODO modifiy create_enemy to add enemy to light manager
              x = enemy_place.x,
              y = enemy_place.y,
              layer = enemy_place.layer,
              breed = enemy_place.breed,
              direction = enemy_place.direction,
              name = enemy_place.name,
              properties = enemy_place.properties
            })

          -- add enemy to the light manager of fsa mode, since it has been recreated
          light_manager_fsa:add_occluder(new_enemy)

          new_enemy:set_treasure(unpack(enemy_place.treasure))
          new_enemy.on_dead = enemy.on_dead  -- For door_manager.
          new_enemy.on_symbol_fixed = enemy.on_symbol_fixed -- For Vegas enemies
          if enemy.on_flying_tile_dead ~= nil then
            new_enemy.on_flying_tile_dead = enemy.on_flying_tile_dead -- For Flying tiles enemies
          end
        end
      end
    end

    -- Torches
    for torch in map:get_entities("auto_torch") do
      torch:set_lit(false)
    end

    -- Destroy bombs.
    game:get_item("bombs_counter"):remove_bombs_on_map()
  end

  -- Function called when a separator is being taken.
  local function separator_on_activating(separator)

    local hero = map:get_hero()

    -- Blocks.
    for _, block_place in ipairs(block_places) do
      local block=block_place.block
      if not block:is_in_same_region(hero) then
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

    -- custom entities.
    for _, entity_place in ipairs(entity_places) do
      local entity=entity_place.entity
      if not entity:is_in_same_region(hero) then
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

    --Reset counters for block riddles
    for block_group in pairs(map.blocks_remaining) do 
      if block_group then
        map.blocks_remaining[block_group]=map:get_entities_count(block_group)
      end
    end


    --Unstable floors
    for _, floor_place in ipairs(unstable_floors_places) do
      local floor=floor_place.floor
      if not floor:exists() then
        if not floor:is_in_same_region(hero) then
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

    -- Destructibles.
    for _, destructible_place in ipairs(destructible_places) do
      local destructible = destructible_place.destructible

      if not destructible:exists() then
        -- Re-create destructibles in all regions except the active one.
        if not destructible:is_in_same_region(hero) then
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
              ground = destructible_place.ground,
            })
          -- We don't recreate the treasure.
          destructible_place.destructible = destructible
        end
      end
    end

    -- Disable all enemies when leaving a zone.
    for enemy in map:get_entities_by_type("enemy") do
      if enemy:is_in_same_region(hero) and enemy:get_breed() ~= "boss/skeleton" then
        enemy:remove()
      end
    end
  end

  for separator in map:get_entities("auto_separator") do
    separator:register_event("on_activating", separator_on_activating)
    separator:register_event("on_activated", separator_on_activated)
  end
-- Store the position and properties of enemies.
  for enemy in map:get_entities_by_type("enemy") do
    local x, y, layer = enemy:get_position()
    enemy_places[enemy] = {
      x = x,
      y = y,
      layer = layer,
      breed = enemy:get_breed(),
      direction = enemy:get_sprite():get_direction(),
      name = enemy:get_name(),
      treasure = { enemy:get_treasure() },
      properties = enemy:get_properties()
    }

    local hero = map:get_hero()
    if not enemy:is_in_same_region(hero) and enemy:get_breed() ~= "boss/skeleton" then
      enemy:remove()
    end
  end

  local function get_entity_sprite_name(entity)
    local sprite = entity:get_sprite()
    return sprite ~= nil and sprite:get_animation_set() or ""
  end

-- Store the position and properties of custom entities
  for entity in map:get_entities("auto_entity") do
    local x, y, layer = entity:get_position()
    local width, height = entity:get_size()

    entity_places[#entity_places + 1] = {
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
-- Store the position and properties of unstable floors.
  for floor in map:get_entities("floor") do
    local x, y, layer = floor:get_position()
    local width, height = floor:get_size()
    if floor:get_type()=="dynamic_tile" then
      unstable_floors_places[#unstable_floors_places + 1] = {
        x = x,
        y = y,
        layer = layer,
        name = floor:get_name(),
        pattern = floor:get_pattern_id(),
        width=width,
        height=height,
        tileset=floor:get_tileset(),
        properties=floor:get_properties(),
        floor=floor, 
      }
    elseif floor:get_type()=="custom_entity" then
      unstable_floors_places[#unstable_floors_places + 1] = {
        x = x,
        y = y,
        layer = layer,
        name = floor:get_name(),
        sprite=get_entity_sprite_name(floor), 
        width=width,
        height=height,
        model=floor:get_model(),
        direction=floor:get_direction(), 
        tiled=floor:is_tiled(),
        properties=floor:get_properties(),
        floor=floor,
      }
    end
  end
-- Store the position and properties of blocks.
  for block in map:get_entities("auto_block") do
    local x, y, layer = block:get_position()
    block_places[#block_places + 1] = {
      x = x,
      y = y,
      layer = layer,
      name = block:get_name(),
      sprite = get_entity_sprite_name(block),
      pushable=block:is_pushable(),
      pullable=block:is_pullable(),
      max_moves=block:get_max_moves(),
      properties=block:get_properties(),
      block = block,
    }
  end
-- Store the position and properties of destructibles.
  for destructible in map:get_entities("auto_destructible") do
    local x, y, layer = destructible:get_position()
    destructible_places[#destructible_places + 1] = {
      x = x,
      y = y,
      layer = layer,
      name = destructible:get_name(),
      treasure = { destructible:get_treasure() },
      sprite = get_entity_sprite_name(destructible),
      destruction_sound = destructible:get_destruction_sound(),
      weight = destructible:get_weight(),
      can_be_cut = destructible:get_can_be_cut(),
      can_explode = destructible:get_can_explode(),
      can_regenerate = destructible:get_can_regenerate(),
      damage_on_enemies = destructible:get_damage_on_enemies(),
      ground = destructible:get_modified_ground(),
      destructible = destructible,
    }
  end

  for enemy in map:get_entities_by_type("enemy") do
    enemy:register_event("on_dead", function()
        if not enemy:get_property("can_resurrect") then
          enemy_places[enemy] = nil
        end
      end)
  end

end

return separator_manager

