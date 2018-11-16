
--[[ 
After suspending the game, stop using the boots. This is necessary
to avoid a problem if a dialog is started/finished when using the boots.
Do not stop using the boots if the game is paused/unpaused.
--]]
function item:on_suspended(suspended)
  local game = item:get_game()
  if suspended and not game:is_paused() then
    item:finish_using()
  end
end




-- Start jump while running.
function item:start_jump()
  local game = self:get_game()
  local hero = game:get_hero()
  local map = game:get_map()
  
  -- Do not jump if: already jumping, carrying, bad ground,...
  ----- ADD MORE RESTRICTIONS HERE!!!!
  if hero.is_jumping then return end
  if hero.custom_carry then return end
  local ground = hero:get_ground_below()
  if not is_jumpable_ground(ground) then return end
  
  -- Freeze the hero.
  --hero:freeze()
  
  -- Add jumping state.
  hero.is_jumping = true
  
  -- Destroy ground effect timer.
  if ground_effect_timer then 
    ground_effect_timer:stop()
    ground_effect_timer = nil
  end
  -- Destroy sound timer.
  if sounds_timer then
    sounds_timer:stop()
    sounds_timer = nil
  end
  
  -- Play jump sound.
  sol.audio.play_sound("jump")
  
  -- The hero can jump. Change custom state, save solid position.
  game:set_custom_command_effect("action", nil)
  game:set_custom_command_effect("attack", nil)
  hero:save_solid_ground() -- TODO: delete this later.
  
  -- Change animation set to display the jump.
  hero:set_fixed_animations("jumping", "jumping")
  hero:set_animation("jumping")
  
  -- Change movement speed.
  hero:get_movement():set_speed(jumping_speed)
  
  -- Create shadow platform with traversable ground that follows the hero under him.
  local x,y,layer = hero:get_position()
  local tile = map:create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  local sprite = tile:create_sprite("shadows/shadow_big_dynamic")
  local nb_frames = 32 -- Number of frames of the current animation.
  local frame_delay = jump_duration/nb_frames
  sprite:set_animation("walking")
  sprite:set_frame_delay(frame_delay) 
  function tile:on_update() tile:set_position(hero:get_position()) end -- Follow the hero.
  
  -- Shift the sprite during the jump. Use a parabolic trajectory.
  local instant = 0
  sol.timer.start(self, 1, function()
    local tn = instant/jump_duration
    local height = math.floor(4*max_height*tn*(1-tn))
    hero:get_sprite():set_xy(0, -height)
    -- Continue shifting while jumping.
    instant = instant+1
    if hero.is_jumping then return true end
  end)
  
  -- Finish the jump.
  sol.timer.start(self, jump_duration, function()
  
    hero:set_fixed_animations(nil, nil)
    tile:remove()
    
    -- If ground is empty, move hero to lower layer.
    local x,y,layer = hero:get_position()
    local ground = hero:get_ground_below()
    local min_layer = map:get_min_layer()
    while ground == "empty" and layer > min_layer do
      layer = layer-1
      hero:set_position(x,y,layer)
      ground = hero:get_ground_below() 
    end
    
    -- Ground effects.
    if ground == "deep_water" or ground == "shallow_water" then
      -- If the ground has water, create a splash effect.
      map:create_ground_effect("water_splash", x, y, layer, "splash")
    elseif ground == "grass" then
      -- If the ground has grass, create leaves effect.
      map:create_ground_effect("falling_leaves", x, y, layer, "bush")
    end
    
    -- Restore custom states.
    game:set_custom_command_effect("action", nil)
	  game:set_custom_command_effect("attack", nil)
    
    -- Restore solid ground when possible.
    ground = hero:get_ground_below()
    if is_jumpable_ground(ground) then
      hero:save_solid_ground()
      hero:reset_solid_ground()
    end

    -- Finish the jump.
    hero.is_jumping = false
    item:set_finished()
  end)
  
end
--]]