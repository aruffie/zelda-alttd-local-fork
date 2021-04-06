----------------------------------
--
-- Shadow Nightmares.
--
-- Main enemy of shadow nightmares, that will call the 6 others and handle transitions between them.
--
-- Methods : enemy:start_transition(step)
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/boss/shadow_nightmares/spirit")
local transitions = {}
local quarter = math.pi * 0.5
local spawn_position = {}

-- Configuration variables
local before_spirit_duration = 2000
local body_count = 8
local between_body_duration = 100
local caterpillar_speed = 100
local caterpillar_angle = quarter
local spirit_duration = 3000
local explosion_particle_count = 8
local explosion_particle_speed = 120
local explosion_particle_distance = 80
local particle_speed = 120
local giant_gel_transition_before_growing_duration = 1500
local aghanim_transition_before_reducing_duration = 2000
local aghanim_transition_before_growing_duration = 1000
local moldorm_transition_before_reducing_duration = 1000
local moldorm_transition_before_growing_duration = 500
local ganon_transition_before_growing_duration = 1000
local lanmola_transition_before_moving_duration = 1000
local dethl_transition_before_moving_duration = 2000
local dethl_transition_before_reducing_duration = 1000
local dethl_transition_before_growing_duration = 500

-- Create the given shadow nightmares enemy.
local function create_shadow(name, breed, on_dead_callback)

  local shadow = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_" .. name,
    breed = breed,
    direction = 3,
    y = 5
  })

  -- Prepare the next transition when shadow defeated.
  shadow:register_event("on_dead", function(shadow)
    local x, y = shadow:get_position()
    local sprite_x, sprite_y = shadow:get_sprite():get_xy()
    enemy:set_position(x + sprite_x, y + sprite_y - 13)
    if on_dead_callback then
      on_dead_callback()
    end
  end)

  -- Reset the main enemy and make it unable to interact.
  sprite:set_xy(0, 0)
  enemy:stop_all()
  enemy:set_visible(false)
end

-- Start movement that accept no distance and ignore obstacles.
local function start_straight_movement(angle, speed, distance, on_finished_callback)

  if distance > 0 then
    local movement = enemy:start_straight_walking(angle, speed, distance, function()
      if on_finished_callback then
        on_finished_callback()
      end
    end)
    movement:set_ignore_obstacles()
  else
    if on_finished_callback then
      on_finished_callback()
    end
  end
end
-- Start a shadow explosion projecting particles.
local function start_particle_explosion()

  -- Create sprite on an independent entity in case the enemy moves.
  local x, y, layer = enemy:get_position()
  local explosion = map:create_custom_entity({
    direction = 0,
    x = x,
    y = y,
    layer = layer,
    width = 16,
    height = 16
  })
  explosion:set_traversable_by(true)

  -- Create the explosion.
  local angle = math.pi / explosion_particle_count * 2.0
  for i = 1, explosion_particle_count, 1 do
    local particle_sprite = explosion:create_sprite("enemies/boss/shadow_nightmares/spirit")
    particle_sprite:set_animation("reducing", function()
      explosion:remove()
    end)
    explosion:bring_sprite_to_back(particle_sprite)

    local movement = sol.movement.create("straight")
    movement:set_speed(explosion_particle_speed)
    movement:set_max_distance(explosion_particle_distance)
    movement:set_angle(i * angle)
    movement:start(particle_sprite)
  end
end

-- Make the enemy contract as a particle, then move to the spawn position and finally grow up again.
local function start_particle_transition(before_reducing_duration, before_growing_duration, explosion, on_finished_callback)

  enemy:set_visible()
  sprite:set_animation("head")
  if explosion then
    start_particle_explosion()
  end

  -- Start reducing then go to the spawn position, and finally grow up as the aghanim shadow.
  sol.timer.start(enemy, before_reducing_duration, function()
    sprite:set_animation("head_reducing", function()
      local angle = enemy:get_angle(spawn_position.x, spawn_position.y)
      local distance = enemy:get_distance(spawn_position.x, spawn_position.y)
      start_straight_movement(angle, particle_speed, distance, function()
        sol.timer.start(enemy, before_growing_duration, function()
          sprite:set_animation("growing", function()
            if on_finished_callback then
              on_finished_callback()
            end
          end)
        end)
      end)
      sprite:set_animation("particle")
    end)
  end)
end

