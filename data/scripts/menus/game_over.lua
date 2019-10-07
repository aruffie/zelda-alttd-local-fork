-- Script that creates a game-over menu for a game.

-- Usage:
-- require("scripts/menus/game_over")

-- Include scripts.
require("scripts/multi_events")
local automation = require("scripts/automation/automation")
local messagebox = require("scripts/menus/messagebox")
local audio_manager = require("scripts/audio_manager")

-- Initializes the game over menu for the game.
local function initialize_game_over_features(game)
  -- No need to initialize it if already done.
  if game.game_over_menu ~= nil then
    return
  end

  -- Sets the menu on the game.
  local game_over_menu = {}
  game.game_over_menu = game_over_menu

  -- Start the game over menu when the game needs it.
  game:register_event("on_game_over_started", function(game)
      -- Attach the game-over menu to the map so that the map's fade-out
      -- effect applies to it when restarting the game.
        sol.menu.start(game:get_map(), game_over_menu)
    end)

-- Called when this menu is started.
  function game_over_menu:on_started()
    local quest_w, quest_h = sol.video.get_quest_size()

    -- Backup current state.
    game_over_menu.backup_game_state()

    -- Hide the hero.
    game:get_hero():set_visible(false)

    -- Adapt the HUD
    game:set_hud_mode("no_buttons")
    game:bring_hud_to_front()
    game:set_custom_command_effect("action", "")
    game:set_custom_command_effect("attack", "")

    -- Background
    game_over_menu.clouds = {}
    for i = 1, 4 do
      local clouds = sol.surface.create("menus/game_over/game_over_clouds_"..i..".png")
      local clouds_w, clouds_h = clouds:get_size()
      game_over_menu.clouds[i] = {
        image = clouds,
        delta = 0,
        width = clouds_w,
        height = clouds_h,
        x = 0,
      }
      clouds:set_opacity(0)
    end
    sol.timer.start(game_over_menu, 1000 / 15, function()
        for i, clouds in ipairs(game_over_menu.clouds) do
          clouds.delta = clouds.delta + 1
          clouds.x = (clouds.delta / i) % clouds.width
          if clouds.x == 0 then
            clouds.delta = 0
          end
        end
        return true
      end)

    game_over_menu.background = sol.surface.create(quest_w, quest_h)
    game_over_menu.background:fill_color({29, 34, 55})
    game_over_menu.background:set_opacity(0)

    game_over_menu.mountain = sol.surface.create("menus/game_over/game_over_mountain.png")
    game_over_menu.mountain:set_opacity(0)

    game_over_menu.stars = sol.sprite.create("menus/game_over/game_over_stars")
    game_over_menu.stars:set_opacity(0)

    game_over_menu.moon = sol.surface.create("menus/game_over/game_over_moon.png")
    game_over_menu.moon:set_opacity(0)

    -- Title
    game_over_menu.title_w, game_over_menu.title_h = 120, 23
    game_over_menu.title_x, game_over_menu.title_y = math.ceil((quest_w - game_over_menu.title_w) / 2), 32
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
    local hero_x, hero_y = game:get_hero():get_position()
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
      "drug",
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

-- Saves the current game state, to restore it after the menu
-- is finished.
  function game_over_menu:backup_game_state()
    game_over_menu.backup_action = game:get_custom_command_effect("action")
    game_over_menu.backup_attack = game:get_custom_command_effect("attack")
    game_over_menu.backup_hud_mode = game:get_hud_mode()
    game_over_menu.backup_music = sol.audio.get_music()
    local hero = game:get_hero()
    game_over_menu.backup_hero_visible = hero:is_visible()
  end

-- Restores the game state to what it was before starting the menu.
  function game_over_menu:restore_game_state(restore_music)
    -- Restore hero.
    local hero = game:get_hero()
    if hero ~= nil then
      hero:set_visible(game_over_menu.backup_hero_visible)
    end

    -- Restore HUD.
    game:set_custom_command_effect("action", game_over_menu.backup_action)
    game:set_custom_command_effect("attack", game_over_menu.backup_attack)
    game:set_hud_mode(game_over_menu.backup_hud_mode)

    -- Restore music.
    if restore_music then
      sol.audio.play_music(game_over_menu.backup_music)
    end
  end

-- Goes to the menu's next step.
  function game_over_menu:next_step()
    game_over_menu:set_step(game_over_menu.step_index + 1)
  end

-- Sets the specific step to the menu.
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
    elseif step == "drug" then
      game_over_menu:step_drug()
    elseif step == "title" then
      game_over_menu:step_title()
    elseif step == "ask_save" then
      game_over_menu:step_ask_save()
    elseif step == "ask_continue" then
      game_over_menu:step_ask_continue()
    end
  end

-- Step: Starting up.
  function game_over_menu:step_init()
    game_over_menu:next_step()
  end

