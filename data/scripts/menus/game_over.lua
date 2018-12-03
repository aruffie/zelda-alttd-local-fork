-- Script that creates a game-over menu for a game.

-- Usage:
-- require("scripts/menus/game_over")

-- Include scripts.
require("scripts/multi_events")
local automation = require("scripts/automation/automation")
local messagebox = require("scripts/menus/messagebox")
local audio_manager = require("scripts/audio_manager")

local function initialize_game_over_features(game)
  if game.game_over_menu ~= nil then
    -- Already done.
    return
  end
  
  local game_over_menu = {}
  game.game_over_menu = game_over_menu

  -- Start the game over menu when the game needs it.
  game:register_event("on_game_over_started", function(game)
    -- Attach the game-over menu to the map so that the map's fade-out
    -- effect applies to it when restarting the game.
    sol.menu.start(game:get_map(), game_over_menu)
  end)
  
  function game_over_menu:on_started()
    -- Backup current state.
    game_over_menu.backup_music = sol.audio.get_music()
    local hero = game:get_hero()
    game_over_menu.backup_hero_visible = hero:is_visible()
    hero:set_visible(false)
    
    -- Adapt the HUD
    local hud = game.get_hud and game:get_hud() or nil
    if hud then
      game_over_menu.backup_hud_mode = hud:get_mode()
      hud:set_mode("dialog")
      game:bring_hud_to_front()
      game_over_menu.backup_action = game:get_custom_command_effect("action")
      game_over_menu.backup_attack = game:get_custom_command_effect("attack")
      game:set_custom_command_effect("action", "")
      game:set_custom_command_effect("attack", "")
    end

    local quest_w, quest_h = sol.video.get_quest_size()
    
    -- Background
    game_over_menu.background = sol.surface.create("menus/game_over/game_over_background.png")
    game_over_menu.background:set_opacity(0)
    
    game_over_menu.black_surface = sol.surface.create(quest_w, quest_h)
    game_over_menu.black_surface:fill_color({0, 0, 0})
    game_over_menu.black_surface:set_opacity(0)

    -- Title
    game_over_menu.title_w, game_over_menu.title_h = 120, 23
    game_over_menu.title_x, game_over_menu.title_y = math.ceil((quest_w - game_over_menu.title_w) / 2), 48
    game_over_menu.letters = {
      { name = "g", offset = 0},
      { name = "a", offset = 20},
      { name = "m", offset = 33},
      { name = "e", offset = 49},
      { name = "o", offset = 65},
      { name = "v", offset = 86},
      { name = "e", offset = 99},
      { name = "r", offset = 107},
    } 
    game_over_menu.anim_duration = 1000
    for _, letter in pairs(game_over_menu.letters) do
      local sprite = sol.sprite.create("menus/game_over/game_over_title")
      sprite:set_animation(letter.name)
      local x, y = game_over_menu.title_x + letter.offset, - game_over_menu.title_h
      sprite:set_xy(x, y)
      letter.sprite = sprite
      letter.automation = automation:new(game_over_menu, sprite, "elastic_out", game_over_menu.anim_duration, { y = game_over_menu.title_y})
    end
    
    -- Sprites.
    local map = game:get_map()
    local camera_x, camera_y = map:get_camera():get_position()
    local hero_x, hero_y = hero:get_position()
    local hero_dead_x, hero_dead_y = hero_x - camera_x, hero_y - camera_y
    local tunic = game:get_ability("tunic")
    game_over_menu.hero_dead_sprite = sol.sprite.create("hero/tunic" .. tunic)
    game_over_menu.hero_dead_sprite:set_paused(true)
    game_over_menu.hero_dead_sprite:set_animation("dying")
    game_over_menu.hero_dead_sprite:set_direction(0)
    game_over_menu.hero_dead_sprite:set_xy(hero_dead_x, hero_dead_y)

    game_over_menu.fade_sprite = sol.sprite.create("menus/game_over/game_over_fade")
    game_over_menu.fade_sprite:set_xy(hero_dead_x, hero_dead_y)
    
    game_over_menu.fairy_sprite = sol.sprite.create("entities/items")
    game_over_menu.fairy_sprite:set_animation("fairy")
    game_over_menu.fairy_sprite:set_xy(hero_dead_x + 12, hero_dead_y + 21)

    -- Steps.
    game_over_menu.steps = {
      "init",
      "fade_in",
      "fairy",
      "title",
      "ask_save",
      "ask_continue",
    }
    local function invert_table(t)
      local s = {}
      for k, v in pairs(t) do
        s[v] = k
      end
      return s
    end
    game_over_menu.step_indexes = invert_table(game_over_menu.steps)
    game_over_menu.step_index = 0

    -- Launch the animation.
    game_over_menu:set_step(1)
  end

  function game_over_menu:on_finished()
    -- Restore hero.
    local hero = game:get_hero()
    if hero ~= nil then
      hero:set_visible(game_over_menu.backup_hero_visible)
    end

    -- Restore HUD.
    local hud = game.get_hud and game:get_hud() or nil
    if hud then
      hud:set_mode(game_over_menu.backup_hud_mode)
      game:set_custom_command_effect("action", game_over_menu.backup_action)
      game:set_custom_command_effect("attack", game_over_menu.backup_attack)
    end

    -- Restore music.
    sol.audio.play_music(game_over_menu.backup_music)
  end

  function game_over_menu:next_step()
    game_over_menu:set_step(game_over_menu.step_index + 1)
  end

  function game_over_menu:set_step(step_index)
    step_index = math.min(step_index, #game_over_menu.steps)  
    game_over_menu.step_index = step_index
    
    local step = game_over_menu.steps[step_index]
    if step == "init" then
      game_over_menu:step_init()
    elseif step == "fade_in" then
      game_over_menu:step_fade_in()
    elseif step == "fairy" then
      game_over_menu:step_fairy()
    elseif step == "title" then
      game_over_menu:step_title()
    elseif step == "ask_save" then
      game_over_menu:step_ask_save()
    elseif step == "ask_continue" then
      game_over_menu:step_ask_continue()
    end
  end

  function game_over_menu:step_init()
    game_over_menu:next_step()
  end

  function game_over_menu:step_fade_in()
    sol.audio.stop_music()
    game_over_menu.fade_sprite:set_animation("close", function()
      game_over_menu.black_surface:set_opacity(255)
    end)

    game_over_menu.hero_dead_sprite:set_paused(false)
    game_over_menu.hero_dead_sprite:set_animation("dying")
    audio_manager:play_sound("hero/dying")

    sol.timer.start(game_over_menu, 2000, function()
      game_over_menu:next_step()
    end)
  end

  function game_over_menu:step_fairy()
    -- Check if the player has a fairy.
    local bottle_with_fairy = nil
    if game.get_first_bottle_with then
      bottle_with_fairy = game:get_first_bottle_with(6)
    end

    if bottle_with_fairy ~= nil then
      -- Make the bottle empty.
      bottle_with_fairy:set_variant(1)
      
      -- Move the fairy towards the hearts.
      local movement = sol.movement.create("target")
      movement:set_target(240, 22)
      movement:set_speed(96)
      movement:start(game_over_menu.fairy_sprite, function()
        -- Restore 7 hearts.
        game:add_life(7 * 4)

        -- Wait for the hearts to be refilled.
        sol.timer.start(game_over_menu, 1000, function()
          game_over_menu.fairy_sprite:fade_out(10)
          game_over_menu.black_surface:set_opacity(0)
          game_over_menu.fade_sprite:set_animation("open", function()
            sol.audio.play_music(game_over_menu.backup_music)
            game:stop_game_over()
            sol.menu.stop(game_over_menu)
          end)
        end)
      end)
    else
      -- Add the death to the total death count.
      local death_count = game:get_value("death_count") or 0
      game:set_value("death_count", death_count + 1)

      -- Go to next step.
      game_over_menu:next_step()
    end
  end

  function game_over_menu:step_title()
    -- Play the game over music.
    audio_manager:play_music("82_game_over")

    -- Show the background.
    game_over_menu.background:fade_in()

    -- Hide the hero.
    game_over_menu.hero_dead_sprite:fade_out(10, function()  
      -- Launch animations.
      local letter_count = #game_over_menu.letters
      for i, letter in ipairs(game_over_menu.letters) do
        local timer_delay = (i - 1) * game_over_menu.anim_duration / 6
        
        if i == letter_count then
          letter.automation.on_finished = function()
            sol.timer.start(game_over_menu, 750, function()
              game_over_menu:next_step()
            end)
          end
        end
    
        sol.timer.start(game_over_menu, timer_delay, function()
          letter.automation:start()
        end)
      end
    end)
  end

  function game_over_menu:step_ask_save()
    messagebox:show(game_over_menu, 
      -- Text lines.
      {
      sol.language.get_string("save_dialog.save_question_0"),
      sol.language.get_string("save_dialog.save_question_1"),
      },
      -- Buttons
      sol.language.get_string("messagebox.yes"),
      sol.language.get_string("messagebox.no"),
      -- Default button
      1,
      -- Callback called after the user has chosen an answer.
      function(result)
        if result == 1 then
          game:save()
        end
        game_over_menu:next_step()
    end)
  end

  function game_over_menu:step_ask_continue()
    messagebox:show(game_over_menu, 
      -- Text lines.
      {
      sol.language.get_string("save_dialog.continue_question_0"),
      sol.language.get_string("save_dialog.continue_question_1"),
      },
      -- Buttons
      sol.language.get_string("messagebox.yes"),
      sol.language.get_string("messagebox.no"),
      -- Default button
      1,
      -- Callback called after the user has chosen an answer.
      function(result)
        -- Restore 7 hearts.
        game:add_life(7 * 4)

        if result == 1 then
          game:start()
          sol.menu.stop(game_over_menu)
        elseif result == 2 then
          sol.menu.stop(game_over_menu)
          sol.main.reset()
        end
    end)   
  end

  function game_over_menu:on_draw(dst_surface)
    -- Fade.
    if game_over_menu.step_index >= game_over_menu.step_indexes["fade_in"] then
      game_over_menu.fade_sprite:draw(dst_surface)
      game_over_menu.black_surface:draw(dst_surface)
    end

    -- Background.
    if game_over_menu.step_index > game_over_menu.step_indexes["fade_in"] then
      game_over_menu.background:draw(dst_surface)
    end

    -- Title.
    for _, letter in pairs(game_over_menu.letters) do
      letter.sprite:draw(dst_surface)
    end


    -- Hero.
    game_over_menu.hero_dead_sprite:draw(dst_surface)

    -- Fairy.
    if game_over_menu.step_index == game_over_menu.step_indexes["fairy"] then
      game_over_menu.fairy_sprite:draw(dst_surface)
    end

  end

  function game_over_menu:on_command_pressed(command)
    -- Block player's input as soon as the menu is opened.
    return true
  end
end

-- Set up the game-over menu on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_game_over_features)

return true
