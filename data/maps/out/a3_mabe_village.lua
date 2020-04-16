-- Variables
local map = ...
local game = map:get_game()
local ball
local ball_shadow
local hero_is_alerted = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Digging
  map:set_digging_allowed(true)
  -- Entities
  map:init_map_entities()
  local item = game:get_item("magnifying_lens")
  local variant_lens = item:get_variant()
  -- Marin
  if not game:is_step_done("sword_obtained") or game:is_step_done("started_looking_for_marin") then
    marin:set_enabled(false)
  else
    marin:get_sprite():set_animation("waiting")
  end
  -- Kid 5
  if not game:is_step_last("started_looking_for_marin")  then
    kid_5:set_enabled(false)
  end  
  -- Grand ma
  if variant_lens == 10 then
    grand_ma:get_sprite():set_animation("nobroom")
  else 
    grand_ma:get_sprite():set_animation("walking")
  end
   -- Kids
  if not game:is_step_last("dungeon_1_completed") and not game:is_step_last("bowwow_dognapped") then
    map:create_ball(kid_1, kid_2)
    map:play_ball(kid_1, kid_2)
  else
    kid_1:get_sprite():set_animation("scared")
    kid_2:get_sprite():set_animation("scared")
    kid_1:get_sprite():set_ignore_suspend(true)
    kid_2:get_sprite():set_ignore_suspend(true)
    map:repeat_kids_scared_direction_check()
  end
  -- Thief detect
  local hero_is_thief_message = game:get_value("hero_is_thief_message")
  if hero_is_thief_message then
    game:start_dialog("maps.out.mabe_village.thief_message", function()
      game:set_value("hero_is_thief_message", false)
    end)
  end
  -- Kids scared
  if game:is_step_last("dungeon_1_completed") or game:is_step_last("bowwow_dognapped") then
    sol.timer.start(map, 500, function()
      map:init_music()
      return true
    end)  
  end
  if game:get_value("mabe_village_weathercook_statue_pushed") then
      push_weathercook_sensor:set_enabled(false)
      weathercock:set_enabled(false)
      weathercook_statue_1:set_position(616,232)
      weathercook_statue_2:set_position(616,248)
  end
    
end)

function map:on_opening_transition_finished(destination)
  
  -- Kids scared
  local x_hero, y_hero = hero:get_position()
  if game:is_step_last("dungeon_1_completed") or game:is_step_last("bowwow_dognapped") then
    map:init_music()
    if destination == library_2_A then
      if not hero_is_alerted then
        hero_is_alerted = true
      end
    elseif destination == nil and hero:get_direction() == 1 and x_hero < 160 and y_hero > 760 then
      map:launch_cinematic_1(kids_alert_position_hero_2)
      hero_is_alerted = true
    else
      if hero_is_alerted then
        hero_is_alerted = false
      end
    end
  end
end

-- Initialize the music of the map
function map:init_music()
  
  if marin ~= nil and marin:is_sing() then
    return
  end
  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  elseif game:is_step_last("dungeon_1_completed") and hero:get_distance(kids_alert_position_center) < 160 or game:is_step_last("bowwow_dognapped") and hero:get_distance(kids_alert_position_center) < 160 then
    audio_manager:play_music("26_bowwow_dognapped")
  else
    audio_manager:play_music("11_mabe_village")
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  -- Bowwow
  if game:is_step_done("dungeon_1_completed") and not game:is_step_done("bowwow_returned")  then
    bowwow:set_enabled(false)
  end

end

-- Kid's ball creation
function map:create_ball(player_1, player_2)

  local x_1,y_1, layer_1 = player_1:get_position()
  local x_2,y_2, layer_2 = player_2:get_position()
  local x_ball_shadow = x_1 
  local y_ball_shadow = y_1 + 8
  ball = map:create_custom_entity{
    name = "ball",
    x = x_1 + 8,
    y = y_1,
    width = 16,
    height = 24,
    direction = 0,
    layer = layer_1 + 1 ,
    sprite = "entities/misc/ball"
  }
  ball_shadow = map:create_custom_entity{
    name = "ball_shadow",
    x = x_ball_shadow,
    y = y_ball_shadow,
    width = 16,
    height = 24,
    direction = 0,
    layer = layer_1,
    sprite = "entities/shadows/ball"
  }
  
end

