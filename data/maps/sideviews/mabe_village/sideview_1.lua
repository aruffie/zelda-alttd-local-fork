local audio_manager = require("scripts/audio_manager")

local map = ...
local game = map:get_game()
local hero = map:get_hero()

local ledger_hook
local ledger_sprite

-- game state,
-- can be [rest, launching, falling, pulling]
local state = "rest"

-- fish currently bitting the fishing ledger
local bitten_fish

-- spawn a fish of some size at line y and in the area of the custom entity region
-- size can be "small" or "big"
-- catch_callback will be called when the player gets this fish
local function make_fish(size, y, region, catch_callback)
  local left, top, width, height = region:get_bounding_box()
  local l = region:get_layer()
  local x = math.random(left, left + width - 20)

  local fish = map:create_custom_entity{
    x=x, y=y, layer=l,
    direction=0,
    width=16, height=16,
    sprite=string.format("entities/animals/fishing_%s_fish", size)
  }
  fish.catch_callback = catch_callback

  local stroll_speed = 12
  local chase_speed = 24

  local chasing = false

  local mov = sol.movement.create("straight")
  mov:set_speed(stroll_speed)
  mov:start(fish)
  local sprite = fish:get_sprite()

  -- activate the random walk of the fish
  function fish:start_stroll()
    local sprite = self:get_sprite()
    local mov = self:get_movement()
    sol.timer.start(self, math.random(1, 1000), function() -- phase timer
      local t1 = sol.timer.start(self, 200, function()
          -- check periodically if there is the hook in sight
          local fx, fy = self:get_position()
          local lx, ly = ledger_hook:get_position()
          if math.abs(ly-fy) < 16 then
            -- on the same line
            local close_enough = math.abs(fx-lx) < 50
            if (close_enough and fx < lx and self:get_direction() == 0) or
               (close_enough and fx > lx and self:get_direction() == 2) then
              -- ledger is in sight
              mov:set_speed(chase_speed)
              mov:set_angle(self:get_angle(ledger_hook))
              sprite:set_animation("chase")
              chasing = true
              
            end
          else
            mov:set_speed(stroll_speed)
            local ca = mov:get_angle()
            mov:set_angle(ca-math.fmod(ca, math.pi))
            sprite:set_animation("normal")
            chasing = false
          end
          
          self.chasing = chasing
          return true
        end)
      
      -- turn itself from time to time
      local t2 = sol.timer.start(self, 4000, function()
        if chasing then return true end
        if math.random(2) > 1 then
          mov:set_angle(0)
        else
          mov:set_angle(math.pi)
        end
        return true
      end)
      
      -- disable auto move, called when fish is caught
      function self:cancel_timers()
        t1:stop()
        t2:stop()
      end
    end)
  end
  
  -- turn around when reaching obstacle
  function mov:on_obstacle_reached()
    mov:set_angle(mov:get_angle() + math.pi)
  end

  fish:add_collision_test('sprite', function(this, other)
    if other == ledger_hook and fish.chasing then
      --was chasing and reached ledger, bite !
      fish:cancel_timers()
      mov:set_speed(0)
      if bitten_fish then
        -- previously bitting fish is released
        bitten_fish:start_stroll()
      end

      -- fix fish position to ledger position
      function ledger_hook:on_position_changed()
        local x,y = ledger_hook:get_position()
        fish:set_position(x-4,y+4)
        sprite:set_direction(0)
      end
      bitten_fish = fish
    end
  end)
  
  function fish:on_movement_changed(mov)
    sprite:set_direction(mov:get_direction4())
  end
  
  fish:start_stroll()
  
  return fish
end

local function small_fish_treasure()
  map:start_coroutine(function()
    wait_for(hero.start_treasure, hero, "fish_small", 1, "")
    dialog("maps.sideviews.mabe_village.sideview_1.got_small_fish")
    wait_for(hero.start_treasure, hero, "rupee", 2, "")
    local response = dialog("maps.sideviews.mabe_village.sideview_1.got_small_fish_2")
    if response then
      -- TODO play again
    else
      dialog("maps.sideviews.mabe_village.sideview_1.leaving")
      -- TODO leave
    end
  end)
end

-- Add the random fishes in the pool.
local function add_fishes()
  local line_count = 4

  local rx, ry, rw, rh = water_ent:get_bounding_box()

  for i = 0, line_count - 1 do
    local fish_y = ry + rh * (i / line_count) + math.random(8, 12)
    make_fish("small", fish_y, water_ent, small_fish_treasure)
  end

  -- TODO add
  -- - 1 big with a piece of heart
  -- - 1 big with 20 rupees
  -- - all small ones give 5 rupees
