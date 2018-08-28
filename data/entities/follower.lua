local follower = ...


local game = follower:get_game()
local map = follower:get_map()
local sprite = follower:get_sprite()
local hero = game:get_hero()
local movement

follower:set_optimization_distance(0)
follower:set_drawn_in_y_order(true)
follower:set_traversable_by(true)
follower:set_traversable_by("hero", false)
follower:set_can_traverse("enemy", true)
follower:set_can_traverse("npc", true)
follower:set_can_traverse("sensor", true)
follower:set_can_traverse("separator", true)
follower:set_can_traverse("stairs", true)
follower:set_can_traverse("teletransporter", true)

local function follow_hero()

  movement = sol.movement.create("target")
  movement:set_speed(100)
  movement:set_ignore_obstacles(true)
  movement:start(follower)
  game.follower_following = true
  sprite:set_animation("walking")

  follower:set_can_traverse("hero", true)
  follower:set_traversable_by("hero", true)
end

-- Stops for now because too close or too far.
local function stop_walking()

  follower:stop_movement()
  movement = nil
  sprite:set_animation("stopped")
end

function follower:on_created()
game.follower_following = true
  if follower:is_following_hero() then
    follower:set_position(hero:get_position())
    follower:get_sprite():set_direction(hero:get_direction())
    follow_hero()
    return
  end

  follower:set_enabled(true)
end

function follower:on_interaction()

  
end

function follower:on_movement_changed()

  local movement = follower:get_movement()
  if movement:get_speed() > 0 then
    if sprite:get_animation() ~= "walking" then
      sprite:set_animation("walking")
    end
  end
end

function follower:on_position_changed()


  local distance = follower:get_distance(hero)
  if follower:is_following_hero() and follower:is_very_close_to_hero() then
    -- Close enough to the hero: stop.
    stop_walking()
  end

end

function follower:on_obstacle_reached()

  sprite:set_animation("stopped")
end

function follower:on_movement_finished()

  sprite:set_animation("stopped")
end

-- Returns whether Zelda is currently following the hero.
-- This is true even if she is temporarily stopped because too far
-- or to close.
function follower:is_following_hero()
  -- This is stored on the game because it persists accross maps,
  -- but this is not saved.
  return game.follower_following
end

function follower:is_very_close_to_hero()

  local distance = follower:get_distance(hero)
  return distance < 32
end

function follower:is_far_from_hero()

  local distance = follower:get_distance(hero)
  return distance >= 100
end

-- Called when the hero leaves a map without Zelda when he was supposed to wait for her.
function follower:hero_gone()

  -- Zelda will be back to the prison cell.
  game.follower_following = false
end

sol.timer.start(follower, 50, function()

  if follower:is_following_hero() then
    if movement == nil and not follower:is_very_close_to_hero() and not follower:is_far_from_hero() then
      -- Restart.
      follow_hero()
    elseif movement ~= nil and follower:is_far_from_hero() then
      -- Too far: stop.
      stop_walking()
    end
  end

  if hero:get_state() == "stairs" and follower:is_following_hero() and not follower:is_far_from_hero() then
    follower:set_position(hero:get_position())
    if hero:get_movement() ~= nil then
      sprite:set_direction(hero:get_movement():get_direction4())
    end
  end

  return true
end)
