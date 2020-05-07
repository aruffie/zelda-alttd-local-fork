local enemy = ...
local sprite = enemy:create_sprite("enemies/pincer")

-- Restart settings.
function enemy:on_restarted()
  sprite:set_xy(-60,20)
end
