-- Lua script of item feather.
-- This script is executed only once for the whole game.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local hero_meta= sol.main.get_metatable("hero")

local item = ...
local game = item:get_game()
--local hero = game:get_hero()
local y_offset = 0
local y_vel=0
local y_accel = 0.3
local max_yvel = 5


-- Event called when the game is initialized.
function item:on_started()
  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
  -- Initialize the properties of your item here,
  -- like whether it can be saved, whether it has an amount
  -- and whether it can be assigned.
end


function hero_meta:is_jumping()
  return hero.is_jumping
end

function hero_meta:set_jumping(jumping)
  hero.is_jumping = jumping
end

local function update_jump(hero)
  for name, sprite in hero:get_sprites() do
    if name~="shadow" then
      sprite:set_xy(0, math.min(y_offset, 0))
    end
  end
  y_offset= y_offset+y_vel
  y_vel = y_vel + y_accel
  if y_offset >=0 then
    for name, sprite in hero:get_sprites() do
      if name~="shadow" then
        sprite:set_xy(0, 0)
      end
    end    
    hero.is_jumping = false
    return false
  end
  return true
end


function item:on_using()
--  print "FEATHER TIME"
  local hero = game:get_hero()
  local map = game:get_map()
  if hero.is_jumping~=true then
    if not map:is_sideview() then
      
      --TODO use custom state for actual jumping
--      print "JUMP"
      hero.is_jumping = true
      y_vel = -max_yvel
      sol.timer.start(game, 10, function() 
          return update_jump(hero)
        end)
    else
--      print "SIDEVIEW JUMP requested "
      local vspeed = hero.vspeed or 0
      if vspeed == 0 then
--        print "validated, now jump :"
        sol.timer.start(10, function()
            hero.on_ladder = false
            hero.vspeed = -max_yvel
          end)
      end
    end
  end

  -- Define here what happens when using this item
  -- and call item:set_finished() to release the hero when you have finished.
  item:set_finished()
end
