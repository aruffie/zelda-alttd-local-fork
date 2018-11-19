-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  -- Castle door
  if game:get_value("castle_door_is_open") then
    castle_door:set_enabled(false)
  end
  -- Baton and bridge
  if game:get_value("main_quest_step") < 14 then
    baton:set_enabled(false)
    bridge:set_enabled(false)
  else
    monkey:set_enabled(false)
  end
  if variant > 4 then
    baton:set_enabled(false)
  end
  -- Golden leaves
  if pickable_golden_leaf_1 ~= nil then
    pickable_golden_leaf_1:set_enabled(false)
  end
  if pickable_golden_leaf_2 ~= nil then
    pickable_golden_leaf_2:set_enabled(false)
  end
  
end

-- Discussion with monkey
function map:talk_to_monkey() 

  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if game:get_value("main_quest_step") < 12 then
    game:start_dialog("maps.out.kanalet_castle.monkey_1")
  elseif game:get_value("main_quest_step") < 14 then
      if variant == 4 then
        game:start_dialog("maps.out.kanalet_castle.monkey_3", function(answer) 
          if answer == 1 then
            game:start_dialog("maps.out.kanalet_castle.monkey_4", function()
              map:launch_cinematic_1()
            end)
          else
            game:start_dialog("maps.out.kanalet_castle.monkey_2")
          end
        end)
      else
        game:start_dialog("maps.out.kanalet_castle.monkey_2")
      end
  end

end

-- Monkey leave bridge
function map:monkey_leave_bridge()

  local x, y, layer = monkey:get_position()
  for i = 1, 9 do
    local monkey_entity = map:get_entity("monk_" .. i)
    local monkey_sprite = monkey_entity:get_sprite()
    monkey_sprite:set_animation("walking")    
    monkey_sprite:set_direction(1)    
    local sprite = monkey_entity:get_sprite()
    local movement = sol.movement.create("target")
    movement:set_target(x, y - 300)
    movement:set_speed(120)
    movement:set_ignore_obstacles(true)
    movement:start(monkey_entity)
    function movement:on_finished()
      monkey_entity:remove()
    end
  end
  local movement = sol.movement.create("target")
  movement:set_target(x, y - 300)
  movement:set_speed(80)
  movement:set_ignore_obstacles(true)
  movement:start(monkey)
  function movement:on_finished()
    monkey:remove()
    hero:unfreeze()
    game:set_hud_enabled(true)
    game:set_pause_allowed(true)
    game:set_value("main_quest_step", 14) 
  end
  
end

-- Enemies events
mad_bomber_1:register_event("on_dead", function()
    
  if not game:get_value("golden_leaf_1") and pickable_golden_leaf_1 ~= nil  then
    pickable_golden_leaf_1:set_enabled(true)
  end
  
end)

crow_1:register_event("on_dead", function()
    
  if not game:get_value("golden_leaf_1") and pickable_golden_leaf_2 ~= nil  then
    pickable_golden_leaf_2:set_enabled(true)
  end
  
end)

-- NPCs events
function monkey:on_interaction()

  map:talk_to_monkey()

end

-- Cinematics
-- This is the cinematic that monkeys build the bridge
function map:launch_cinematic_1()
  
  local hero = map:get_hero()
  local options = {
    entities_ignore_suspend = {hero, monkey}
  }
  map:set_cinematic_mode(true, options)
  local x, y, layer = monkey:get_position()
  local animation_finished = false
  audio_manager:play_music("31_kiki_bridge")
  local timer_music = sol.timer.start(monkey, 15000, function()
    if animation_finished == false then
      sol.audio.stop_music()
    end
  end)
  timer_music:set_suspended_with_map(false)
  local movement_monkey = sol.movement.create("target")
  movement_monkey:set_target(monkey_0)
  movement_monkey:set_speed(60)
  movement_monkey:set_ignore_obstacles(true)
  movement_monkey:set_ignore_suspend(true)
  movement_monkey:start(monkey)
  function movement_monkey:on_finished()
    monkey:get_sprite():set_animation("stopped")
    movement_monkey:stop()
  end
  local num_monkeys_arrived = 0
  for i = 1, 10 do
    local x_random = math.random(-128, 128)
    local timer = math.random(1000)
    if i == 10 then
      timer = 14000
    end
    local x_monkey = x + x_random
    local y_monkey = y + 150
    local direction = 0
    if x_monkey < x then
      direction = 0
    else
      direction = 2
    end
    sol.timer.start(map, timer, function()
      local target_entity = map:get_entity("monkey_" .. i)
      local monkey_entity = map:create_custom_entity({
        name = "monk_"..i,
        sprite = "npc/monkey_brown",
        x = x_monkey,
        y = y_monkey,
        width = 24,
        height = 32,
        layer = layer,
        direction = direction
      })
      local monkey_sprite = monkey_entity:get_sprite()
      monkey_sprite:set_animation("jumping")       
      local movement = sol.movement.create("target")
      movement:set_target(target_entity)
      movement:set_speed(100)
      movement:set_ignore_obstacles(true)
      movement:set_ignore_suspend(true)
      movement:start(monkey_entity)
      function movement:on_finished()
        num_monkeys_arrived = num_monkeys_arrived + 1
        if i == 10 then
          monkey_entity:remove()
        end
        if num_monkeys_arrived == 9 then
          local timer = sol.timer.start(monkey, 9000, function()
            bridge:set_enabled(true)
            baton:set_enabled(true)
            sol.audio.play_sound("secret_1")
            monkey:get_sprite():set_animation("stopped")
            monkey:get_sprite():set_direction(3)
            game:start_dialog("maps.out.kanalet_castle.monkey_5", function()
              animation_finished = true
              map:init_music()
              map:monkey_leave_bridge()
              map:get_entity("monkey"):get_sprite():set_animation("jumping")
              map:get_entity("monkey"):get_sprite():set_direction(1)
              map:set_cinematic_mode(false)
            end)
          end)
          timer:set_suspended_with_map(false)
        end
      end
    end)
  end

end
