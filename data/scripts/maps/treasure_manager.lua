local treasure_manager = {}

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local block_manager = require("scripts/maps/block_manager")
require("scripts/multi_events")

function treasure_manager:appear_chest_when_enemies_dead(map, enemy_prefix, chest)

  local function enemy_on_dead()
    local game = map:get_game()
    if not map:has_entities(enemy_prefix) then
      local chest_entity = map:get_entity(chest)
      local treasure, variant, savegame = chest_entity:get_treasure()
      if not savegame or savegame and not game:get_value(savegame) then
        self:appear_chest(map, chest, true)
      end
    end
  end

  -- Setup for each existing enemy that matches the prefix and ones created in the future.
  for enemy in map:get_entities(enemy_prefix) do
    enemy:register_event("on_dead", enemy_on_dead)
  end
  map:register_event("on_enemy_created", function(map, enemy)
    if string.match(enemy:get_name() or "", enemy_prefix) then
      enemy:register_event("on_dead", enemy_on_dead)
    end
  end)

end

function treasure_manager:appear_chest_when_horse_heads_upright(map, entity_prefix, chest)

  local function horse_head_on_finish_throw(horse_head)

    -- Make this horse head not liftable.
    horse_head:set_weight(-1)

    -- Get horse heads global states.
    local are_all_heads_thrown = true
    local are_all_heads_upright = true
    for entity in map:get_entities(entity_prefix) do
      if entity:get_weight() ~= -1 then
        are_all_heads_thrown = false
        break
      elseif entity:get_direction() ~= 1 then
        are_all_heads_upright = false
      end
    end

    -- If they all have been thrown.
    if are_all_heads_thrown then
      if are_all_heads_upright then
        -- Make the chest appear if they are upright.
        self:appear_chest(map, chest, true)
      else
        -- Else play error song and reset direction.
        audio_manager:play_sound("misc/error")
        sol.timer.start(500, function()
            for entity in map:get_entities(entity_prefix) do
              entity:set_direction(0)
            end
          end)
      end
      -- Make all horse heads liftable again.
      for entity in map:get_entities(entity_prefix) do
        entity:set_weight(0)
      end
    end
  end

  for entity in map:get_entities(entity_prefix) do
    entity:register_event("on_finish_throw", horse_head_on_finish_throw)
  end
end

function treasure_manager:appear_chest_when_holes_filled(map, vacuum_name, chest)

  local function vacuum_on_holes_filled(vacuum)
    self:appear_chest(map, chest, true)
  end

  local vacuum = map:get_entity(vacuum_name)
  vacuum:register_event("on_all_holes_filled", vacuum_on_holes_filled)
end

function treasure_manager:appear_chest_when_torches_lit(map, torches_prefix, chest)
  local function torch_on_lit(torch)
    for entity in map:get_entities(torches_prefix) do
      if not entity:is_lit() then
        return -- Remaining unlit torches.
      end
    end
    self:appear_chest(map, chest, true)
  end

  for torch in map:get_entities(torches_prefix) do
    torch:register_event("on_lit", torch_on_lit)
  end
end

function treasure_manager:appear_pickable_when_enemies_dead(map, enemy_prefix, pickable)

  local function enemy_on_dead()
    local game = map:get_game()
    if not map:has_entities(enemy_prefix) then
      local pickable_entity = map:get_entity(pickable)
      if pickable_entity ~= nil then
        local treasure, variant, savegame = pickable_entity:get_treasure()
        if not savegame or savegame and not game:get_value(savegame) then
          self:appear_pickable(map, pickable, true)
        end
      end
    end
  end

  -- Setup for each existing enemy that matches the prefix and ones created in the future.
  for enemy in map:get_entities(enemy_prefix) do
    enemy:register_event("on_dead", enemy_on_dead)
  end
  map:register_event("on_enemy_created", function(map, enemy)
    if string.match(enemy:get_name() or "", enemy_prefix) then
      enemy:register_event("on_dead", enemy_on_dead)
    end
  end)

