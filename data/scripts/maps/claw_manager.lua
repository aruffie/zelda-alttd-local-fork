local claw_manager = {}

local audio_manager = require("scripts/audio_manager")

-- Starts the Claw minigame.
-- Needs the following entities on the map: claw_up, claw_crane, claw_shadow.
-- Pickables of the minigame need to be prefixed by "game_item".
function claw_manager:create_minigame(map)

  local game = map:get_game()
  local claw_up = map:get_entity("claw_up")
  assert(claw_up ~= nil)
  local claw_up_sprite = claw_up:get_sprite()
  local claw_crane = map:get_entity("claw_crane")
  assert(claw_crane ~= nil)
  local claw_crane_sprite = claw_crane:get_sprite()
  local claw_shadow = map:get_entity("claw_shadow")
  assert(claw_shadow ~= nil)

  local claw_up_start_x, claw_up_start_y = claw_up:get_position()
  local pickable_grabbed = nil
  local platform  -- Invisible platform that avoids the pickable to fall after it is grabbed.
  local sound_timer
  local claw_menu = {}

  function claw_menu:on_started()

    -- Play a sound repeatedly while moving the crane.
    sound_timer = sol.timer.start(claw_menu, 60, function()
      if claw_up:get_movement() ~= nil or claw_crane:get_movement() ~= nil then
        audio_manager:play_sound("misc/trendy_game_lever")
      end
      return true
    end)

    claw_menu:launch_step_1()

  end

  function claw_menu:launch_step_1()

    claw_up_sprite:set_animation("claw_on")

    local claw_movement = sol.movement.create("straight")
    claw_movement:set_angle(0)  -- Go to the right initially.
    claw_movement:set_speed(30)
    claw_movement:set_max_distance(160)
    claw_movement:set_ignore_obstacles(true)
    claw_movement:start(claw_up)

    -- Make the crane and the shadow follow the same movement.
    function claw_movement:on_position_changed()
      local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
      local claw_crane_x, claw_crane_y = claw_crane:get_position()
      local claw_shadow_x, claw_shadow_y = claw_shadow:get_position()
      claw_crane:set_position(claw_up_x, claw_crane_y)
      claw_shadow:set_position(claw_up_x, claw_shadow_y)
    end

    function claw_menu:on_command_pressed(command)
      return true  -- Eat all commands.
    end
    function claw_menu:on_command_released(command)
      if command == "action" then
        claw_movement:stop()
        claw_menu:launch_step_2()
      end
      return true  -- Eat all commands.
    end

  end

  -- Step 2 - Claw vertical movement.
  function claw_menu:launch_step_2()

    -- Start the movement when pressing the command.
    function claw_menu:on_command_pressed(command)
      if command == "action" then
        local claw_movement = sol.movement.create("straight")  -- Then go to the South.
        claw_movement:set_angle(3 * math.pi / 2)
        claw_movement:set_speed(30)
        claw_movement:set_max_distance(128)
        claw_movement:set_ignore_obstacles(true)
        claw_movement:start(claw_up)
        function claw_movement:on_position_changed()
          local claw_up_x, claw_up_y = claw_up:get_position()
          local claw_crane_x, claw_crane_y = claw_crane:get_position()
          local claw_shadow_x, claw_shadow_y = claw_shadow:get_position()
          claw_crane:set_position(claw_crane_x, claw_up_y + 16)
          claw_shadow:set_position(claw_crane_x, claw_up_y + 40)
        end
      end
      return true
    end
    
    -- Stop the movement when releasing the command.
    function claw_menu:on_command_released(command)
      if command == "action" then
        claw_up:stop_movement()
        sol.timer.start(claw_up, 1000, function()
          claw_menu:launch_step_3()
        end)
      end
      return true
    end

  end

  -- Step 3: Move the bottom of the claw downwards.
  function claw_menu:launch_step_3()

    function claw_menu:on_command_pressed(command)
      return true
    end
    function claw_menu:on_command_released(command)
      return true
    end

    local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
    local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()

    local claw_chain = map:create_custom_entity({
      direction = 3,
      layer = claw_up_layer,
      x = claw_up_x,
      y = claw_up_y,
      width = 16,
      height = 16,
    })
    
    local claw_chain_sprite = sol.sprite.create("entities/claw_chain")
    function claw_chain:on_pre_draw()
      if claw_chain:exists() then
        -- Draw the links.
        local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
        claw_up_y = claw_up_y + 8
        local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
        claw_crane_y = claw_crane_y - 8
        local num_chains = claw_crane_y - claw_up_y
        local x1, y1 = claw_up_x, claw_up_y
        local x2, y2 = claw_crane_x, claw_crane_y - 5

        for i = 0, num_chains - 1 do
          local chain_x = x1 + (x2 - x1) * i / num_chains
          local chain_y = y1 + (y2 - y1) * i / num_chains
          map:draw_visual(claw_chain_sprite, chain_x, chain_y)
        end
      end
    end

    local claw_movement = sol.movement.create("path")
    claw_movement:set_path{6,6}
    claw_movement:set_speed(10)
    claw_movement:set_ignore_obstacles(true)
    claw_movement:start(claw_crane, function()
      claw_movement:stop()
      claw_menu:launch_step_4()
    end)

  end

  -- Step 4: Grab the pickable.
  function claw_menu:launch_step_4()

    claw_up_sprite:set_animation("claw_down_crane")
    claw_crane_sprite:set_animation("opening", function()
      claw_crane_sprite:set_animation("opened")
      sol.timer.start(claw_crane, 1000, function()
        claw_crane_sprite:set_animation("closing", function()
          claw_crane_sprite:set_animation("closed")
          sol.timer.start(claw_up, 1000, function()
            for pickable in map:get_entities("game_item") do
              if pickable_grabbed == nil and claw_shadow:get_distance(pickable) < 8 then
                audio_manager:play_sound("misc/trendy_game_win")
                pickable_grabbed = pickable
                local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
                platform = map:create_custom_entity({
                  direction = 0,
                  x = claw_crane_x,
                  y = claw_crane_y + 8,
                  layer = claw_crane_layer,
                  width = 16,
                  height = 16,
                })
                platform:set_modified_ground("traversable")  -- Avoid the pickable to fall on the lower layer again.
                function pickable_grabbed:on_position_changed(x, y)
                  platform:set_position(x, y)
                end
                pickable_grabbed:set_position(claw_crane_x, claw_crane_y + 8, claw_crane_layer)
              end
            end
            claw_menu:launch_step_5()
          end)
        end)
      end)
    end)

  end

  -- Step 5: Make the bottom of the claw go back to the upper part.
  function claw_menu:launch_step_5()
    
    local claw_movement = sol.movement.create("target")
    claw_movement:set_target(claw_up, 0, 16)
    claw_movement:set_speed(30)
    claw_movement:set_ignore_obstacles(true)

    function claw_movement:on_position_changed()
      local claw_up_x, claw_up_y = claw_up:get_position()
      local claw_crane_x, claw_crane_y = claw_crane:get_position()
      if pickable_grabbed ~= nil then
        pickable_grabbed:set_position(claw_crane_x, claw_crane_y + 8)
      end
    end

    claw_movement:start(claw_crane, function()
      claw_movement:stop()
      claw_menu:launch_step_6()
    end)    

  end

  -- Step 6: Go back to the initial position.
  function claw_menu:launch_step_6()

    local claw_up_x, claw_up_y = claw_up:get_position()
    local claw_crane_x, claw_crane_y = claw_crane:get_position()
    
    local claw_movement = sol.movement.create("target")
    claw_movement:set_target(claw_up_start_x, claw_up_start_y)
    claw_movement:set_speed(30)
    claw_movement:set_ignore_obstacles(true)
    
    function claw_movement:on_position_changed()
      local claw_up_x, claw_up_y = claw_up:get_position()
      local claw_crane_x, claw_crane_y = claw_crane:get_position()
      claw_crane:set_position(claw_up_x, claw_up_y + 16)
      claw_shadow:set_position(claw_up_x, claw_up_y + 40)
      if pickable_grabbed ~= nil then
        pickable_grabbed:set_position(claw_crane_x, claw_crane_y + 8)
      end
    end
    claw_movement:start(claw_up, function()
      claw_movement:stop()
      sol.timer.start(claw_up, 1000, function()
        claw_menu:launch_step_7()
      end)
    end)

  end

  -- Step 7: Release the pickable.
  function claw_menu:launch_step_7()

    claw_crane_sprite:set_animation("opening", function()
      claw_crane_sprite:set_animation("opened")
      sol.timer.start(claw_up, 1000, function()
        if platform ~= nil then  
          platform:remove()
        end 
        if pickable_grabbed ~= nil then
          local claw_up_x, claw_up_y = claw_up:get_position()
          pickable_grabbed:set_position(claw_up_x, claw_up_y + 32)
        end
        claw_crane_sprite:set_animation("closing", function()
          claw_up_sprite:set_animation("claw_off")
          claw_crane_sprite:set_animation("closed")
          sol.menu.stop(claw_menu)
        end)
      end)
    end)

  end

  return claw_menu
end

return claw_manager