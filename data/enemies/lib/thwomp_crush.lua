local behavior = {}

-- Behavior of an enemy that falls to the ground if the hero is under it, then goes back to it's initial position.
-- The enemy has only one sprite.

-- Example of use from an enemy script:

-- local enemy = ...
-- local behavior = require("enemies/lib/towards_hero")
-- local properties = {
--   sprite = "enemies/globul",
--   life = 1,
--   damage = 2,
--   normal_speed = 32,
--   faster_speed = 32,
--   hurt_style = "normal",
--   push_hero_on_sword = false,
--   pushed_when_hurt = true,
--   ignore_obstacles = false,
--   obstacle_behavior = "flying",
--   detection_distance = 100,
--   movement_create = function()
--     local m = sol.movement.create("random_path")
--     return m
--   end
-- }
-- behavior:create(enemy, properties)

-- The properties parameter is a table.
-- All its values are optional except the sprite.
local audio_manager = require("scripts/audio_manager")
function behavior:create(enemy, properties)

  local falling = false
  local returning_home = false
  local home_x, home_y
  local platform
  local platform_dx, platform_dy
  -- Set default properties.
  if properties.life == nil then
    properties.life = 2
  end
  if properties.damage == nil then
    properties.damage = 2
  end
  if properties.normal_speed == nil then
    properties.normal_speed = 32
  end
  if properties.faster_speed == nil then
    properties.faster_speed = 100
  end
  if properties.hurt_style == nil then
    properties.hurt_style = "normal"
  end
  if properties.pushed_when_hurt == nil then
    properties.pushed_when_hurt = false
  end
  if properties.push_hero_on_sword == nil then
    properties.push_hero_on_sword = true
  end
  if properties.ignore_obstacles == nil then
    properties.ignore_obstacles = false
  end
  if properties.obstacle_behavior == nil then
    properties.obstacle_behavior = "normal"
  end
  if properties.crash_sound == nil then
    properties.crash_sound = "items/bomb_drop"
  end
  if properties.is_walkable == nil then
    properties.is_walkable = false
  end
  if properties.outer_detection_range == nil then
    properties.outer_detection_range=0
  end
  properties.movement_create = function()
      local m = sol.movement.create("straight")
      return m
  end


  function enemy:on_created()
    home_x, home_y=self:get_position()
    self:set_life(properties.life)
    self:set_damage(properties.damage)
    self:create_sprite(properties.sprite)
    self:set_hurt_style(properties.hurt_style)
    self:set_pushed_back_when_hurt(properties.pushed_when_hurt)
    self:set_push_hero_on_sword(properties.push_hero_on_sword)
    self:set_obstacle_behavior(properties.obstacle_behavior)
    local w,h =self:get_sprite():get_size()
    self:set_size(w,h)
    self:set_origin(w/2, h-3)

    self:set_invincible()
    self:get_sprite():set_animation("normal")

    if properties.is_walkable then --Create a platform on it's top
      local x,y,w,h=self:get_bounding_box()
      platform = self:get_map():create_custom_entity({
        x=x,
        y=y,
        layer= self:get_layer(),
        direction = 3,
        width = w,
        height= 8,
        model = "platform_thwomp",
      })
      platform:set_size(w,1)
      platform:set_origin(0,0)
    end
  end

  function enemy:on_position_changed()
    if platform then
      x, y=self:get_bounding_box()
      platform:set_position(x, y)
    end
  end

  function enemy:look_at_hero()
    local hero = self:get_map():get_entity("hero")
    local angle = self:get_angle(hero)
    local sprite = self:get_sprite()
    local n = sprite:get_num_directions()
    local dir_arc = 2*math.pi/n
    local index = math.floor((angle+dir_arc/2)*n/(2*math.pi))%n
    sprite:set_direction(index)
  end

  function enemy:on_obstacle_reached(movement)
    if falling and not sound_played then
      audio_manager:play_sound(properties.crash_sound)
      sound_played = true
      sol.timer.stop_all(self)
      sol.timer.start(enemy, 1000, function()
        local sprite = self:get_sprite()
        sprite:set_animation("normal")
        enemy:go_home()
      end)      
    end
  end

  function enemy:on_restarted()
    if falling then
      self:fall()
    else
      self.go_home()
    end
  end

  function enemy:on_update()
    self:look_at_hero()
  end

  function enemy:check_hero()

    local hero = self:get_map():get_entity("hero")
    local x, _, w = self:get_bounding_box()
    local hx = hero:get_position()
    local hero_is_under_me = hx>=x-properties.outer_detection_range and
                             hx<=x+w+properties.outer_detection_range and
                             self:is_in_same_region(hero)
    if hero_is_under_me and not falling and not returning_home then
      self:fall()
    end
    sol.timer.stop_all(self)
    sol.timer.start(self, 100, function() self:check_hero() end)
  end

  function enemy:fall()
    --print("Crushing time!")
    falling=true
    audio_manager:play_sound("hero/throw")
    enemy:get_sprite():set_animation("falling")    
    local m = sol.movement.create("straight")
    m:set_speed(properties.faster_speed)
    m:set_angle(3*math.pi/2)
    m:set_ignore_obstacles(properties.ignore_obstacles)
    m:start(enemy)
  end

  function enemy:go_home()
    falling = false
    sound_played = false
    returning_home=true 
    enemy:get_sprite():set_animation("normal")
    local m = sol.movement.create("target")
    m:set_speed(properties.normal_speed)
    m:set_target(home_x, home_y)
    m:set_ignore_obstacles(properties.ignore_obstacles)
    m:start(enemy, function()
      returning_home=false
      enemy:check_hero()
    end)
  end
end

return behavior

