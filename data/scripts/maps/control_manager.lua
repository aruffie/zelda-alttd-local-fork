-- Control Manager.
--[[
Use this script to create control menus. A control menu controls input commands pressed.
This includes the creation of movements from the arrow key commands pressed.

-- INSTRUCTIONS:
1) Import the script.
2) To start a control menu on an entity:

  local control_menu = game:create_control_menu([can_override])
  <<-- Set your movement properties here with the setter functions.
  control_menu:start(entity)

3) To stop the menu, write:

  control_menu:stop()

4) -- Functions to set properties:
  control_menu:set_fixed_animations(stopped_anim, walking_anim)
  control_menu:get_fixed_animations()
  control_menu:set_speed(speed)
  control_menu:get_speed()
  control_menu:set_can_override(can_override)
  control_menu:get_can_override()
  control_menu:set_on_top(on_top)
  control_menu:get_on_top()
  control_menu:is_sideview()
  -- Events that can be overriden:
  control_menu:on_command_pressed(command)
  control_menu:on_command_released(command)

--]]

-- Returns new control menu.
game_meta = sol.main.get_metatable("game")

function game_meta:create_control_menu(can_override)

  -- Create menu and default values.
  local control_menu = {}
  control_menu.can_override = false
  control_menu.on_top = true
  control_menu.speed = 88
  control_menu.entity = nil

  -- Initialize menu.
  function control_menu:start(entity)
    control_menu.entity = entity
    local game = entity:get_game()
    local map = entity:get_map()
    -- Start menu.
    sol.menu.start(map, control_menu, control_menu.on_top)
    sol.menu.bring_to_front(control_menu)
    -- Initialize current movement.
    local dir8 = game:get_commands_direction()
    control_menu:update_movement(dir8)
  end

  -- Finish menu.
  function control_menu:stop(entity)
    control_menu.entity:stop_movement()
    sol.menu.stop(control_menu)
  end

  -- Select stopped/walking animations.
  function control_menu:set_fixed_animations(stopped_anim, walking_anim)
    control_menu.stopped_animation = stopped_anim
    control_menu.walking_animation = walking_anim
  end
  function control_menu:get_fixed_animations()
    local stopped_anim = control_menu.stopped_animation
    local walking_anim = control_menu.walking_animation
    return stopped_anim, walking_anim
  end

  -- Select speed.
  function control_menu:set_speed(speed) control_menu.speed = speed end
  function control_menu:get_speed() return control_menu.speed end
  -- Select overriding commands.
  function control_menu:set_can_override(can_override) control_menu.can_override = can_override end
  function control_menu:get_can_override() return control_menu.can_override end
  -- Select if it is on top.
  function control_menu:set_on_top(on_top) control_menu.on_top = on_top end
  function control_menu:get_on_top() return control_menu.on_top end
  -- To know if the behavior is sideview.
  function control_menu:is_sideview()
    local map = control_menu.entity:get_map()
    return map.is_sideview and map:is_sideview()
  end

  -- Handle commands for input events.
  function control_menu:on_command_pressed(command)
    if not control_menu:is_sideview() then
      control_menu:handle_command(command, "pressed")
    else
      control_menu:handle_command(command, "pressed")
      --control_menu:handle_sideview_command(command, "pressed")
    end
  end
  function control_menu:on_command_released(command)
    if not control_menu:is_sideview() then
      control_menu:handle_command(command, "released")
    else
      control_menu:handle_command(command, "released")
      --control_menu:handle_sideview_command(command, "released")
    end
  end

  -- Default behavior for normal maps.
  function control_menu:handle_command(command, action)
    local entity = control_menu.entity
    local game = entity:get_game()
    local hero = game:get_hero()
    local is_arrow = (command == "up") or (command == "down")
                  or (command == "left") or (command == "right")
    if is_arrow then
      -- Arrow key commands.
      local dir8 = game:get_commands_direction()
      control_menu:update_movement(dir8)
      return control_menu.can_override -- Handled if it can override.
    elseif (command == "item_1" or command == "item_2")
        and entity:get_type() == "hero" then
      -- Item command.
      local slot = (command == "item_1") and 1 or 2
      local item = game:get_item_assigned(slot)
      -- TODO: check if the item can be used.
      item:on_using()
    elseif command == "attack" and entity:get_type() == "hero"
        and action == "pressed" then
      control_menu:set_fixed_animations(nil, nil)
      entity:unfreeze() -- TODO: remove and modify this when we have custom states.
      entity:start_attack()
      return true
    end
  end

  -- Default behavior for sideview maps. Ignore up/down arrowkeys.
  function control_menu:handle_sideview_command(command, action)
    local entity = control_menu.entity
    local game = entity:get_game()
    local is_horizontal_arrow = (command == "left") or (command == "right")
    if is_horizontal_arrow then
      -- Arrow key commands.
      local dir8 = (command == "right") and 0 or 4
      control_menu:update_movement(dir8)
      return control_menu.can_override -- Handled if it can override.
    elseif (command == "item_1" or command == "item_2")
        and entity:get_type() == "hero" then
      -- Item command.
      local slot = (command == "item_1") and 1 or 2
      local item = game:get_item_assigned(slot)
      -- TODO: check if the item can be used.
      item:on_using()
    elseif command == "attack" and entity:get_type() == "hero"
        and action == "pressed" then
      control_menu:set_fixed_animations(nil, nil)
      entity:unfreeze() -- TODO: remove and modify this when we have custom states.
      entity:start_attack()
      return true
    end
  end

  -- Create movement for the given direction.
  function control_menu:update_movement(dir8)
    local entity = control_menu.entity
    -- If no direction, stop movement.
    if dir8 == nil then
      entity:stop_movement()
      for _, sprite_name in pairs({"tunic"}) do
        local sprite = entity:get_sprite(sprite_name) 
        local stopped_anim = control_menu.stopped_animation
        if stopped_anim and sprite:has_animation(stopped_anim) then
          sprite:set_animation(stopped_anim)
        end
      end
      return
    end
    -- Create movement.
    local m = sol.movement.create("straight")
    m:set_angle(dir8 * math.pi/4)
    m:set_speed(control_menu:get_speed())
    m:set_smooth(true)
    -- Update sprites. Update direction for non diagonal movements.
    for _, sprite_name in pairs({"tunic"}) do
      local sprite = entity:get_sprite(sprite_name) 
      local walking_anim = control_menu.walking_animation
      if walking_anim and sprite:has_animation(walking_anim) then
        sprite:set_animation(walking_anim)
      end
      if dir8 % 2 == 0 then
        local anim = sprite:get_animation()
        local dir4 = dir8 / 2
        if sprite:get_num_directions(anim) > dir4 then sprite:set_direction(dir4) end
      end
    end

    -- Start movement.
    m:start(control_menu.entity)
  end

  -- Return control menu.
  return control_menu
end
