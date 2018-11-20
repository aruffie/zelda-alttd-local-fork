local claw_manager = {}
local claw_step  = 1
local claw_movement
local claw_step = nil
local claw_up_start_x = nil
local claw_up_start_y = nil
local claw_is_sound_activated
local claw_entity_found = nil
local claw_timer

function claw_manager:init_map(map)
  
  local game = map:get_game()
  local hero = map:get_hero()
  local claw_up = map:get_entity("claw_up")
  local claw_up_sprite = claw_up:get_sprite()
 claw_step = 1
  claw_up_start_x, claw_up_start_y = claw_up:get_position()
  claw_up_sprite:set_animation("claw_on")
  hero:freeze()
  claw_manager:launch_step_1(map)
  claw_timer = sol.timer.start(claw_up, 60, function()
    if claw_is_sound_activated then
      audio_manager:play_sound("trendy_game_lever")
    end
    return true
  end)
  
end

-- Step 1 - Claw horizontal movement
function claw_manager:launch_step_1(map)

  local game = map:get_game()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_shadow= map:get_entity("claw_shadow")
  claw_step = 1
  function map:on_command_pressed(button)
    if claw_step == 1 and button == "item_1" then
      claw_movement = sol.movement.create("straight")
      claw_movement:set_angle(0)
      claw_movement:set_speed(30)
      claw_movement:set_max_distance(160)
      claw_movement:set_ignore_obstacles(true)
      claw_movement:start(claw_up)
      claw_is_sound_activated = true
      function claw_movement:on_position_changed()
        local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
        local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
        local claw_shadow_x, claw_shadow_y, claw_crane_layer = claw_shadow:get_position()
        claw_crane:set_position(claw_up_x, claw_crane_y)
        claw_shadow:set_position(claw_up_x, claw_shadow_y)
      end
    end
  end
  function map:on_command_released(button)
      if claw_step == 1 and button == "item_1" then
        claw_is_sound_activated = false
        claw_movement:stop()
        claw_manager:launch_step_2(map)
     end
  end

end

-- Step 2 - Claw vertical movement
function claw_manager:launch_step_2(map)

  local game = map:get_game()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_shadow= map:get_entity("claw_shadow")
  local is_stopped = false
  claw_step = 2
  function game:on_command_pressed(button)
    if claw_step == 2 and button == "item_2" and is_stopped == false then
      claw_movement = sol.movement.create("straight")
      claw_movement:set_angle(3 * math.pi / 2)
      claw_movement:set_speed(30)
      claw_movement:set_max_distance(128)
      claw_movement:set_ignore_obstacles(true)
      claw_movement:start(claw_up)
      claw_is_sound_activated = true
      function claw_movement:on_position_changed()
        local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
        local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
        local claw_shadow_x, claw_shadow_y, claw_shadow_layer = claw_shadow:get_position()
        claw_crane:set_position(claw_crane_x, claw_up_y + 16)
        claw_shadow:set_position(claw_crane_x, claw_up_y + 40)
      end
    end
  end
  function game:on_command_released(button)
      if button == "item_2" and is_stopped == false then
        is_stopped = true
        claw_movement:stop()
        claw_is_sound_activated = false
        sol.timer.start(claw_up, 1000, function()
          claw_manager:launch_step_3(map)
        end)
     end
  end

end

-- Step 3
function claw_manager:launch_step_3(map)

  local game = map:get_game()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
  local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
  claw_step = 3
  claw_movement = sol.movement.create("path")
  claw_movement:set_path{6,6}
  claw_movement:set_speed(10)
  claw_movement:set_ignore_obstacles(true)
  claw_movement:start(claw_crane)
  function claw_movement:on_finished()
    claw_movement:stop()
    claw_manager:launch_step_4(map)
  end
  local claw_chain = map:create_custom_entity({
    direction = 3,
    layer = claw_up_layer,
    x = claw_up_x,
    y = claw_up_y,
    width = 16,
    height = 16,
  })
  claw_chain_sprite = sol.sprite.create("entities/claw_chain")
  function claw_chain:on_pre_draw()
        if claw_chain:exists() and claw_chain:is_enabled() then
          -- Draw the links.
          local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
          claw_up_y = claw_up_y + 8
          local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
          claw_crane_y = claw_crane_y - 8
          local num_chains = claw_crane_y - claw_up_y
          local x1 = claw_up_x
          local y1 = claw_up_y
          local x2 = claw_crane_x
          local y2= claw_crane_y
          y2 = y2 - 5
          for i = 0, num_chains - 1 do
            local chain_x = x1 + (x2 - x1) * i / num_chains
            local chain_y = y1 + (y2 - y1) * i / num_chains
            local skip = direction == 1 and laser_x == source_x and i == 0
            if not skip then
              map:draw_visual(claw_chain_sprite, chain_x, chain_y)
            end
          end
      end
  end