-- Kid's ball playing
function map:play_ball(player_1, player_2)
  
  ball:get_sprite():set_animation("thrown")
  player_1:get_sprite():set_animation("playing_1")
  player_2:get_sprite():set_animation("playing_2")
  local x_1,y_1, layer_1 = player_1:get_position()
  local x_2,y_2, layer_2 = player_2:get_position()
  local y_ball_shadow = y_1 + 8
  local distance = math.abs(x_2 - x_1) - 16
  local direction8 = 0
  if x_1 > x_2 then
    direction8 = 4
  end
  local movement = sol.movement.create("jump")
  movement:set_direction8(direction8)
  movement:set_distance(distance)
  movement:set_ignore_obstacles(true)
  movement:start(ball)
  function  movement:on_position_changed()
    local ball_x, ball_y, ball_layer = ball:get_position()
    ball_shadow:set_position(ball_x, y_ball_shadow)
  end
  function movement:on_finished()
    movement:stop()
    ball:get_sprite():set_animation("stopped")
    sol.timer.start(player_1, 500, function() 
      map:play_ball(player_2, player_1)
    end)
  end
  
end

-- Discussion with Fishman
function map:talk_to_fishman() 

  local fishman_sprite = fishman:get_sprite()
  local direction4 = fishman:get_direction4_to(hero)
  fishman_sprite:set_animation("stopped")
  fishman_sprite:set_direction(direction4)
  game:start_dialog("maps.out.mabe_village.fishman_1", function(answer)
    if answer == 1 then
      game:start_dialog("maps.out.mabe_village.fishman_2", function()
        fishman_sprite:set_animation("walking")
        fishman_sprite:set_direction(2)
      end)
      --TODO - CODING FISHING GAME
    else
      game:start_dialog("maps.out.mabe_village.fishman_3", function()
        fishman_sprite:set_animation("walking")
        fishman_sprite:set_direction(2)
      end)
    end
  end)

end

-- Discussion with Marin
function map:talk_to_marin() 

  local item_ocarina = game:get_item("ocarina")
  local item_melody_1 = game:get_item("melody_1")
  local variant_ocarina = item_ocarina:get_variant()
  local variant_melody_1 = item_melody_1:get_variant()
  if not game:is_step_done("tarin_saved") then
    game:start_dialog("maps.out.mabe_village.marin_1", game:get_player_name(), function()
      marin:sing_start()
    end)
  elseif not game:is_step_done("dungeon_2_completed") then
    game:start_dialog("maps.out.mabe_village.marin_2", game:get_player_name(), function()
      marin:sing_start()
    end)
  elseif variant_ocarina == 1 and variant_melody_1 == 0 then
    game:start_dialog("maps.out.mabe_village.marin_4", function()
      marin:launch_cinematic_marin_singing_with_hero(map)
    end)
  elseif game:is_step_done("dungeon_3_completed") then
    game:start_dialog("maps.out.mabe_village.marin_8")
  else
    game:start_dialog("maps.out.mabe_village.marin_3", game:get_player_name(), function()
      marin:sing_start()
    end)
  end

end

-- Discussion with Grand ma
function  map:talk_to_grand_ma()

  local item = game:get_item("magnifying_lens")
  local variant_lens = item:get_variant()
  local grand_ma_sprite = grand_ma:get_sprite()
  local x_grand_ma, y_grand_ma, layer_grand_ma = grand_ma:get_position()
  if variant_lens == 10 then
    game:start_dialog("maps.out.mabe_village.grand_ma_3", function(answer)
      if answer == 1 then
        hero:freeze()
        game:set_hud_enabled(false)
        game:set_pause_allowed(false)
        grand_ma_sprite:set_animation("brandish")
        local broom_entity = map:create_custom_entity({
          name = "brandish_broom",
          sprite = "entities/items",
          x = x_grand_ma,
          y = y_grand_ma - 24,
          width = 16,
          height = 16,
          layer = layer_grand_ma + 1,
          direction = 0
        })
        broom_entity:get_sprite():set_animation("magnifying_lens")
        broom_entity:get_sprite():set_direction(9)
        audio_manager:play_sound("items/fanfare_item_extended")
        sol.timer.start(grand_ma, 2000, function() 
          hero:unfreeze()
          game:set_hud_enabled(true)
          game:set_pause_allowed(true)
          broom_entity:remove()
          grand_ma_sprite:set_animation("walking")
          game:start_dialog("maps.out.mabe_village.grand_ma_5", function()
            hero:start_treasure("magnifying_lens", 11)
          end)
        end)
      else
        game:start_dialog("maps.out.mabe_village.grand_ma_4")
      end
    end)
  elseif variant_lens > 10 then
    game:start_dialog("maps.out.mabe_village.grand_ma_6")
  elseif not game:is_step_last("dungeon_1_completed") and not game:is_step_last("bowwow_dognapped") then  
    game:start_dialog("maps.out.mabe_village.grand_ma_1", function()
      grand_ma:get_sprite():set_direction(3)
    end)
  else
    game:start_dialog("maps.out.mabe_village.grand_ma_2", function()
      grand_ma:get_sprite():set_direction(3)
    end)
  end

