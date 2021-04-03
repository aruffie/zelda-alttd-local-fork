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
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local transitions = {}
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local giant_gel

-- Configuration variables
local before_giant_gel_transition_duration = 2000
local body_count = 8
local between_body_duration = 100
local giant_gel_transition_speed = 100
local giant_gel_transition_angle = quarter
local giant_gel_transition_distance = 80
local giant_gel_transition_spirit_duration = 3000
local giant_gel_transition_reduced_duration = 2500

-- Start the transition to the giant gel form.
local function start_giant_gel_transition()

  sol.timer.start(enemy, before_giant_gel_transition_duration, function()

    -- Create the shadow tail.
    local body_sprites = {}
    for i = 1, body_count, 1 do
      local body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
      body_sprite:set_animation("body")
      enemy:bring_sprite_to_back(body_sprite)
      table.insert(body_sprites, body_sprite)
    end

    -- Start a recoil movement on tail sprites first.
    local i = 1
    sol.timer.start(enemy, between_body_duration, function()
      local movement = sol.movement.create("straight")
      movement:set_speed(giant_gel_transition_speed)
      movement:set_max_distance(giant_gel_transition_distance)
      movement:set_angle(giant_gel_transition_angle)
      movement:start(i == body_count + 1 and sprite or body_sprites[i])

      -- Make the first body_sprite slowly grow up when the head starts moving, and remove body sprites when the growth finishes.
      if i == body_count + 1 then
        body_sprites[1]:set_animation("growing", function()
          for _, body_sprite in ipairs(body_sprites) do
            enemy:remove_sprite(body_sprite)
          end

          -- Let the spirit form for some time, then reduce size again, wait and grow up again.
          sprite:set_animation("spirit")
          sol.timer.start(enemy, giant_gel_transition_spirit_duration, function()
            sprite:set_animation("reducing", function()
              sprite:set_animation("body")
              sol.timer.start(enemy, giant_gel_transition_reduced_duration, function()
                sprite:set_animation("growing", function()

                  -- Create the giant gel enemy.
                  local x, y = enemy:get_position()
                  local head_x, head_y = sprite:get_xy()
                  enemy:set_position(x + head_x, y + head_y)

                  giant_gel = enemy:create_enemy({
                    name = (enemy:get_name() or enemy:get_breed()) .. "_giant_gel",
                    breed = "boss/shadow_nightmares/giant_gel"
                  })

                  -- Prepare the next transition when giant gel defeated.
                  giant_gel:register_event("on_dead", function(giant_gel)
                    enemy:start_transition("aghanim")
                  end)

                  -- Reset the main enemy and make it unable to interact.
                  sprite:set_xy(0, 0)
                  enemy:stop_all()
                  enemy:set_visible(false)
                end)
              end)
            end)
          end)
        end)
        body_sprites[1]:set_frame_delay(300)
      end

      i = i + 1
      return i < body_count + 2
    end)
  end)
end

-- Start the transition to the aghanim form.
local function start_aghanim_transition()

  local x, y = giant_gel:get_position()
  enemy:set_position(x, y - 16)
  enemy:set_visible()
  sprite:set_animation("head")

  -- Create the shadow particles.
  for i = 1, body_count, 1 do
    local particle_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
    particle_sprite:set_animation("particle", function()
      enemy:remove_sprite(particle_sprite)
    end)
    enemy:bring_sprite_to_back(particle_sprite)

    local movement = sol.movement.create("straight")
      movement:set_speed(giant_gel_transition_speed)
      movement:set_max_distance(giant_gel_transition_distance)
      movement:set_angle(i * eighth)
      movement:start(particle_sprite)
  end
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
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  sprite:set_animation("head")
  enemy:set_drawn_in_y_order(false)
  enemy:set_position(hero:get_position())
  enemy:set_invincible()
  enemy:set_can_attack(false)
  enemy:start_transition("giant_gel")
end)