end

-- Step 4
function claw_manager:launch_step_4(map)

  local game = map:get_game()
  local hero = map:get_hero()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
  local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
  local claw_up_sprite = claw_up:get_sprite()
  local claw_crane_sprite = claw_crane:get_sprite()
  claw_step = 4
  claw_up_sprite:set_animation("claw_down_crane")
  claw_crane_sprite:set_animation("opening")
  function claw_crane_sprite:on_animation_finished(animation)
    if animation == "opening" then
      claw_crane_sprite:set_animation("opened")
      sol.timer.start(claw_up, 1000, function()
        claw_crane_sprite:set_animation("closing")
      end)
    elseif animation == "closing"  then
      claw_crane_sprite:set_animation("closed")
      sol.timer.start(claw_up, 1000, function()
        for pickable in map:get_entities("game_item") do
          if claw_entity_found == nil and claw_crane:overlaps(pickable, "sprite") then
            claw_entity_found = pickable
            audio_manager:play_sound("trendy_game_win")
            claw_entity_found:set_position(claw_crane_x, claw_crane_y + 8)
          end
        end
        claw_manager:launch_step_5(map)
      end)
    end
  end

end

-- Step 5
function claw_manager:launch_step_5(map)

  local game = map:get_game()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
  local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
  claw_step = 5
  claw_movement = sol.movement.create("target")
  claw_movement:set_target(claw_up_x, claw_up_y + 16)
  claw_movement:set_speed(30)
  claw_movement:set_ignore_obstacles(true)
  claw_movement:start(claw_crane)
  claw_is_sound_activated = true
  function claw_movement:on_position_changed()
    local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
    local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
    if claw_entity_found ~= nil then
      claw_entity_found:set_position(claw_crane_x, claw_crane_y + 8)
    end
  end
  function claw_movement:on_finished()
      claw_movement:stop()
      claw_is_sound_activated = false
      claw_manager:launch_step_6(map)
  end

end

-- Step 6
function claw_manager:launch_step_6(map)

  local game = map:get_game()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_shadow= map:get_entity("claw_shadow")
  local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
  local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
  claw_step = 6
  claw_movement = sol.movement.create("target")
  claw_movement:set_target(claw_up_start_x, claw_up_start_y)
  claw_movement:set_speed(30)
  claw_movement:set_ignore_obstacles(true)
  claw_movement:start(claw_up)
  claw_is_sound_activated = true
  function claw_movement:on_position_changed()
    local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
    local claw_crane_x, claw_crane_y, claw_crane_layer = claw_crane:get_position()
    local claw_shadow_x, claw_shadow_y, claw_shadow_layer = claw_shadow:get_position()
    claw_crane:set_position(claw_up_x, claw_up_y + 16)
    claw_shadow:set_position(claw_up_x, claw_up_y + 40)
    if claw_entity_found ~= nil then
      claw_entity_found:set_position(claw_crane_x, claw_crane_y + 8)
    end
  end
  function claw_movement:on_finished()
      claw_movement:stop()
      claw_is_sound_activated = false
      sol.timer.start(claw_up, 1000, function()
        claw_manager:launch_step_7(map)
      end)
  end

end

-- Step 7
function claw_manager:launch_step_7(map)

  local game = map:get_game()
  local hero = map:get_hero()
  local claw_up = map:get_entity("claw_up")
  local claw_crane = map:get_entity("claw_crane")
  local claw_up_sprite = claw_up:get_sprite()
  local claw_crane_sprite = claw_crane:get_sprite()
  local claw_up_x, claw_up_y, claw_up_layer = claw_up:get_position()
  claw_step = 7
  claw_crane_sprite:set_animation("opening")
  function claw_crane_sprite:on_animation_finished(animation)
      if animation == "opening" then
        claw_crane_sprite:set_animation("opened")
        sol.timer.start(claw_up, 1000, function()
          if claw_entity_found ~= nil then
            claw_entity_found:set_position(claw_up_x, claw_up_y + 32)
          end
          claw_crane_sprite:set_animation("closing")
        end)
      elseif animation == "closing"  then
        claw_up_sprite:set_animation("claw_off")
        claw_crane_sprite:set_animation("closed")
        claw_step = nil
        hero:unfreeze()
        claw_timer:stop()
        claw_entity_found = nil
        claw_crane:clear_collision_tests()
      end
    end

end


return claw_manager