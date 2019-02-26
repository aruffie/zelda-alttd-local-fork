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

function behavior:create(enemy, properties)

  local falling = false
  local returning_home = false
  local home_x, home_y
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
    self:set_size(16, 16)
    self:set_origin(8, 13)
    self:set_invincible()
  end


  function enemy:on_obstacle_reached(movement)
    if falling then
      local sprite = self:get_sprite()
      sprite:get_animation(falling)
      self:go_home()
      self:check_hero()
    end
  end

  function enemy:on_restarted()
    if falling then
    self:fall()

    else
      self.go_home()
      self:check_hero()
    end
  end

  function enemy:check_hero()

    local hero = self:get_map():get_entity("hero")
    local x, _, w = self:get_bounding_box()
    local hx = hero:get_position()
    local hero_is_under_me = hx>=x and hx<=x+w and self:is_in_same_region(hero)
    local angle = self:get_angle(hero)
    local sprite = self:get_sprite()
    sprite:set_animation("normal")
    local n = sprite:get_num_directions()
    sprite:set_direction(math.floor(angle * n/(2*math.pi)))
    if hero_is_under_me and not falling and not returning_home then
      self:fall()
    end
    sol.timer.stop_all(self)
    sol.timer.start(self, 100, function() self:check_hero() end)
  end

  function enemy:fall()
    falling=true
    local m = sol.movement.create("straight")
    m:set_speed(properties.faster_speed)
    m:set_angle(3*math.pi/2)
    m:set_ignore_obstacles(properties.ignore_obstacles)
    m:start(enemy)
  end

  function enemy:go_home()
    falling=false
    returning_home=true 
    local m = sol.movement.create("target")
    m:set_speed(properties.normal_speed)
    m:set_target(home_x, home_y)
    m:set_ignore_obstacles(properties.ignore_obstacles)
    m:start(enemy, function()
      returning_home=false
    end)
  end
end

return behavior

