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

  -- Magic bar.
  -- {
  --   menu_script = "scripts/hud/magic_bar",
  --   x = -104,
  --   y = 27,
  -- },

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

  -- Pause icon.
  {
    menu_script = "scripts/hud/pause_icon",
    x = 23,
    y = 6,
  },

  -- Item icon for slot 1.
  {
    menu_script = "scripts/hud/item_icon",
    x = 9,
    y = 28,
    slot = 1,  -- Item slot (1 or 2).
  },

  -- Item icon for slot 2.
  {
    menu_script = "scripts/hud/item_icon",
    x = 62,
    y = 28,
    slot = 2,  -- Item slot (1 or 2).
  },

  -- Attack icon.
  {
    menu_script = "scripts/hud/attack_icon",
    x = 35,
    y = 28,
    dialog_x = 15,
    dialog_y = 20,
  },

  -- Action icon.
  {
    menu_script = "scripts/hud/action_icon",
    x = 50,
    y = 50,
    dialog_x = 30,
    dialog_y = 42,
  },
}

return hud_config