-- Step: Black circle fade in around the hero.
  function game_over_menu:step_fade_in()
    sol.audio.stop_music()
    game_over_menu.fade_sprite:set_animation("close", function()
        game_over_menu.background:set_opacity(255)
        game_over_menu.stars:fade_in()
        game_over_menu.moon:fade_in()
        game_over_menu.mountain:fade_in()
        local clouds_count = #game_over_menu.clouds
        local fade_delay = 20
        for i, clouds in ipairs(game_over_menu.clouds) do
          clouds.image:fade_in(fade_delay, function()
              if i == clouds_count then
                game_over_menu:next_step()
              end
            end)
        end
      end)

    game_over_menu.hero_dead_sprite:set_paused(false)
    game_over_menu.hero_dead_sprite:set_animation("dying")
    audio_manager:play_sound("hero/dying")
  end

-- Step: heal the hero if he has a fairy in a bottle.
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
          local restored_heart_count = 7
          game:add_life(restored_heart_count * 4)

          -- Wait for the hearts to be refilled.
          sol.timer.start(game_over_menu, 250 * restored_heart_count, function()
              game_over_menu.fairy_sprite:fade_out(10)
              game_over_menu.background:set_opacity(0)
              game_over_menu.fade_sprite:set_animation("open", function()
                  sol.audio.play_music(game_over_menu.backup_music)
                  game:stop_game_over()
                  game_over_menu:restore_game_state(true)
                  sol.menu.stop(game_over_menu)
                end)
            end)
        end)
    else
      -- Go to next step.
      game_over_menu:next_step()
    end
  end
  
-- Step: heal the hero if he has a drug.
  function game_over_menu:step_drug()
    if not game:get_value("game_over_skip_drug") then
      -- Check if the player has a drug.
      local item = game:get_item("drug")
      if item:get_variant() > 0 then
          item:set_variant(0)
        -- Wait for the hearts to be refilled.
        -- Restore 7 hearts.
        local restored_heart_count = 7
        game:add_life(restored_heart_count * 4)
        sol.timer.start(game_over_menu, 250 * restored_heart_count, function()
          game_over_menu.fairy_sprite:fade_out(10)
          game_over_menu.background:set_opacity(0)
          game_over_menu.fade_sprite:set_animation("open", function()
            sol.audio.play_music(game_over_menu.backup_music)
            game:stop_game_over()
            game_over_menu:restore_game_state(true)
            sol.menu.stop(game_over_menu)
          end)
        end)
      else
        -- Go to next step.
        game_over_menu:next_step()
      end
    else  
      -- Go to next step.
      game_over_menu:next_step()
    end
    game:set_value("game_over_skip_drug", false)
  end

-- Step: show the Game Over title.
  function game_over_menu:step_title()
    
    -- Add the death to the total death count.
    local death_count = game:get_value("death_count") or 0
    game:set_value("death_count", death_count + 1)
    -- Play the game over music.
    audio_manager:play_music("82_game_over")

    -- Hide the hero.
    game_over_menu.hero_dead_sprite:fade_out(10, function()
        -- Launch animations.
        local letter_count = #game_over_menu.letters
        for i, letter in ipairs(game_over_menu.letters) do
          local timer_delay = (i - 1) * game_over_menu.anim_duration / 6

          if i == letter_count then
            letter.automation.on_finished = function()
              game_over_menu:next_step()
            end
          end

          sol.timer.start(game_over_menu, timer_delay, function()
              letter.automation:start()
            end)
        end
      end)
  end

-- Step: ask the player if he wants to save.
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

-- Step: ask the player if he wants to continue or not.
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
        if result == 1 then
          -- Restore some life.
          local restored_heart_count = 7
          game:add_life(restored_heart_count * 4)

          -- Wait for the hearts to be refilled before quitting the menu.
          sol.timer.start(game_over_menu, 250 * restored_heart_count, function()
              game_over_menu:restore_game_state(false)
              game:set_hud_enabled(false)
              game:start()
            end)
        elseif result == 2 then
          -- Restart Solarus.
          sol.main.reset()
        end
      end)
  end

-- Called when this menu has to be drawn.
  function game_over_menu:on_draw(dst_surface)
    local dst_surface_w, dst_surface_h = dst_surface:get_size()

    -- Fade.
    if game_over_menu.step_index >= game_over_menu.step_indexes["fade_in"] then
      game_over_menu.fade_sprite:draw(dst_surface)
      game_over_menu.background:draw(dst_surface)

      local stars_w, stars_h = game_over_menu.stars:get_size()
      game_over_menu.stars:draw(dst_surface, (dst_surface_w - stars_w) / 2, 0)

      game_over_menu.moon:draw(dst_surface, 48, 72)

      local mountain_w, mountain_h = game_over_menu.mountain:get_size()
      game_over_menu.mountain:draw(dst_surface, (dst_surface_w - mountain_w) / 2, dst_surface_h - mountain_h)

      for i = #game_over_menu.clouds, 1, -1 do
        local clouds = game_over_menu.clouds[i]
        local clouds_x, clouds_y = math.floor(clouds.x), dst_surface_h - clouds.height
        clouds.image:draw(dst_surface, clouds_x, clouds_y)
        if clouds.x > 0 then
          clouds.image:draw(dst_surface, clouds_x - clouds.width, clouds_y)
        end
      end
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

-- Called when a command is pressed by the player.
  function game_over_menu:on_command_pressed(command)
    -- Block player's input as soon as the menu is opened.
    return true
  end
end

-- Set up the game-over menu on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_game_over_features)

return true
