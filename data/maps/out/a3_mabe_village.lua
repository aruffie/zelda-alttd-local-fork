-- Variables
local map = ...
local game = map:get_game()
local marin_song = false
local marin_and_link_song = false
local ball
local ball_shadow
local ball_is_launch = false
local hero_is_alerted = false
local marin_notes = nil
local marin_notes_2 = nil
local hero_notes = nil
local hero_notes_2 = nil

-- Map events
function map:on_started(destination)

  map:init_music()
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  local item = game:get_item("magnifying_lens")
  local variant_lens = item:get_variant()
  -- Signs
  shop_sign_2:get_sprite():set_animation("crane_sign")
  -- Marin
  if game:get_value("main_quest_step") < 4 or game:get_value("main_quest_step") > 20  then
    marin:set_enabled(false)
  else
    marin:get_sprite():set_animation("waiting")
  end
  -- Kid 5
  if game:get_value("main_quest_step") ~= 21  then
    kid_5:set_enabled(false)
  end  
  -- Grand ma
  if variant_lens == 10 then
    grand_ma:get_sprite():set_animation("nobroom")
  else 
    grand_ma:get_sprite():set_animation("walking")
  end
   -- Kids
  if map:get_game():get_value("main_quest_step") ~= 8 and map:get_game():get_value("main_quest_step") ~= 9 then
    map:create_ball(kid_1, kid_2)
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
  --Weathercock statue pushed
  if game:get_value("mabe_village_weathercook_statue_pushed") then
      push_weathercook_sensor:set_enabled(false)
      weathercock:set_enabled(false)
      weathercook_statue_1:set_position(616,232)
      weathercook_statue_2:set_position(616,248)
  end
-- Kids scared
  if map:get_game():get_value("main_quest_step") == 8 or map:get_game():get_value("main_quest_step") == 9 then
    sol.timer.start(map, 500, function()
        map:init_music()
        if  hero:get_distance(kids_alert_position_center) < 60 then
          if not hero_is_alerted then
            hero:get_sprite():set_direction(3)
            hero_is_alerted = true
              local hero = map:get_hero()
              hero:freeze()
              game:start_dialog("maps.out.mabe_village.kids_alert_moblins", function()
                  self:get_game():set_value("main_quest_step", 9)
                  hero:unfreeze()
              end)
          end
        else
          if hero_is_alerted then
            hero_is_alerted = false
          end
        end
        return true
     end)
  end
    
end

-- Initialize the music of the map
function map:init_music()
  
  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  elseif map:get_game():get_value("main_quest_step") == 8 and hero:get_distance(kids_alert_position_center) < 160 or map:get_game():get_value("main_quest_step") == 9 and hero:get_distance(kids_alert_position_center) < 160 then
    sol.audio.play_music("maps/out/moblins_and_bow_wow")
  else
    if marin_song then
      sol.audio.play_music("maps/out/song_of_marin")
    elseif marin_and_link_song then
      sol.audio.play_music("maps/out/song_of_marin_and_link")
    else
      sol.audio.play_music("maps/out/mabe_village")
    end
  end

end

function map:marin_alone_sing()

  marin_song = true
  map:marin_sing_start()
  map:init_music()

end

function map:marin_and_hero_sing()

  marin_and_link_song = true
  local hero = map:get_hero()
  hero:freeze()
  game:set_hud_enabled(false)
  game:set_pause_allowed(false)
  map:marin_sing_start()
  local timer1 = sol.timer.start(marin, 7500, function()
    hero:set_direction(3)
    map:marin_sing_stop()
    map:hero_sing_start()
    local timer2 = sol.timer.start(marin, 8000, function()
      map:marin_sing_start()
      local timer3 = sol.timer.start(marin, 17500, function()
        map:marin_sing_stop()
        map:hero_sing_stop()
        sol.audio.stop_music()
        local direction4 = hero:get_direction4_to(marin)
        hero:set_direction(direction4)
        game:start_dialog("maps.out.mabe_village.marin_5", function(answer)
          if answer == 1 then
            local timer4 = sol.timer.start(marin, 500, function()
              marin_and_link_song = false
              map:init_music()
            end)
            local item_melody = game:get_item("melody_1")
            item_melody:set_variant(1)
            item_melody:brandish(function()
              --game:set_value("main_quest_step", 19) 
              game:set_hud_enabled(true)
              game:set_pause_allowed(true)
              game:start_dialog("maps.out.mabe_village.marin_7")
            end)
          else
            game:start_dialog("maps.out.mabe_village.marin_6", function()
              map:marin_and_hero_sing()
            end)
          end
        end)
      end)
    end)
  end)
  map:init_music()

