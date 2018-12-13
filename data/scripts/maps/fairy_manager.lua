local fairy_manager = {}

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Launch fairy if hero is injured
function fairy_manager:launch_fairy_if_hero_not_max_life(map, fairy_name, music_name)

    local game = map:get_game()
    local max_life = game:get_max_life()
    local life = game:get_life()
    if life < max_life then
      local hero = map:get_hero()
      local fairy = map:get_entity(fairy_name)
      hero:set_direction(1)
      fairy:set_enabled(true)
      local options = {
        entities_ignore_suspend = {fairy}
      }
      map:set_cinematic_mode(true, options)
      audio_manager:play_music("72_great_fairy_fountain")
      fairy:get_sprite():fade_in(100, function()
        game:start_dialog("scripts.meta.map.fairy", function()
          local hearts = {}
          fairy_manager:create_hearts(map, 0, fairy_name, hearts, music_name)
        end)
      end)
  end
        
end

-- Creates hearts around the hero and launch animation
function fairy_manager:create_hearts(map, index, fairy_name, hearts, music_name)

        local hero = map:get_hero()
        local x, y, layer = hero:get_position()
        x = x +4
        local radius = 40
        sol.timer.start(map, 150, function()
            if (index < 8) then
              local position_x = x
              local position_y = y
              if index == 0 then
                position_y = position_y - radius
              end
              if index == 1 then
                position_y = position_y - radius*math.sin(45 * math.pi / 180)
                position_x = position_x + radius*math.cos(45  * math.pi / 180)
              end
              if index == 2 then
                position_x = position_x + radius
              end
              if index == 3 then
                position_y = position_y + radius*math.sin(135 * math.pi / 180)
                position_x = position_x - radius*math.cos(135  * math.pi / 180)
              end
              if index == 4 then
                position_y = position_y + radius
              end
              if index == 5 then
                position_y = position_y - radius*math.sin(225 * math.pi / 180)
                position_x = position_x + radius*math.cos(225  * math.pi / 180)
              end
              if index== 6 then
                position_x = position_x - radius
              end
              if index == 7 then
                position_y = position_y + radius*math.sin(315 * math.pi / 180)
                position_x = position_x - radius*math.cos(315  * math.pi / 180)
              end
              hearts[index] = map:create_custom_entity({
                sprite = "hud/heart",
                x = position_x,
                y = position_y,
                width = 8,
                height = 8,
                layer = 2,
                direction = 0
              })
              index = index + 1
              audio_manager:play_sound("misc/great_fairy_heal")
              fairy_manager:create_hearts(map, index, fairy_name, hearts, music_name)
            else
              fairy_manager:animate_hearts(map, fairy_name, hearts, music_name)
            end
        end)
end


-- Animate Hearts and finished the care
function fairy_manager:animate_hearts(map, fairy_name, hearts, music_name)

  local radius = 40
  local hero = map:get_hero()
  for index = 0, 7, 1 do
    local heart  = hearts[index]
    local angle = 0
    if index == 0 then
      angle = 0
    end
    if index == 1 then
      angle = 45
    end
    if index == 2 then
      angle = 90
    end
    if index == 3 then
      angle = 135
    end
    if index == 4 then
      angle = 180
    end
    if index == 5 then
      angle = 225
    end
    if index== 6 then
      angle = 270
    end
    if index == 7 then
      angle = 315
    end
    local m = sol.movement.create("circle")
    m:set_center(hero, 4, 0)
    m:set_radius(radius)
    m:set_radius_speed(50)
    m:set_max_rotations(4)
    m:set_angle_speed(360)
    m:set_initial_angle(angle)
    m:set_ignore_obstacles(true)
    if index == 7 then
      m:start(heart, function() 
              fairy_manager:get_life_and_disappear(map, fairy_name, hearts, music_name)
      end)
    else
      m:start(heart)
    end
  end
end

function fairy_manager:get_life_and_disappear(map, fairy_name, hearts, music_name)

  local game = map:get_game()
  local max_life = game:get_max_life()
  local fairy = map:get_entity(fairy_name)
  local hero = map:get_hero()
  for index = 0, 7, 1 do
    local heart  = hearts[index]
    heart:remove()
  end
  game:add_life(max_life)
  audio_manager:play_sound("misc/great_fairy_vanish")
  fairy:get_sprite():fade_out(100, function()
    local options = {
      entities_ignore_suspend = {fairy}
    }
    map:set_cinematic_mode(false, options)
    sol.audio.play_music(music_name)
  end)
        
end


-- Init fairy
function fairy_manager:init_map(map, fairy_name)

  local fairy = map:get_entity(fairy_name)
  fairy:set_enabled(false)
        
end

return fairy_manager