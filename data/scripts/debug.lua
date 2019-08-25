-- Adds cheating keys and a Lua console to ease debugging.
-- Debugging is enabled if there exists a file called "debug"
-- or "debug.lua" in the write directory.

-- Usage:
-- require("scripts/debug")
local mode_7_manager = require("scripts/mode_7")

if not sol.file.exists("debug") and not sol.file.exists("debug") then
  return true
end

local console = require("scripts/console")
local game_manager = require("scripts/game_manager")

local debug = {}
local show_debug_info_screen=false

function debug:on_key_pressed(key, modifiers)

  local handled = true
  if key == "1" then
    if sol.game.exists("save1.dat") then
      sol.main:start_savegame(game_manager:create("save1.dat"))
    end
  elseif key == "2" then
    if sol.game.exists("save2.dat") then
      sol.main:start_savegame(game_manager:create("save2.dat"))
    end
  elseif key == "3" then
    if sol.game.exists("save3.dat") then
      sol.main:start_savegame(game_manager:create("save3.dat"))
    end
  elseif key == "f12" and not console.enabled then
    sol.menu.start(sol.main, console)
  elseif key == "f10" then
    print ("toggled debug screen")
    show_debug_info_screen = not show_debug_info_screen
  elseif sol.main.game ~= nil and not console.enabled then
    local game = sol.main.game
    local map = game:get_map()
    local hero = nil
    if game ~= nil and map ~= nil then
      hero = map:get_entity("hero")
    end

    -- In-game cheating keys.
    if key == "p" then
      game:add_life(5)
    elseif key == "m" then
      game:remove_life(4)
    elseif key == "o" then
      game:add_money(50)
    elseif key == "l" then
      game:remove_money(15)
    elseif key == "i" then
      game:add_magic(10)
    elseif key == "k" then
      game:remove_magic(4)
    elseif key == "kp 7" then
      game:set_max_magic(0)
    elseif key == "kp 8" then
      game:set_max_magic(42)
    elseif key == "kp 9" then
      game:set_max_magic(84)
    elseif key == "kp 1" then
      local tunic = game:get_item("tunic")
      local variant = math.max(1, tunic:get_variant() - 1)
      tunic:set_variant(variant)
      game:set_ability("tunic", variant)
    elseif key == "kp 4" then
      local tunic = game:get_item("tunic")
      local variant = math.min(3, tunic:get_variant() + 1)
      tunic:set_variant(variant)
      game:set_ability("tunic", variant)
    elseif key == "kp 2" then
      local sword = game:get_item("sword")
      local variant = math.max(1, sword:get_variant() - 1)
      sword:set_variant(variant)
    elseif key == "kp 5" then
      local sword = game:get_item("sword")
      local variant = math.min(4, sword:get_variant() + 1)
      sword:set_variant(variant)
    elseif key == "kp 3" then
      local shield = game:get_item("shield")
      local variant = math.max(1, shield:get_variant() - 1)
      shield:set_variant(variant)
    elseif key == "kp 6" then
      local shield = game:get_item("shield")
      local variant = math.min(3, shield:get_variant() + 1)
      shield:set_variant(variant)
    elseif key == "g" and hero ~= nil then
      local x, y, layer = hero:get_position()
      if layer ~= map:get_min_layer() then
        hero:set_position(x, y, layer - 1)
      end
    elseif key == "t" and hero ~= nil then
      local x, y, layer = hero:get_position()
      if layer ~= map:get_max_layer() then
        hero:set_position(x, y, layer + 1)
      end
    elseif key == "r" then
      if hero:get_walking_speed() == 384 then
        hero:set_walking_speed(debug.normal_walking_speed)
      else
        debug.normal_walking_speed = hero:get_walking_speed()
        hero:set_walking_speed(384)
      end
    elseif key == "7" then
      local map_id = "out/a1_west_mt_tamaranch"
      local destination_name = "travel_destination"
      mode_7_manager:teleport(game, map:get_entity("travel_sensor"), map_id, destination_name)
    else
      -- Not a known in-game debug key.
      handled = false
    end
  else
    -- Not a known debug key.
    handled = false
  end

  return handled
end

-- The shift key skips dialogs
-- and the control key traverses walls.
local hero_movement = nil
local ctrl_pressed = false
function debug:on_update()

  local game = sol.main.game
  if game ~= nil then

    if game:is_dialog_enabled() then
      if sol.input.is_key_pressed("left shift") or sol.input.is_key_pressed("right shift") then
        game:get_dialog_box():show_all_now()
      end
    end

    local hero = game:get_hero()
    if hero ~= nil then
      if hero:get_movement() ~= hero_movement then
        -- The movement has changed.
        hero_movement = hero:get_movement()
        if hero_movement ~= nil
        and ctrl_pressed
        and not hero_movement:get_ignore_obstacles() then
          -- Also traverse obstacles in the new movement.
          hero_movement:set_ignore_obstacles(true)
        end
      end
      if hero_movement ~= nil then
        if not ctrl_pressed
        and (sol.input.is_key_pressed("left control") or sol.input.is_key_pressed("right control") or sol.input.is_key_pressed("-")) then
          hero_movement:set_ignore_obstacles(true)
          ctrl_pressed = true
        elseif ctrl_pressed
        and (not sol.input.is_key_pressed("left control") and not sol.input.is_key_pressed("right control")) then
          hero_movement:set_ignore_obstacles(false)
          ctrl_pressed = false
        end
      end
    end
  end