end

function map:marin_sing_start()

  local x,y,layer = marin:get_position()
  marin_notes = map:create_custom_entity{
    x = x,
    y = y - 16,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 0,
    sprite = "entities/notes"
  }
  marin_notes_2 = map:create_custom_entity{
    x = x,
    y = y - 16,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 2,
    sprite = "entities/notes"
  }
  marin:get_sprite():set_animation("singing")

end

function map:marin_sing_stop()

    marin:get_sprite():set_animation("waiting")
    if marin_notes ~= nil then
      marin_notes:remove()
    end
    if marin_notes_2 ~= nil then
      marin_notes_2:remove()
    end

end

function map:hero_sing_start()

  local hero = map:get_hero()
  local x ,y ,layer = hero:get_position()
  hero_notes = map:create_custom_entity{
    x = x,
    y = y - 16,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 0,
    sprite = "entities/notes"
  }
  hero_notes_2 = map:create_custom_entity{
    x = x,
    y = y - 16,
    layer = layer + 1,
    width = 24,
    height = 32,
    direction = 2,
    sprite = "entities/notes"
  }
  hero:set_animation("playing_ocarina")

end

function map:hero_sing_stop()

    hero:set_animation("stopped")
    if hero_notes ~= nil then
      hero_notes:remove()
    end
    if hero_notes_2 ~= nil then
      hero_notes_2:remove()
    end

end


function map:init_map_entities()
 
  -- Bowwow
  if game:get_value("main_quest_step") > 7 and game:get_value("main_quest_step") < 12  then
    bowwow:set_enabled(false)
  end

end


-- Ball animation
function map:create_ball(player_1, player_2)

local x_1,y_1, layer_1 = player_1:get_position()
  local x_2,y_2, layer_2 = player_2:get_position()
  x_1 = x_1 + 8
  x_2 = x_2 - 8
  local x_ball_shadow = x_1 
  local y_ball_shadow = y_1 + 8
  local radius =  (x_2 - x_1) / 2
  local center_y = y_1
  local center_x = x_1 + radius
  ball = map:create_custom_entity{
    x = x_1,
    y = y_1,
    width = 16,
    height = 24,
    direction = 0,
    layer = 1 ,
    sprite= "entities/ball"
  }
  ball_shadow = map:create_custom_entity{
    x = x_ball_shadow,
    y = y_ball_shadow,
    width = 16,
    height = 24,
    direction = 0,
    layer = 0,
    sprite= "entities/ball_shadow"
  }
  movement = sol.movement.create("circle")
  movement:set_radius(radius)
  movement:set_angle_speed(180)
  movement:set_initial_angle(0)
  movement:set_ignore_obstacles(true)
  movement:set_clockwise(false)
  movement:set_center(center_x, center_y)
  function  movement:on_position_changed()
      local ball_x, ball_y, ball_layer = ball:get_position()
      ball_shadow:set_position(ball_x, y_ball_shadow)
  end
  sol.timer.start(player_1, 10, function()
      local ball_x, ball_y, ball_layer = ball:get_position()
      if ball_x > x_1 - 2 and  ball_x < x_1 + 2 then
        movement:set_clockwise(not movement:is_clockwise())
      end
      if ball_x > x_2 - 2 and  ball_x < x_2 + 2 then
        movement:set_clockwise(not movement:is_clockwise())
      end
    return true
  end)
  movement:start(ball)
end