-- Start moving as a caterpillar shadow to the north, then starts the short spirit shadow form.
local function start_spirit()

  sol.timer.start(enemy, before_spirit_duration, function()

    -- Create the shadow tail.
    local body_sprites = {}
    for i = 1, body_count, 1 do
      local body_sprite = enemy:create_sprite("enemies/boss/shadow_nightmares/spirit")
      body_sprite:set_animation("body")
      enemy:bring_sprite_to_back(body_sprite)
      table.insert(body_sprites, body_sprite)
    end

    -- Start a recoil movement on tail sprites first.
    local i = 1
    sol.timer.start(enemy, between_body_duration, function()
      local x, y = enemy:get_position()
      local movement = sol.movement.create("straight")
      movement:set_speed(caterpillar_speed)
      movement:set_max_distance(y - spawn_position.y)
      movement:set_angle(caterpillar_angle)
      movement:start(i == body_count + 1 and sprite or body_sprites[i])

      -- Make the first body_sprite slowly grow up when the head starts moving, and remove body sprites when the growth finishes.
      if i == body_count + 1 then
        body_sprites[1]:set_animation("growing", function()
          for _, body_sprite in ipairs(body_sprites) do
            enemy:remove_sprite(body_sprite)
          end

          -- Let the spirit form for some time, then starts the transition to giant gel.
          sprite:set_animation("spirit")
          sol.timer.start(enemy, spirit_duration, function()
            local head_x, head_y = sprite:get_xy()
            sprite:set_xy(0, 0)
            enemy:set_position(x + head_x, y + head_y)
            enemy:start_transition("giant_gel")
          end)
        end)
        body_sprites[1]:set_frame_delay(200)
      end

      i = i + 1
      return i < body_count + 2
    end)
  end)
end

-- Start the transition to the giant gel form.
local function start_giant_gel_transition()

  sprite:set_animation("reducing", function()
    sol.timer.start(enemy, giant_gel_transition_before_growing_duration, function()
      sprite:set_animation("growing", function()
        create_shadow("giant_gel", "boss/shadow_nightmares/giant_gel", function()
          enemy:start_transition("aghanim")
        end)
      end)
    end)
    sprite:set_animation("particle")
  end)
end

-- Start the transition to the aghanim form.
local function start_aghanim_transition()

  start_particle_transition(aghanim_transition_before_reducing_duration, aghanim_transition_before_growing_duration, true, function()
    local growing_entity = enemy:start_brief_effect("enemies/boss/shadow_nightmares/aghanim", "growing", 0, 5, nil, function()
      create_shadow("aghanim", "boss/shadow_nightmares/aghanim", function()
        enemy:start_transition("moldorm")
      end)
    end)
    growing_entity:get_sprite():set_direction(enemy:get_direction4_to(hero))
  end)
end

-- Start the transition to the moldorm form.
local function start_moldorm_transition()

  start_particle_transition(moldorm_transition_before_reducing_duration, moldorm_transition_before_growing_duration, true, function()
    create_shadow("moldorm", "boss/shadow_nightmares/moldorm", function()
      enemy:start_transition("ganon")
    end)
  end)
end

-- Start the transition to the ganon form.
local function start_ganon_transition()

  start_particle_transition(0, ganon_transition_before_growing_duration, true, function()
    local growing_entity = enemy:start_brief_effect("enemies/boss/shadow_nightmares/ganon", "growing", 0, 5, nil, function()
      create_shadow("ganon", "boss/shadow_nightmares/ganon", function()
        enemy:start_transition("lanmola")
      end)
    end)
  end)
end

-- Start the transition to the lanmola form.
local function start_lanmola_transition()

  enemy:set_visible()
  sprite:set_animation("head")
  start_particle_explosion()
  sol.timer.start(enemy, lanmola_transition_before_moving_duration, function()
    create_shadow("lanmola", "boss/shadow_nightmares/lanmola", function()
      enemy:start_transition("dethl")
    end)
  end)
end

-- Start the transition to the dethl form.
local function start_dethl_transition()

  enemy:set_visible()
  sprite:set_animation("head")
  start_particle_explosion()

  -- Start moving to the spawn position on the head form, then reduce to particle and grow up as dethl.
  sol.timer.start(enemy, dethl_transition_before_moving_duration, function()
    local angle = enemy:get_angle(spawn_position.x, spawn_position.y)
    local distance = enemy:get_distance(spawn_position.x, spawn_position.y)
    start_straight_movement(angle, particle_speed, distance, function()
      start_particle_transition(dethl_transition_before_reducing_duration, dethl_transition_before_growing_duration, false, function()
        create_shadow("dethl", "boss/shadow_nightmares/dethl", function()
          enemy:start_death()
        end)
      end)
    end)
  end)
end

-- Start the transition to the given step.
function enemy:start_transition(step)

  if transitions[step] then
    transitions[step]()
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Store corresponding steps function.
  transitions["giant_gel"] = start_giant_gel_transition
  transitions["aghanim"] = start_aghanim_transition
  transitions["moldorm"] = start_moldorm_transition
  transitions["ganon"] = start_ganon_transition
  transitions["lanmola"] = start_lanmola_transition
  transitions["dethl"] = start_dethl_transition

  -- Set the spawn reference position.
  local camera_x, camera_y, camera_width, camera_height = camera:get_bounding_box()
  spawn_position.x = camera_x + camera_width * 0.5
  spawn_position.y = camera_y + camera_height * 0.3
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  sprite:set_animation("head")
  enemy:set_drawn_in_y_order(false)
  enemy:set_position(hero:get_position())
  enemy:set_invincible()
  enemy:set_can_attack(false)
  --start_spirit()
  enemy:start_transition("ganon")
end)