end

function map:init_music()

  audio_manager:play_music("15_trendy_game")

end

function map:on_started()

  map:init_music()
  hero:freeze()
  hero:set_animation("fishing_stopped")
  game:set_pause_allowed(false)
  
  local x, y, l = hero:get_position()
  ledger_hook = map:create_custom_entity{
    x = x - 18, y = y + 8, layer = l,
    width = 8, height = 8,
    direction = 0,
    sprite = "entities/ledger_hook",
  }
  ledger_hook:set_origin(8,8)
  ledger_sprite = ledger_hook:get_sprite()
  ledger_sprite:set_animation("move")
  
  add_fishes()
end

-- utility function to set a movement from a vector
local function set_mov_vec(mov, x, y)
  local angle = math.atan2(-y, x)
  local speed = math.sqrt(x*x + y*y)
  mov:set_angle(angle)
  mov:set_speed(speed)
end

local function clamp(min, max, val)
  return math.max(min, math.min(max, val))
end

local falling_speed = 24
local pull_speed = 24

-- start states functions
local function start_rest()
  state = "rest"
  local x,y,l = hero:get_position()
  ledger_hook:set_position(x - 18, y + 8, l)
  ledger_hook:stop_movement()
  hero:set_animation("fishing_caught_fish", function()
    hero:set_animation("fishing_stopped")
  end)
end

local function start_fall()
  state = "falling"
  local mov = sol.movement.create("straight")
  mov:set_angle(3 * math.pi / 2)
  mov:set_speed(falling_speed)
  mov:start(ledger_hook)
  ledger_sprite:set_animation("stopped")
  hero:set_animation("fishing_move")
end

local function start_pulling()
  state = "pulling"
  local mov = sol.movement.create"target"
  mov:set_target(hero)
  mov:set_speed(pull_speed)
  mov:start(ledger_hook)
  ledger_sprite:set_animation("move")
  hero:set_animation("fishing_pull")
end

local function start_in_water()
  local sp = ledger_hook:create_sprite("entities/ground_effects/water")
  sp:set_animation("default", function()
    ledger_hook:remove_sprite(sp)
  end)

  start_fall()
end

local function launch_ledger()
  map:start_coroutine(function()
    local options = {
      --entities_ignore_suspend = {ledger_hook}
    }
    map:set_cinematic_mode(true, options)
    hero:set_animation("fishing_stopped")

    wait(500)

    local x, y, l = hero:get_position()
    ledger_hook:set_position(x + 18, y, l)

    hero:set_animation("fishing_start", function()
      hero:set_animation("fishing_stopped")
    end)

    local acc = sol.movement.create("target")
    acc:set_target(x, y - 20)
    acc:set_speed(120)
    acc:set_ignore_obstacles(true)
    acc:set_ignore_suspend(true)

    movement(acc, ledger_hook)

    wait(80)

    local mov = sol.movement.create("straight")
    local t_start = sol.main.get_elapsed_time()

    local function current()
      return sol.main.get_elapsed_time() - t_start
    end

    local initial_x = -200
    local initial_y = -150

    mov:set_ignore_obstacles(false)
    mov:set_ignore_suspend(true)
    set_mov_vec(mov, initial_x, initial_y)
    mov:start(ledger_hook)

    sol.timer.start(map, 20, function()
      set_mov_vec(mov,
        clamp(initial_x, 0, initial_x + current() * 0.00), 
        math.min(1000, initial_y + current() * 0.5)
      )

      if ledger_hook:overlaps(water_ent) then
        mov:stop()
        map:set_cinematic_mode(false)
        hero:freeze()
        hero:set_animation("fishing_stopped")
        start_in_water()
        return false
      end
      return true
    end)
  end)
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()
  local state = hero:get_state()
  hero:freeze()
  hero:set_animation("fishing_stopped")
end

function map:on_command_pressed(cmd)
  if cmd == 'action' then
    if state == 'rest' then
      launch_ledger()
    elseif state == 'falling' then
      start_pulling()
    end
  end
end

function map:on_command_released(cmd)
  if cmd == 'action' then
    if state == 'pulling' then
      start_fall()
    end
  end
end

catch_zone:add_collision_test('overlapping', function(this, other)
  if state == 'pulling' and other == ledger_hook then
    if bitten_fish then
      -- fish was caught !
      local callback = bitten_fish.catch_callback
      bitten_fish:remove()
      bitten_fish = nil
      callback()
    else
      start_rest()
    end
  end
end)
