local treasure_manager = {}

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

function treasure_manager:appear_chest_when_enemies_dead(map, enemy_prefix, chest)
    
  local function enemy_on_dead()
    local game = map:get_game()
    if not map:has_entities(enemy_prefix) then
       local chest_entity = map:get_entity(chest)
       local treasure, variant, savegame = chest_entity:get_treasure()
      if  not savegame or savegame and not game:get_value(savegame) then
         self:appear_chest(map, chest, true)
      end
    end
  end

  for enemy in map:get_entities(enemy_prefix) do
    enemy:register_event("on_dead", enemy_on_dead)
  end

end

function treasure_manager:appear_pickable_when_enemies_dead(map, enemy_prefix, pickable)
    
  local function enemy_on_dead()
    local game = map:get_game()
    if not map:has_entities(enemy_prefix) then
       local pickable_entity = map:get_entity(pickable)
        if pickable_entity ~= nil then
          local treasure, variant, savegame = pickable_entity:get_treasure()
          if  not savegame or savegame and not game:get_value(savegame) then
           self:appear_pickable(map, pickable, true)
          end
        end
    end
  end

  for enemy in map:get_entities(enemy_prefix) do
    enemy:register_event("on_dead", enemy_on_dead)
  end

end

function treasure_manager:appear_pickable_when_blocks_moved(map, block_prefix, pickable)

  local remaining = map:get_entities_count(block_prefix)
  local game = map:get_game()
  local function block_on_moved()
    remaining = remaining - 1
    if remaining == 0 then
      local pickable_entity = map:get_entity(pickable)
      if pickable_entity ~= nil then
        local treasure, variant, savegame = pickable_entity:get_treasure()
        if  not savegame or savegame and not game:get_value(savegame) then
         self:appear_pickable(map, pickable, true)
        end
      end
   end
  end
  for block in map:get_entities(block_prefix) do
    enemy:register_event("on_moved", block_on_moved)
  end

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

    local pickable = map:get_entity(pickable)
    if pickable and not pickable:is_enabled() then
      local game = map:get_game()
      pickable:set_enabled(true)
      if sound ~= nil and sound ~= false then
        audio_manager:play_sound("misc/secret1")
      end
    end

end


function treasure_manager:appear_heart_container_if_boss_dead(map)

    local game = map:get_game()
    local dungeon = game:get_dungeon_index()
    local savegame = "dungeon_" .. dungeon .. "_boss"
    if game:get_value(savegame) then
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