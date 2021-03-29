-- Variables
local map = ...
local game = map:get_game()
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local weather_manager = require("scripts/maps/weather_manager")

-- Create a custom entity.
local function create_custom_entity(x, y, sprite)
  return map:create_custom_entity({
    direction = 0,
    x = x,
    y = y,
    layer = hero:get_layer(),
    width = 16,
    height = 16,
    sprite = sprite
  })
end

-- Start a movement on an entity.
local function start_straight_movement(entity, speed, angle, distance, on_finished_callback)

  local movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_max_distance(distance)
  movement:set_angle(angle)
  movement:set_ignore_obstacles(true)

  function movement:on_finished()
    if on_finished_callback then
      on_finished_callback()
    end
  end
  movement:start(entity)
end

-- Make the entity start jumping.
local function start_jumping(entity, duration, height, angle, speed, on_finished_callback)

  local movement
  local sprite = entity:get_sprite()

  -- Schedule an update of the sprite vertical offset by frame.
  local elapsed_time = 0
  sol.timer.start(entity, 10, function()

    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * height)
      return true
    else
      sprite:set_xy(0, 0)
      if movement and entity:get_movement() == movement then
        movement:stop()
      end

      -- Call events once jump finished.
      if on_finished_callback then
        on_finished_callback()
      end
    end
  end)

  -- Move the entity on-floor if requested.
  if angle then
    movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:start(entity)
  
    return movement
  end
end

-- Start the boss cutscene.
local function start_boss_cinematic()

  hero:freeze()

  -- Create characters.
  local x, y, layer = placeholder_boss:get_position()
  local grim_creeper = create_custom_entity(x, y, "enemies/boss/evil_eagle/grim_creeper")
  local minion_1 = create_custom_entity(x - 24, y - 24, "enemies/boss/grim_creeper/minion")
  local minion_2 = create_custom_entity(x + 24, y - 24, "enemies/boss/grim_creeper/minion")
  local eagle = create_custom_entity(368, 40, "enemies/boss/evil_eagle/eagle")
  local eagle_sprite = eagle:get_sprite()
  grim_creeper:get_sprite():set_animation("waiting")

  -- Start the actual cinematic.
  sol.timer.start(map, 100, function()
    map:set_cinematic_mode(true, {entities_ignore_suspend = {grim_creeper, minion_1, minion_2, eagle}})
    game:set_suspended(false) -- Workaround: Don't use the game suspension of the cinematic mode.
    sol.timer.start(map, 1500, function()
      game:start_dialog("maps.dungeons.7.boss_threat")
      sol.timer.start(map, 1500, function()
        eagle_sprite:set_animation("rushing")
        eagle_sprite:set_direction(2)
        start_straight_movement(eagle, 240, math.pi, 416, function()
          sol.timer.start(map, 1000, function()
            eagle:set_position(-48, 82)
            eagle_sprite:set_direction(0)
            start_straight_movement(eagle, 240, 0, 416, function()
              sol.timer.start(map, 1000, function()
                eagle:set_position(368, 124)
                eagle_sprite:set_direction(2)
                start_straight_movement(eagle, 240, math.pi, 160, function()
                  eagle_sprite:set_animation("flying")
                  start_straight_movement(eagle, 120, math.pi, 48, function()
                    start_straight_movement(minion_1, 120, math.pi * 0.9, 240, function()
                      minion_1:remove()
                    end)
                    start_straight_movement(minion_2, 120, math.pi * 0.9, 240, function()
                      minion_2:remove()
                    end)
                    sol.timer.start(map, 500, function()
                      start_jumping(grim_creeper, 700, 32, grim_creeper:get_angle(eagle), grim_creeper:get_distance(eagle) + 32, function()
                        grim_creeper:remove()
                        eagle:remove_sprite(eagle_sprite)
                        eagle_sprite = eagle:create_sprite("enemies/boss/evil_eagle")
                        eagle_sprite:set_animation("flying")
                        eagle_sprite:set_direction(2)
                        sol.timer.start(map, 1000, function()
                          map:set_cinematic_mode(false, {entities_ignore_suspend = {grim_creeper, minion_1, minion_2, eagle}})
                          hero:unfreeze()
                          start_straight_movement(eagle, 120, math.pi * 0.9, 40, function()
                            eagle_sprite:set_animation("rushing")
                            start_straight_movement(eagle, 180, math.pi * 0.95, 200, function()
                              eagle:remove()
                              enemy_manager:launch_boss_if_not_dead(map)
                              sol.timer.start(map, 2000, function()
                                boss:start_fighting()
                              end)

                              function boss:on_dying()
                                game:start_dialog("maps.dungeons.7.boss_dying")
                              end
                            end)
                          end)
                        end)
                      end)
                    end)
                  end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

-- Make the given cloud moves.
local function start_cloud_movement(entity, speed)

  local x, y = entity:get_position()
  local movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_max_distance(264)
  movement:set_angle(0)
  movement:set_ignore_obstacles()
  movement:start(entity)

  function movement:on_finished()
    entity:set_position(x, y)
    start_cloud_movement(entity, speed)
  end
end

-- Clouds managment.
local function start_thunder()

  sol.timer.start(map, math.random(2000, 4000), function()
    local thunder = map:create_custom_entity({
      direction = 0,
      x = math.random(0, 320),
      y = 0,
      layer = 0,
      width = 32,
      height = 72,
      sprite = "entities/effects/thunder"
    })
    local sprite = thunder:get_sprite()
    sprite:set_animation("appearing", function()
      sprite:set_animation("visible")
      sol.timer.start(thunder, 300, function()
        thunder:remove()
      end)
    end)
    return math.random(2000, 4000)
  end)
end

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Sideview
  map:set_sideview(true)
  -- Weather
  weather_manager:launch_sideview_rain(map, 200, 2)
  weather_manager:launch_sideview_rain(map, 50, 1)
  for cloud in map:get_entities("clouds") do
    start_cloud_movement(cloud, math.random(10, 30))
  end
  start_thunder()
  -- Pickables
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:appear_heart_container_if_boss_dead(map)
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")
end

-- Start the boss when entering the top screen or deactivate it when leaving.
function separator_1:on_activating(direction4)

  -- If the boss exists, deactivate it when going to the south and restart it when going to the north.
  -- Manually handle the activation cause the enemy may not be on the hero region nor the map when taking the separator.
  if boss and boss:exists() then
    if direction4 == 1 and not boss:is_enabled() then
      boss:set_enabled(true)
      boss:start_fighting() -- Restart the boss if coming up again after falling.

    elseif direction4 == 3 and boss:is_enabled() then
      sol.timer.stop_all(boss)
      boss:stop_movement()
      boss:set_enabled(false)
    end
  end

  -- Start the boss if needed.
  if is_boss_active == false and not game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss") then
    is_boss_active = true
    start_boss_cinematic()
  end
end