function map:generate_ball_movement(player_1, player_2, clockwise)
  
  local x_1,y_1, layer_1 = player_1:get_position()
  local x_2,y_2, layer_2 = player_2:get_position()
  local x_ball_shadow = x_1 
  local y_ball_shadow = y_1 + 8
  local radius =  (x_2 - x_1) / 2
  local center_y = y_1
  local center_x = x_1 + radius
  local movement = sol.movement.create("circle")
  movement:set_radius(radius)
  movement:set_angular_speed(math.pi)
  movement:set_angle_from_center(0)
  movement:set_ignore_obstacles(true)
  movement:set_clockwise(clockwise)
  movement:set_center(center_x, center_y)
  movement:set_max_rotations(1)
  function movement:on_position_changed()
    --local ball_x, ball_y, ball_layer = ball:get_position()
    --ball_shadow:set_position(ball_x, y_ball_shadow)
  end 
  
  return movement
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
  if game:get_value("main_quest_step") <= 4 then
    game:start_dialog("maps.out.mabe_village.marin_1", game:get_player_name(), function()
      map:marin_alone_sing()
    end)
  elseif game:get_value("main_quest_step") < 11 then
    game:start_dialog("maps.out.mabe_village.marin_2", game:get_player_name(), function()
      map:marin_alone_sing()
    end)
  elseif variant_ocarina == 1 and variant_melody_1 == 0 then
    game:start_dialog("maps.out.mabe_village.marin_4", function()
      map:marin_and_hero_sing()
    end)
  elseif game:get_value("main_quest_step") > 18 then
    game:start_dialog("maps.out.mabe_village.marin_8")
  else
    game:start_dialog("maps.out.mabe_village.marin_3", game:get_player_name(), function()
      map:marin_alone_sing()
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
          sol.audio.play_sound("treasure")
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
    elseif map:get_game():get_value("main_quest_step") ~= 8 and map:get_game():get_value("main_quest_step") ~= 9 then
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
function  map:talk_to_kids() 

  local rand = math.random(4)
  game:start_dialog("maps.out.mabe_village.kids_" .. rand)

end

-- Discussion with Kid 5
function map:talk_to_kid_5() 

  game:start_dialog("maps.out.mabe_village.kid_5_1")

end

function map:repeat_kids_scared_direction_check()

  local directionkid1 = kid_1:get_direction4_to(hero)
  local directionkid2 = kid_2:get_direction4_to(hero)
  kid_1:get_sprite():set_direction(directionkid1)
  kid_2:get_sprite():set_direction(directionkid2)
  sol.timer.start(map, 100, function() 
    map:repeat_kids_scared_direction_check()
  end)
end

-- Sensor events
function marin_sensor_1:on_activated()

    marin_song = false
    map:init_music()
    map:marin_sing_stop()

end

function marin_sensor_2:on_activated()

    marin_song = false
    map:init_music()
    map:marin_sing_stop()

end

function push_weathercook_sensor:on_activated_repeat()
    if hero:get_animation() == "pushing" and hero:get_direction() == 1 and game:get_ability("lift") == 2 then
      hero:freeze()
      hero:get_sprite():set_animation("pushing")
      push_weathercook_sensor:set_enabled(false)
      weathercock:set_enabled(false)
      sol.audio.play_sound("hero_pushes")
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
          sol.audio.play_sound("secret_2")
          hero:unfreeze()
          game:set_value("mabe_village_weathercook_statue_pushed",true)
        end)
    end
end

-- NPC events
function grand_ma:on_interaction()

  map:talk_to_grand_ma()

end

function kid_1:on_interaction()

  map:talk_to_kids()

end

function kid_2:on_interaction()

  map:talk_to_kids()

end

function kid_3:on_interaction()

    if map:get_game():get_value("main_quest_step") == 9 then
      game:start_dialog("maps.out.mabe_village.kids_alert_moblins")
    else
      map:talk_to_kids()
    end

end

function kid_4:on_interaction()

    if map:get_game():get_value("main_quest_step") == 9 then
      game:start_dialog("maps.out.mabe_village.kids_alert_moblins")
    else
      map:talk_to_kids()
    end

end

function kid_5:on_interaction()

  map:talk_to_kid_5()

end

function marin:on_interaction()

    if marin_song == false then
      map:talk_to_marin()
    end

end

function fishman:on_interaction()

      map:talk_to_fishman()

end