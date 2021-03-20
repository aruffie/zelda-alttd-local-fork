-- Variables
local map = ...
local game = map:get_game()
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local enemy_manager = require("scripts/maps/enemy_manager")

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

  -- Create the grim creeper and its minions.
  local x, y, layer = placeholder_boss:get_position()
  local grim_creeper = create_custom_entity(x, y, "enemies/boss/evil_eagle/grim_creeper")
  local minion_1 = create_custom_entity(x - 24, y - 24, "enemies/boss/grim_creeper/minion")
  local minion_2 = create_custom_entity(x + 24, y - 24, "enemies/boss/grim_creeper/minion")
  grim_creeper:get_sprite():set_animation("waiting")

  -- Then make the eagle appear.
  sol.timer.start(map, 2000, function()
    local eagle = map:create_custom_entity({
      direction = 2,
      x = 368,
      y = 16,
      layer = hero:get_layer(),
      width = 16,
      height = 16,
      sprite = "enemies/boss/evil_eagle/eagle"
    })
    local eagle_sprite = eagle:get_sprite()
    eagle_sprite:set_animation("rushing")

    -- Start the actual cinematic.
    --map:set_cinematic_mode(true, {entities_ignore_suspend = {grim_creeper, minion_1, minion_2, eagle}})
    start_straight_movement(eagle, 240, math.pi, 416, function()
      sol.timer.start(map, 1000, function()
        eagle:set_position(-48, 70)
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
                sol.timer.start(grim_creeper, 200, function()
                  start_jumping(grim_creeper, 700, 32, grim_creeper:get_angle(eagle), grim_creeper:get_distance(eagle) + 32, function()
                    grim_creeper:remove()
                    eagle:remove_sprite(eagle_sprite)
                    eagle_sprite = eagle:create_sprite("enemies/boss/evil_eagle")
                    eagle_sprite:set_animation("flying")
                    eagle_sprite:set_direction(2)
                    sol.timer.start(map, 1000, function()
                      --map:set_cinematic_mode(true, {entities_ignore_suspend = {grim_creeper, minion_1, minion_2, eagle}})
                      hero:unfreeze()
                      start_straight_movement(eagle, 120, math.pi * 0.9, 240, function()
                        eagle:remove()
                        boss:start_fighting()
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

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Sideview
  map:set_sideview(true)
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")
end

-- Start the boss
function sensor_1:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
    start_boss_cinematic()

    function boss:on_dying()
      game:start_dialog("maps.dungeons.7.boss_dying")
    end
  else
    boss:start_fighting() -- Restart the boss if coming up again after falling.
  end
end