end

function treasure_manager:appear_pickable_when_blocks_moved(map, block_prefix, pickable)
  block_manager:init_block_riddle(map, block_prefix, function()
      local game = map:get_game()
      local pickable_entity = map:get_entity(pickable)
      if pickable_entity ~= nil then
        local treasure, variant, savegame = pickable_entity:get_treasure()
        if not savegame or savegame and not game:get_value(savegame) then
          treasure_manager:appear_pickable(map, pickable, true)
        end
      end
    end)
end

function treasure_manager:appear_pickable_when_flying_tiles_dead(map, enemy_prefix, pickable)

  local function enemy_on_flying_tile_dead()
    local game = map:get_game()
    local pickable_appear = true
    for enemy in map:get_entities(enemy_prefix) do
      if enemy.state ~= "destroying" then
        pickable_appear = false
      end
    end
    if pickable_appear then
      local pickable_entity = map:get_entity(pickable)
      if pickable_entity ~= nil then
        local treasure, variant, savegame = pickable_entity:get_treasure()
        if not savegame or savegame and not game:get_value(savegame) then
          self:appear_pickable(map, pickable, true)
        end
      end
    end
  end

  for enemy in map:get_entities(enemy_prefix) do
    enemy:register_event("on_flying_tile_dead", enemy_on_flying_tile_dead)
  end

end

function treasure_manager:appear_pickable_when_holes_filled(map, vacuum_name, pickable)

  local function vacuum_on_holes_filled(vacuum)
    self:appear_pickable(map, pickable, true)
  end

  local vacuum = map:get_entity(vacuum_name)
  vacuum:register_event("on_all_holes_filled", vacuum_on_holes_filled)
end

function treasure_manager:appear_pickable_when_hit_by_arrow(map, entity_name, pickable)

  local function entity_on_hit_by_arrow(entity)
    self:appear_pickable(map, pickable, true)
  end

  local entity = map:get_entity(entity_name)
  entity:register_event("on_hit_by_arrow", entity_on_hit_by_arrow)
end

function treasure_manager:disappear_chest(map, chest)

  local chest = map:get_entity(chest)
  chest:set_enabled(false)

end

function treasure_manager:disappear_pickable(map, pickable)

  local pickable = map:get_entity(pickable)
  if pickable then
    pickable:set_enabled(false)
  end

end

function treasure_manager:appear_chest_if_savegame_exist(map, chest, savegame)

  local game = map:get_game()
  if savegame and game:get_value(savegame) then
    treasure_manager:appear_chest(map, chest, false)
  else
    treasure_manager:disappear_chest(map, chest)
  end

end


function treasure_manager:appear_chest(map, chest, sound)

  local chest = map:get_entity(chest)
  local game = map:get_game()
  chest:set_enabled(true)
  if sound ~= nil and sound ~= false then
    audio_manager:play_sound("misc/secret1")
  end

end

function treasure_manager:appear_pickable(map, pickable, sound)

  local pickable_entity = map:get_entity(pickable)
  if pickable_entity and not pickable_entity:is_enabled() then
    local game = map:get_game()
    map:start_coroutine(function()
        local options={
          entities_ignore_suspend={pickable,},
        }
        pickable_entity:set_enabled(true)
        pickable_entity:fall_from_ceiling(192, "hero/cliff_jump", function()
          if sound ~= nil and sound ~= false then
            audio_manager:play_sound("misc/secret1")
          end
        end)
      end)
  end
end



function treasure_manager:appear_heart_container_if_boss_dead(map)

  local game = map:get_game()
  local dungeon = game:get_dungeon_index()
  local savegame = "dungeon_" .. dungeon .. "_boss"
  if game:get_value(savegame) then
    print('ok')
    self:appear_pickable(map, "heart_container", false)
  end

end

