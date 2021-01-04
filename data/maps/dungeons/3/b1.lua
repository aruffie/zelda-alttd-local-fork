-- Variables
local map = ...
local game = map:get_game()
local camera = map:get_camera()
local hero = map:get_hero()
local circle = math.pi * 2.0
local is_boss_active = false
local is_boss_room_entered = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-- Create a green zol and make it fall from ceiling.
local function create_falling_zol()

  local camera_x, camera_y, camera_width, camera_height = camera:get_bounding_box()
  local center_x, center_y = camera_x + camera_width / 2.0, camera_y + camera_height / 2.0
  local distance_max_from_center = 56
  local angle = math.random() * circle
  local x, y = center_x + math.cos(angle) * distance_max_from_center, center_y + math.sin(angle) * distance_max_from_center
  local layer = hero:get_layer()
  local zol = map:create_enemy({
    name = "boss_zol",
    breed = "boss/projectiles/zol",
    x = x,
    y = y,
    layer = layer,
    direction = 0
  })
  sol.timer.stop_all(zol)
  zol:stop_movement()

  -- Make the zol fall from ceiling then restart.
  local zol_sprite = zol:get_sprite()
  zol_sprite:set_xy(0, camera_y - y) -- Move the enemy to the start position right now to ensure it won't be visible before the beginning of the fall.
  zol_sprite:set_animation("jumping")
  zol:set_visible()
  zol:set_layer(map:get_max_layer())
  zol:start_throwing(zol, 750, y - camera_y, nil, nil, nil, function()
    zol:set_layer(layer)
    zol:restart()
  end)

  -- Make another gel fall from ceiling on dead.
  zol:register_event("on_dead", function(zol)
    sol.timer.start(map, 1000, function()
      if not is_boss_active then
        create_falling_zol()
      end
    end)
  end)
end

-- Map events
function map:on_started()

  -- Doors
  door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_3")
  treasure_manager:disappear_pickable(map, "pickable_small_key_7")
  treasure_manager:disappear_pickable(map, "pickable_small_key_8")
  treasure_manager:disappear_pickable(map, "pickable_small_key_9")
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_small_key_3")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_5_", "pickable_small_key_7")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_7_", "pickable_small_key_9")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_6_", "pickable_small_key_8")
  -- Separators
  separator_manager:init(map)
end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_3_big_treasure" then
    treasure_manager:get_instrument(map)
    game:set_step_done("dungeon_3_completed")
  end

end

-- Entering boss room.
sensor_1:register_event("on_activated", function()

  if game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss") or is_boss_room_entered then
    return
  end
  is_boss_room_entered = true
  game:start_dialog("maps.dungeons.3.boss_room_entered")
  
  -- Make two green zols fall from the ceiling until the hero bonk on a wall.
  local zol_number = 0
  sol.timer.start(map, 1000, function()
    create_falling_zol()
    zol_number = zol_number + 1
    return zol_number < 2
  end)

  -- Make the boss appear when the hero bonk on a wall.
  function hero:on_bonking()
    if map == hero:get_map() and not is_boss_active then
      is_boss_active = true
      enemy_manager:launch_boss_if_not_dead(map)
    end
  end
end)