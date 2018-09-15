local map = ...
local game = map:get_game()

-- Map events
function map:on_started(destination)

   local item = game:get_item("magnifying_lens")
  -- Digging
  map:set_digging_allowed(true)
  map:init_music()
  map:launch_small_bowwow()
  map:repeat_meow_meow_direction_check()
  if game:get_value("main_quest_step") == 8 or game:get_value("main_quest_step") == 9 then
    meow_meow:get_sprite():set_animation("panicked")
  end
  if item:get_variant() > 2 then
    small_bowwow_2:get_sprite():set_animation("ruban")
  end

end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  elseif game:get_value("main_quest_step") == 8 or game:get_value("main_quest_step") == 9  then
      sol.audio.play_music("maps/out/moblins_and_bow_wow")
  else
    sol.audio.play_music("maps/houses/inside")
  end

end

-- Function that forces Mrs Meow Meow to always watch the hero
function map:repeat_meow_meow_direction_check()

  local direction4 = meow_meow:get_direction4_to(hero)
  meow_meow:get_sprite():set_direction(direction4)
  sol.timer.start(map, 100, function() 
    map:repeat_meow_meow_direction_check()
  end)

end

-- Discussion with Mrs Meow Meow
function map:talk_to_meow_meow() 

  if game:get_value("main_quest_step") < 8 then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_1")
  elseif game:get_value("main_quest_step") == 8 or game:get_value("main_quest_step") == 9 then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_2")
  elseif game:get_value("main_quest_step") < 11 then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_3")
  elseif game:get_value("main_quest_step") == 11 then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_4", function()
      game:set_value("main_quest_step", 12)
    end)
  else
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_1")
  end

end

-- Discussion with Small bowwow 1
function map:talk_to_small_bowwow_1() 

  game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_1_1")

end

-- Discussion with Small bowwow 2
function map:talk_to_small_bowwow_2() 

    sol.audio.play_sound("bowwow")
    local item = game:get_item("magnifying_lens")
    local variant = item:get_variant()
    if variant == 2 then
      game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_2", function(answer)
        if answer == 1 then
            sol.audio.play_sound("bowwow")
            game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_4", function()
              small_bowwow_2:get_sprite():set_animation("ruban")
              hero:start_treasure("magnifying_lens", 3, "magnifying_lens_3")
              end)
        else
          game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_3")
        end
      end)
    elseif variant > 1 then
      game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_1")
    else
      game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_1")
    end

end

-- NPC events
function meow_meow:on_interaction()

      map:talk_to_meow_meow()

end

function small_bowwow_1:on_interaction()

      map:talk_to_small_bowwow_1()

end

function small_bowwow_2:on_interaction()

      map:talk_to_small_bowwow_2()

end

function small_bowwow_1:on_obstacle_reached(movement)

  map:set_animation_small_bowwow(self)

end

function small_bowwow_2:on_obstacle_reached(movement)

  map:set_animation_small_bowwow(self)

end

function small_bowwow_1:on_movement_finished(movement)

  map:set_animation_small_bowwow(self)

end

function small_bowwow_2:on_movement_finished(movement)

  map:set_animation_small_bowwow(self)

end

-- Others functions
function map:launch_small_bowwow()

  for entity in map:get_entities("small_bowwow") do
    map:set_animation_small_bowwow(entity)
  end

end

function map:set_animation_small_bowwow(entity)

  -- Random diagonal direction.
  local sprite = entity:get_sprite()
  local rand4 = math.random(4)
  local direction8 = rand4 * 2 - 1
  local angle = direction8 * math.pi / 4
  local m = sol.movement.create("straight")
  m:set_speed(48)
  m:set_angle(angle)
  m:set_max_distance(24 + math.random(96))
  m:start(entity)
  sprite:set_direction(rand4 - 1)
  sol.timer.stop_all(entity)

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end