function treasure_manager:get_instrument(map)

  local game = map:get_game()
  local dungeon = game:get_dungeon_index()
  local hero = map:get_entity("hero")
  local x_hero,y_hero, layer_hero = hero:get_position()
  local dungeon_infos = game:get_dungeon()
  local camera = map:get_camera()
  local surface = camera:get_surface()
  local opacity = 0
  local effect_model = require("scripts/gfx_effects/fade_to_white")
  local timer_1
  local timer_2
  local timer_3
  local timer_4
  local timer_5
  -- Create custom entities
  local effect_entity_1 = map:create_custom_entity({
      name = "effect",
      sprite = "entities/effects/sparkle_small",
      x = x_hero,
      y = y_hero - 24,
      width = 16,
      height = 16,
      layer = layer_hero,
      direction = 0
    })
  local effect_entity_2 = map:create_custom_entity({
      name = "effect",
      sprite = "entities/effects/sparkle_big",
      x = x_hero,
      y = y_hero - 24,
      width = 16,
      height = 16,
      layer = layer_hero + 1,
      direction = 0
    })
  local instrument_entity = map:create_custom_entity({
      name = "brandish_sword",
      sprite = "entities/items",
      x = x_hero,
      y = y_hero - 24,
      width = 16,
      height = 16,
      layer = layer_hero,
      direction = 0
    })
  local notes_1 = map:create_custom_entity{
    x = x_hero,
    y = y_hero - 24,
    layer = layer_hero,
    width = 24,
    height = 32,
    direction = 2,
    sprite = "entities/symbols/notes"
  }
  local notes_2 = map:create_custom_entity{
    x = x_hero,
    y = y_hero - 24,
    layer = layer_hero,
    width = 24,
    height = 32,
    direction = 0,
    sprite = "entities/symbols/notes"
  }
  instrument_entity:get_sprite():set_animation("instrument_" .. dungeon)
  instrument_entity:get_sprite():set_direction(0)
  notes_1:set_enabled(false)
  notes_2:set_enabled(false)
  effect_entity_2:set_enabled(false)
  local options = {
    entities_ignore_suspend = {hero, effect_entity_1, effect_entity_2, notes_1, notes_2, instrument_entity}
  }
  map:set_cinematic_mode(true, options)
  hero:set_animation("brandish")
  audio_manager:play_music("24_instrument_of_the_sirens")
  timer_1 = sol.timer.start(map, 7000, function()
      sol.audio.stop_music()
    end)
  timer_1:set_suspended_with_map(false)
  timer_2 = sol.timer.start(2000, function()
      effect_entity_1:remove()
      game:start_dialog("_treasure.instrument_" .. dungeon ..".1", function()
          local remaining_time = timer_1:get_remaining_time()
          timer_1:stop()
          sol.timer.start(map, remaining_time, function()
              audio_manager:play_music(dungeon_infos.music_instrument)
              timer_5 = sol.timer.start(map, 11000, function()
                  sol.audio.stop_music()
                end)
              timer_5:set_suspended_with_map(false)
              notes_1:set_enabled(true)
              notes_2:set_enabled(true)
              timer_3 = sol.timer.start(5000, function()
                  notes_1:remove()
                  notes_2:remove()
                  effect_entity_2:set_enabled(true)
                end)
              timer_3:set_suspended_with_map(false)
              timer_4 = sol.timer.start(8000, function()
                  effect_model.start_effect(surface, game, "in", false, function()
                      game:start_dialog("maps.dungeons.".. dungeon ..".indication", function()
                          local map_id = dungeon_infos["teletransporter_end_dungeon"]["map_id"]
                          local destination_name = dungeon_infos["teletransporter_end_dungeon"]["destination_name"]
                          hero:teleport(map_id, destination_name, "immediate")
                          game.map_in_transition = effect_model
                          map:set_cinematic_mode(false)
                        end)
                    end)
                end)
              timer_4:set_suspended_with_map(false)
            end)
        end)
    end)
  timer_2:set_suspended_with_map(false)
end

return treasure_manager