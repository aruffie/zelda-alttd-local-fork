local parchment = require("scripts/menus/parchment")

local enemy_manager = {}

enemy_manager.is_transported = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

function enemy_manager:on_enemies_dead(map, enemies_prefix, callback)

  local function enemy_on_dead()
    if not map:has_entities(enemies_prefix) then
      callback()
    end
  end

  -- Setup for each existing enemy that matches the prefix and ones created in the future.
  for enemy in map:get_entities(enemies_prefix) do
    enemy:register_event("on_dead", enemy_on_dead)
  end
  map:register_event("on_enemy_created", function(map, enemy)
    if string.match(enemy:get_name() or "", enemies_prefix) then
      enemy:register_event("on_dead", enemy_on_dead)
    end
  end)
  
end

function enemy_manager:set_weak_boo_buddies_when_at_least_on_torch_lit(map, torch_prefix, enemy_prefix)

  local function torch_on_lit()
    for enemy in map:get_entities(enemy_prefix) do
      if enemy.is_weak and not enemy:is_weak() then
        enemy:set_weak(true)
      end
    end
  end
  local function torch_on_unlit()
print("unlit")
    for torch in map:get_entities(torch_prefix) do
      if torch:is_lit() then
        return
      end
    end
    for enemy in map:get_entities(enemy_prefix) do
      enemy:set_weak(false)
    end
  end
  for torch in map:get_entities(torch_prefix) do
    torch:register_event("on_lit", function(torch)
      torch_on_lit()
    end)
    torch:register_event("on_unlit", function(torch)
      torch_on_unlit()
    end)
  end
  
end

function enemy_manager:execute_when_vegas_dead(map, enemy_prefix)

  local function enemy_on_symbol_fixed(enemy)
    local direction = enemy:get_sprite():get_direction()
    local all_immobilized = true
    local all_same_direction = true
    for vegas in map:get_entities(enemy_prefix) do
      local sprite = vegas:get_sprite()
      if not vegas:is_symbol_fixed() then
        all_immobilized = false
      end
      if vegas:get_sprite():get_direction() ~= direction then
        all_same_direction = false
      end
    end

    if not all_immobilized then
      return
    end

    sol.timer.start(map, 500, function()
        if not all_same_direction then
          audio_manager:play_sound("misc/error")
          for vegas in map:get_entities(enemy_prefix) do
            vegas:set_symbol_fixed(false)
          end
          return
        end
        audio_manager:play_sound("enemies/enemy_die")
        -- Kill them.
        for vegas in map:get_entities(enemy_prefix) do
          vegas:set_life(0)
        end
      end)
  end
  for enemy in map:get_entities(enemy_prefix) do
    local sprite = enemy:get_sprite()
    enemy.on_symbol_fixed = enemy_on_symbol_fixed
  end
end

function enemy_manager:create_teletransporter_if_small_boss_dead(map, sound)

  local game = map:get_game()
  local dungeon = game:get_dungeon_index()
  local savegame = "dungeon_" .. dungeon .. "_small_boss"
  if game:get_value(savegame) then
    for teletransporter in map:get_entities("midpoint_teletransporter") do
      teletransporter:set_enabled(true)
    end

    if sound ~= nil and sound ~= false then
      audio_manager:play_sound("misc/dungeon_teleport_appear")
    end
  end

end

-- Launch battle if small boss in the room are not dead
function enemy_manager:launch_small_boss_if_not_dead(map)

  local game = map:get_game()
  local door_prefix = "door_group_small_boss"
  local dungeon = game:get_dungeon_index()
  local dungeon_infos = game:get_dungeon()
  local savegame = "dungeon_" .. dungeon .. "_small_boss"
  local placeholder = "placeholder_small_boss"
  if game:get_value(savegame) then
    return false
  end
  local placeholder = map:get_entity(placeholder)
  local x,y,layer = placeholder:get_position()
  local game = map:get_game()
  placeholder:set_enabled(false)
  local enemy = map:create_enemy{
    name = "enemy_small_boss",
    breed = dungeon_infos["small_boss"]["breed"],
    direction = 2,
    x = x,
    y = y,
    layer = layer
  }
  enemy:register_event("on_dead", function()
      enemy:launch_small_boss_dead()
    end)
  for tile in map:get_entities("tiles_small_boss_") do
    local layer = tile:get_property('start_layer')
    tile:set_layer(layer)
  end
  map:close_doors(door_prefix)
  audio_manager:play_music("21_mini_boss_battle")

end

-- Launch battle if  boss in the room are not dead
function enemy_manager:launch_boss_if_not_dead(map)

  local game = map:get_game()
  local door_prefix = "door_group_boss"
  local dungeon = game:get_dungeon_index()
  local dungeon_infos = game:get_dungeon()
  local savegame = "dungeon_" .. dungeon .. "_boss"
  if game:get_value(savegame) then
    return false
  end
  local placeholder = map:get_entity("placeholder_boss")
  local x,y,layer = placeholder:get_position()
  placeholder:set_enabled(false)
  local enemy = map:create_enemy{
    name = "boss",
    breed = dungeon_infos["boss"]["breed"],
    direction = 2,
    x = x,
    y = y,
    layer = layer
  }
  enemy:register_event("on_dead", function()
      enemy:launch_boss_dead(door_prefix, savegame)
    end)
  map:close_doors(door_prefix)
  audio_manager:play_music("22_boss_battle")
  sol.timer.start(enemy, 1000, function()
      game:start_dialog("maps.dungeons." .. dungeon .. ".boss_welcome", function()
          
          game:set_suspended(true)

          -- Show parchment with dungeon name.
          local dungeon_index = game:get_dungeon_index()
          local line_1 = sol.language.get_dialog("maps.dungeons." .. dungeon_index .. ".boss_name").text
          local line_2 = sol.language.get_dialog("maps.dungeons." .. dungeon_index .. ".boss_description").text
          parchment:show(map, "boss", "top", 1500, line_1, line_2, nil, function()

            game:set_suspended(false)
            
            if enemy.launch_after_first_dialog then
              enemy:launch_after_first_dialog()
            end
          end)
        end)
    end)

end

return enemy_manager