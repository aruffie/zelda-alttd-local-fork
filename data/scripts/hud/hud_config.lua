-- Defines the elements to put in the HUD
-- and their position on the game screen.

-- You can edit this file to add, remove or move some elements of the HUD.

-- Each HUD element script must provide a method new()
-- that creates the element as a menu.
-- See for example scripts/hud/hearts.

-- Negative x or y coordinates mean to measure from the right or bottom
-- of the screen, respectively.

local hud_config = {

  -- Hearts meter.
  {
    menu_script = "scripts/hud/hearts",
    x = -89,
    y = 8,
  },

  -- Rupee counter.
  {
    menu_script = "scripts/hud/rupees",
    x = 8,
    y = -20,
  },

  -- Small key counter.
  {
    menu_script = "scripts/hud/small_keys",
    x = -36,
    y = -18,
  },

  -- Floor view.
  {
    menu_script = "scripts/hud/floor",
    x = 5,
    y = 70,
  },

  -- Item icon for slot 1.
  {
    menu_script = "scripts/hud/item_icon",
    x = 9,
    y = 6,
    slot = 1,  -- Item slot (1 or 2).
  },

  -- Item icon for slot 2.
  {
    menu_script = "scripts/hud/item_icon",
    x = 62,
    y = 6,
    slot = 2,  -- Item slot (1 or 2).
  },

  -- Attack icon.
  {
    menu_script = "scripts/hud/attack_icon",
    x = 35,
    y = 6,
    dialog_x = 15,
    dialog_y = 20,
  },

  -- Action icon.
  {
    menu_script = "scripts/hud/action_icon",
    x = 50,
    y = 28,
    dialog_x = 30,
    dialog_y = 42,
  },
}

return hud_config