end

-- Discussion with Kids
function map:talk_to_kids() 

  local rand = math.random(4)
  game:start_dialog("maps.out.mabe_village.kids_" .. rand)

end

-- Discussion with Kid 5
function map:talk_to_kid_5() 

  game:start_dialog("maps.out.mabe_village.kid_5_1")

end

function map:repeat_kids_scared_direction_check()

  local x_hero, y_hero = hero:get_position()
  local x_kid_1, y_kid_1 = kid_1:get_position()
  local x_kid_2, y_kid_2 = kid_2:get_position()
  local direction_kid_1 = 1
  local direction_kid_2 = 1
  if y_hero > y_kid_1 then
    direction_kid_1 = 3
  end
  if y_hero > y_kid_2 then
    direction_kid_2 = 3
  end
  kid_1:get_sprite():set_direction(direction_kid_1)
  kid_2:get_sprite():set_direction(direction_kid_2)
  sol.timer.start(map, 100, function() 
    map:repeat_kids_scared_direction_check()
  end)

end

-- Sensors events
function marin_sensor_1:on_activated()

  if marin:is_sing() then
    marin:sing_stop()
    map:init_music()    
  end

end

function marin_sensor_2:on_activated()

  if marin:is_sing() then
    marin:sing_stop()
    map:init_music()    
  end

end

function push_weathercook_sensor:on_activated_repeat()
  
    if hero:get_animation() == "pushing" and hero:get_direction() == 1 and game:get_ability("lift") == 2 then
      hero:freeze()
      hero:get_sprite():set_animation("pushing")
      push_weathercook_sensor:set_enabled(false)
      weathercock:set_enabled(false)
      audio_manager:play_sound("hero_pushes")
        local weathercook_x,weathercook_y = map:get_entity("weathercook_statue_1"):get_position()
        local weathercook_x_2,weathercook_y_2 = map:get_entity("weathercook_statue_2"):get_position()
        local i = 0
        sol.timer.start(map,50,function()
          i = i + 1
          weathercook_y = weathercook_y - 1
          weathercook_statue_1:set_position(weathercook_x, weathercook_y)
          weathercook_y_2 = weathercook_y_2 - 1
          weathercook_statue_2:set_position(weathercook_x_2, weathercook_y_2)
          if i < 32 then return true end
          audio_manager:play_sound("misc/secret2")
          hero:unfreeze()
          game:set_value("mabe_village_weathercook_statue_pushed",true)
        end)
    end
    
end

-- NPCs events
function grand_ma:on_interaction()

  map:talk_to_grand_ma()

end

function kid_1:on_interaction()

  if game:is_step_last("bowwow_dognapped") then
    game:start_dialog("maps.out.mabe_village.kids_alert_moblins")
  else
    map:talk_to_kids()
  end

end

function kid_2:on_interaction()

  if game:is_step_last("bowwow_dognapped") then
    game:start_dialog("maps.out.mabe_village.kids_alert_moblins")
  else
    map:talk_to_kids()
  end
  
end

function kid_3:on_interaction()

  map:talk_to_kids()

end

function kid_4:on_interaction()

  map:talk_to_kids()
end

function kid_5:on_interaction()

  map:talk_to_kid_5()

end

function marin:on_interaction()

  if marin:is_sing() == false then
    map:talk_to_marin()
  end

end

function fishman:on_interaction()

  map:talk_to_fishman()

end

-- Cinematics
-- This is the cinematic that kids are scared
function map:launch_cinematic_1(destination)
  
  local hero = map:get_hero()
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, kid_1, kid_2}
    }
    map:set_cinematic_mode(true, options)
    hero:set_animation("walking")
    if destination ~= nil then
      local m = sol.movement.create("target")
      m:set_target(destination)
      m:set_speed(40)
      m:set_ignore_obstacles(true)
      m:set_ignore_suspend(true)
      movement(m, hero)
    end  
    hero:set_animation("stopped")
    dialog("maps.out.mabe_village.kids_alert_moblins")
    hero:set_animation("scared")
    wait(1000)
    game:set_step_done("bowwow_dognapped")
    map:set_cinematic_mode(false)
  end)

end