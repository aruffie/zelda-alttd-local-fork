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

  for enemy in map:get_entities(enemies_prefix) do
    enemy:register_event("on_dead", enemy_on_dead)
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

      local function create_teletransporter(teletransporter_suffix)
        placeholder_teletransporter = map:get_entity("teletransporter_" .. teletransporter_suffix)
        if placeholder_teletransporter then
          local teletransporter_x,  teletransporter_y,  teletransporter_layer = placeholder_teletransporter:get_position()
          teletransporter = map:create_custom_entity{
            x = teletransporter_x,
            y = teletransporter_y,
            width = teletransporter_suffix == "A" and 24 or 16,
            height = teletransporter_suffix == "A" and 24 or 16,
            direction = 0,
            sprite = "entities/misc/teletransporter",
            layer = teletransporter_layer,
            sound = teletransporter_suffix == "A" and "teletransporter" or nil
          }
          teletransporter:add_collision_test("center", function(teletransporter_source, hero)
            local hero_sprite = hero:get_sprite()
            if enemy_manager.is_transported  == false and hero:get_type() == "hero" then
              enemy_manager.is_transported  = true
              game:set_suspended(true)
              game:set_pause_allowed(false)
              teletransporter:get_sprite():set_ignore_suspend(true)
              hero:set_position(teletransporter:get_position())
              hero_sprite:set_ignore_suspend(true)
              hero_sprite:set_animation("teleporting")
              audio_manager:play_sound("misc/dungeon_teleport")
              function hero_sprite:on_animation_finished(animation)
                if animation == "teleporting" then
                  game:set_suspended(false)
                  game:set_pause_allowed(true)
                  teletransporter:get_sprite():set_ignore_suspend(false)
                  hero_sprite:set_ignore_suspend(false)
                  -- Get destination map infos if available, else teleport on the same map.
                  local destination_map = map:get_id()
                  local dungeon_info = game:get_dungeon()
                  if dungeon_info and dungeon_info.teletransporter_sall_boss then
                    local map_info = dungeon_info.teletransporter_sall_boss
                    destination_map = teletransporter_suffix == "A" and map_info.map_id_B or map_info.map_id_A
                  end
                  local destination_name = "teletransporter_destination_" .. (teletransporter_suffix == "A" and "B" or "A")
                  hero:teleport(destination_map, destination_name)
                  enemy_manager.is_transported  = false
                end
              end
            end
          end)
        end
      end

      create_teletransporter("A")
      create_teletransporter("B")
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
    game:start_dialog("maps.dungeons." .. dungeon .. ".boss_welcome")
        
end

return enemy_manager