-- Variables
local map = ...
local game = map:get_game()
local destructible_places = {}
local bis_destructible_places = {}
local raccoon_positions =  {1, 2, 1, 2 , 1 , 3, 1, 3, 4, 5, 6, 7, 6, 5, 4, 5, 6, 7, 6, 5, 4, 8}
local raccoon_index = 1
local raccoon_movement = false
map.overlay_angles = {
  3 * math.pi / 4,
  5 * math.pi / 4,
      math.pi / 4,
  7 * math.pi / 4
}
map.overlay_step = 1
map.raccoon_warning_done = false
map.fsa_no_clouds = true -- prevent fsa mode to draw clouds

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local fairy_manager = require("scripts/maps/fairy_manager")
local owl_manager = require("scripts/maps/owl_manager")

-- Utils functions
local function get_destructible_sprite_name(destructible)

  local sprite = destructible:get_sprite()
  return sprite ~= nil and sprite:get_animation_set() or ""

end

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Remove the big stone if you come from the secret cave
  if destination == stair_bombs_upgrade then secret_stone:set_enabled(false) end
  -- Tail key chest
  if game:get_value("forest_chest_1")  then
    forest_chest_1:set_open(true)
  end
   tarin:get_sprite():set_direction(3)
   tarin:bring_to_front()
   raccoon_invisible:set_enabled(false)
  -- Store destructibles
  for destructible in map:get_entities("destructible") do
    local x, y, layer = destructible:get_position()
    destructible_places[#destructible_places + 1] = {
      x = x,
      y = y,
      layer = layer,
      name = destructible:get_name(),
      treasure = { destructible:get_treasure() },
      sprite = get_destructible_sprite_name(destructible),
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
  -- Store bis destructibles
  for destructible in map:get_entities("bis_destructible") do
    local x, y, layer = destructible:get_position()
    bis_destructible_places[#bis_destructible_places + 1] = {
      x = x,
      y = y,
      layer = layer,
      name = destructible:get_name(),
      treasure = { destructible:get_treasure() },
      sprite = get_destructible_sprite_name(destructible),
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

  map:set_digging_allowed(true)
  fairy_manager:init_map(map, "fairy")
  map:set_overlay()
  map:init_tarin()
  owl_2:set_enabled(false)
  owl_3:set_enabled(false)
  if game:has_item("mushroom") or game:has_item("magic_powder_counter") and game:get_item("magic_powder_counter"):get_amount() > 0 then 
    mushroom:set_enabled(false)
  end
  if map:get_game():get_value("owl_2") == true then
    map:init_music()
  end

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("16_mysterious_forest")

end

map:register_event("on_draw", function(map, destination_surface)

 -- Make the overlay scroll with the camera, but slightly faster to make
  -- a depth effect.
  local camera_x, camera_y = map:get_camera():get_position()
  local overlay_width, overlay_height = map.overlay:get_size()
  local screen_width, screen_height = destination_surface:get_size()
  local x, y = camera_x + map.overlay_offset_x, camera_y + map.overlay_offset_y
  x, y = -math.floor(x * 1.5), -math.floor(y * 1.5)

  -- The overlay's image may be shorter than the screen, so we repeat its
  -- pattern. Furthermore, it also has a movement so let's make sure it
  -- will always fill the whole screen.
  x = x % overlay_width - 2 * overlay_width
  y = y % overlay_height - 2 * overlay_height

  local dst_y = y
  while dst_y < screen_height + overlay_height do
    local dst_x = x
    while dst_x < screen_width + overlay_width do
      -- Repeat the overlay's pattern.
      map.overlay:draw(destination_surface, dst_x, dst_y)
      dst_x = dst_x + overlay_width
    end
    dst_y = dst_y + overlay_height
  end

end,true)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("16_mysterious_forest")

end

function map:init_tarin()
 
  if game:is_step_done("tarin_saved") then
    tarin:remove()
    tarin_2:remove()
  else
    tarin:get_sprite():set_animation("waiting_raccoon")
    tarin_2:get_sprite():set_animation("waiting_raccoon")
    tarin_2:get_sprite():synchronize(tarin:get_sprite())
    tarin_2:set_enabled(false)
  end

end

-- Obtaining tail key
function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_item:get_name() == "tail_key" then
    game:set_step_done("dungeon_1_key_obtained")
  end

end

-- Chests events
function forest_chest_1:on_opened()

  hero:start_treasure("tail_key", 1, "forest_chest_1", function()
    if map:get_game():get_value("owl_3") ~= true and game:is_step_last("dungeon_1_key_obtained") then
      owl_manager:appear(map, 3, function()
      map:init_music()
      end)
    end
  end)

end

-- Sensors events
function owl_2_sensor:on_activated()

  if map:get_game():get_value("owl_2") ~= true then
      owl_manager:appear(map, 2, function()
        map:init_music()
      end)
    end

end

function lost_sensor:on_activated()

  if raccoon_movement or game:is_step_done("tarin_saved") then
    return
  end
  for key, destructible in pairs(destructible_places) do
      local d = map:get_entity(destructible["name"])
      if d ~= nil and d:get_sprite():get_animation() == "destroy" then
      local bis_destructible = map:get_entity("bis_" .. destructible["name"])
      local position_x, position_y = bis_destructible:get_position()
      bis_destructible:remove()
      d:set_position(position_x, position_y)
    else
        local is_exist = map:has_entity(destructible["name"])
        if (is_exist) then
          map:get_entity("bis_" .. destructible["name"]):set_enabled(true)
        else
          map:get_entity("bis_" .. destructible["name"]):set_enabled(false)
        end
    end
  end
  tarin:get_sprite():set_animation("laugh_raccoon")
  tarin_2:get_sprite():set_animation("laugh_raccoon")
  local x, y = hero:get_position()
  local sensor_x, sensor_y = self:get_position()
  local marker_x, marker_y = lost_destination:get_position()
  local diff_x, diff_y = marker_x - sensor_x, marker_y - sensor_y
  hero:set_position(x + diff_x, y + diff_y)
  audio_manager:play_sound("misc/mysterious_woods_lost")
  map.overlay_offset_x = map.overlay_offset_x - diff_x  -- Keep continuity of the overlay effect.
  map.overlay_offset_y = map.overlay_offset_y - diff_y
  -- Keep the exact same destructible entities so that the player cannot see a difference.
  tarin_2:set_enabled(true)
  tarin_2:get_sprite():fade_out(function()
    tarin_2:set_enabled(false)
    tarin:get_sprite():set_animation("waiting_raccoon")
    tarin_2:get_sprite():set_animation("waiting_raccoon")
  end)
  -- Put Tarin above the grass.
  tarin:bring_to_front()
  tarin_2:bring_to_front()

end

function raccoon_lost_warning_sensor:on_activated()

  if not game:is_step_done("tarin_saved") and not map.raccoon_warning_done then
    map.raccoon_warning_done = true
    game:start_dialog("maps.out.forest.raccoon_lost_warning", function() 
      tarin:get_sprite():set_direction(3)
      tarin_2:get_sprite():set_direction(3)
    end)
  end

end


-- Separator events
function separator:on_activating()

 -- Rebuild destructibles
  for key, destructible_place in pairs(destructible_places) do
    local is_exist = map:has_entity(destructible_place["name"])
    if (is_exist == false) then
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
    else
          map:get_entity(destructible_place["name"]):set_enabled(true)
    end
  end
  for key, bis_destructible_place in pairs(bis_destructible_places) do
    local is_exist = map:has_entity(bis_destructible_place["name"])
    if (is_exist == false) then
      local destructible = map:create_destructible({
        x = bis_destructible_place.x,
        y = bis_destructible_place.y,
        layer = bis_destructible_place.layer,
        name = bis_destructible_place.name,
        sprite = bis_destructible_place.sprite,
        destruction_sound = bis_destructible_place.destruction_sound,
        weight = bis_destructible_place.weight,
        can_be_cut = bis_destructible_place.can_be_cut,
        can_explode = bis_destructible_place.can_explode,
        can_regenerate = bis_destructible_place.can_regenerate,
        damage_on_enemies = bis_destructible_place.damage_on_enemies,
        ground = bis_destructible_place.ground,
      })
    else
          map:get_entity(bis_destructible_place["name"]):set_enabled(true)
    end
  end

end

function separator:on_activated()

  if tarin_2 ~= nil then
    tarin_2:set_enabled(false)
    map.raccoon_warning_done = false
  end
end

-- NPCs events
function tarin:on_interaction()

  if not game:is_step_done("tarin_saved") then
    game:start_dialog("maps.out.forest.raccoon", function()
      tarin:get_sprite():set_direction(3)
      tarin_2:get_sprite():set_direction(3)
    end)
  else
    game:start_dialog("maps.out.forest.tarin", function()
      tarin:get_sprite():set_direction(3)
    end)
    if tarin_2 then
     tarin_2:get_sprite():set_direction(tarin:get_sprite():get_direction())
    end
  end

end

function tarin:on_interaction_item(item)

  if game:is_step_done("tarin_saved") then
    return
  end
  if item:get_name() == "magic_powder_counter"  then
    map:launch_cinematic_1()
  end

end

function fairy_fountain:on_activated()

  local music_name = sol.audio.get_music()
  fairy_manager:launch_fairy_if_hero_not_max_life(map, "fairy", music_name)

end


-- Others functions
function change_movement_raccoon()

  local camera = map:get_camera()
  local value = raccoon_positions[raccoon_index]
  if value ~= nil then
    local entity = map:get_entity("racoon_position_" .. value)
    local movement = sol.movement.create("target")
    movement:set_speed(256)
    movement:set_target(entity)
    movement:set_ignore_obstacles(true)
    movement:set_ignore_suspend(true)
    movement:start(raccoon_invisible)
    function movement:on_position_changed()
      local x,y = raccoon_invisible:get_position()
      tarin:set_position(x,y)
    end
    function movement:on_finished()
      local direction4 = hero:get_direction4_to(tarin)
      hero:get_sprite():set_direction(direction4)
      audio_manager:play_sound("hero/bounce")
      raccoon_index = raccoon_index + 1
      change_movement_raccoon()
    end
  else
    local x, y, layer = tarin:get_position()
    audio_manager:play_sound("items/bomb_explode")
    map:create_explosion{
      layer = layer,
      x = x,
      y = y,
    }
    raccoon_invisible:remove()
    tarin:get_sprite():set_animation("tired_raccoon")
    local timer1 = sol.timer.start(map, 1000, function()
      game:set_step_done("tarin_saved")
      racoon_position_8:set_enabled(false)
      tarin_2:remove()
      game:start_dialog("maps.out.forest.raccoon_to_tarin", function()
        local movement1 = sol.movement.create("straight")
        movement1:set_angle(math.pi / 2)
        movement1:set_max_distance(150)
        movement1:set_speed(250)
        movement1:set_ignore_obstacles(true)
        movement1:set_ignore_suspend(true)
        movement1:start(camera, function()
          audio_manager:play_sound("misc/secret1")
          local timer2 = sol.timer.start(map, 1000, function()
            local movement2 = sol.movement.create("straight")
            movement2:set_angle(3 * math.pi / 2)
            movement2:set_speed(250)
            movement2:set_max_distance(198)
            movement2:set_ignore_obstacles(true)
            movement2:set_ignore_suspend(true)
            movement2:start(camera, function()
              map:init_music()
              local options = {
                entities_ignore_suspend = {hero, tarin}
              }
              map:set_cinematic_mode(false, options)
              camera:start_tracking(hero)
            end)
          end)
       end)
      end)
    end)
    timer1:set_suspended_with_map(false)
  end

end

function map:set_overlay()

  map.overlay = sol.surface.create("entities/effects/fog.png")
  map.overlay:set_opacity(96)
  map.overlay_offset_x = 0  -- Used to keep continuity when getting lost.
  map.overlay_offset_y = 0
  map.overlay_m = sol.movement.create("straight")
  map.restart_overlay_movement()

end

function map:restart_overlay_movement()

  map.overlay_m:set_speed(16) 
  map.overlay_m:set_max_distance(100)
  map.overlay_m:set_angle(map.overlay_angles[map.overlay_step])
  map.overlay_step = map.overlay_step + 1
  if map.overlay_step > #map.overlay_angles then
    map.overlay_step = 1
  end
  map.overlay_m:start(map.overlay, function()
    map:restart_overlay_movement()
  end)

end

-- Cinematics
-- This is the cinematic when Tarkin goes crazy.
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, tarin}
    }
    map:set_cinematic_mode(true, options)
    local sprite = tarin:get_sprite()
    local symbol = tarin:create_symbol_exclamation(true)
    sprite:set_animation("powder_raccoon")
    wait(500)
    sprite:set_animation("stopped_raccoon")
    raccoon_movement = true
    raccoon_invisible:set_enabled(true)
    audio_manager:stop_music()
    local camera = map:get_camera()
    camera:start_manual()
    hero:unfreeze()
    local m = sol.movement.create("straight")
    m:set_angle(math.pi / 2)
    m:set_max_distance(48)
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    movement(m, camera)
    sprite:set_animation("shocking_raccoon")
    symbol:remove()
    wait(1000)
    sprite:set_frame_delay(150)
    change_movement_raccoon()
  end)

end