end


--[[
  ------------------------------------
  DEBUG INFORMATION DISPLAY
  ------------------------------------
--]]

-- set up pressed commands display
local debug_command_sprite=sol.sprite.create("debug/commands")
local commands = {
  {
    name = "action",
    x = 310,
    y = 227,
  },
  {
    name = "attack", 
    x = 301,
    y = 233,
  }, 
  {
    name = "item_1", 
    x = 292,
    y = 227,
  },
  {
    name = "item_2", 
    x = 301,
    y = 222,
  }, 
  {
    name = "pause", 
    x = 283,
    y = 227,
  }, 
  {
    name = "up", 
    x = 270,
    y = 222,
  }, 
  {
    name = "down", 
    x = 270,
    y = 232,
  }, 
  {
    name = "left", 
    x = 266,
    y = 227,
  }, 
  {
    name = "right",
    x = 274,
    y = 227,
  },
}
--set up debug informations display
local debug_informations_text=sol.text_surface.create({
    vertical_alignment="top",
    font="enter_command_mono",
    font_size=17, 
  })
local debug_informations_background=sol.surface.create(sol.video.get_quest_size())
debug_informations_background:fill_color({64,64,64,192})

local function show_text(dst, x,y,text)
  debug_informations_text:set_text(text)
  debug_informations_text:draw(dst, x, y)
end

function debug:on_draw(dst_surface)
  local game = sol.main.get_game()
  if game then

    --Show cuttently active command keys
    for _, command in pairs(commands) do
      if game:is_command_pressed(command.name) then
        debug_command_sprite:set_animation(command.name)
        debug_command_sprite:draw(dst_surface, command.x, command.y)
      end
    end

    --show various information about the game on-screen, such as the moement parameters. Can be switched on and off by pressing F11
    --[[
      Common fields : XY, direction4
      
      Field         Straight/         Pathfinding/
                    Random/     Path  Rndm path      Circle     Jump  Pixel
                    /target
      -------------------------------------------
        Speed       X           X      X                         X
        Angle       X           X      X              
        Max dist.   X           -.     -
        smooth?     X           -      -
        Path        -           X      -
        Loop ?      -           X      -                                 X
        Snaptogrid  -           X      -
        Center      -           -      -              X
        Radius                                        X
        Radius_speed                                  X
        Clockwise?                                    X
        Angle from center                             X
        Angular speed                                 X
        Rotations                                     X
        Duration                                      X
        Loop delay                                    X
        Direction8                                               X
        Distance                                                 X
        Trajectory                                                       X
        Delay                                                            X
        
        
        Lines 
        Speed / Anguler speed
        Angle / Angle from center
        Smoot / Loop / clockwise - able
    --]]
    if show_debug_info_screen then
      debug_informations_background:draw(dst_surface)
      local hero=game:get_hero()
      local hero_movement=hero:get_movement()

      if hero_movement then
        show_text(dst_surface, 0, 0, "Movement info")
        local x,y=hero_movement:get_xy()
        show_text(dst_surface, 0, 10, "Position: ("..x..", "..y..")")
        show_text(dst_surface, 0, 20, "Direction:" ..hero_movement:get_direction4())
        
        if hero_movement.get_speed then
          show_text(dst_surface, 0, 30, "Speed: "..hero_movement:get_speed().." px/s")
        end
        if hero_movement.get_angular_speed then
          show_text(dst_surface, 0, 30, "A.Speed: "..hero_movement:get_anguler_speed().." rad/s")
        end
        
        if hero_movement.get_angle then
          show_text(dst_surface, 0, 40, "Angle: "..hero_movement:get_angle().." rad")
        end
        if hero_movement.get_angle_from_center then
          show_text(dst_surface, 0, 40, "Circular Angle: "..hero_movement:get_angle_from_center().." rad")
        end
        
        if hero_movement.get_max_distance then
          show_text(dst_surface, 0, 50, "Distance: "..hero_movement:get_max_distance().." px")
        end
        
        if hero_movement.is_smooth then
          show_text(dst_surface, 0, 60, "Smooth? "..(hero_movement:is_smooth() and "Yes" or "No"))
        end        if hero_movement.is_clockwise then
          show_text(dst_surface, 0, 60, "Clockwise? "..(hero_movement:is_clockwise() and "Yes" or "No"))
        end        if hero_movement.get_snap_to_grid then
          show_text(dst_surface, 0, 60, "Snap to grid? "..(hero_movement:get_snap_to_grid() and "Yes" or "No"))
        end
        if hero_movement.get_path then
          show_text(dst_surface, 0, 70, "Path"..hero_movement:get_path())
        end        
        if hero_movement.get_path then
          show_text(dst_surface, 0, 70, "Path"..hero_movement:is_mooth())
        end      
      end
    end
  end
end

sol.menu.start(sol.main, debug)

return true
