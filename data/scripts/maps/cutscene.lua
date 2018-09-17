-- @author std::gregwar
--
-- This script allows to run your code in a co-routine, to write cinematics without callbacks.
-- The passed function is run in a special environment that expose various helpers.
--
-- Usage:
--
-- require() the script, use start_on_map function to start a function in the special environment
--
-- Example:
--
-- --In a map script file
--
-- local cutscene = require('scripts/maps/cutscene')
--
-- local game, map, hero = --init those vals as always
--
-- -- somewhere
--   cutscene.start_on_map(map,function()
--     dialog("sample_dialog") --display a dialog, waiting for it to finish
--     wait(100) -- wait some time
--     local mov = sol.movement.create(...) --create a movement like anywhere else
--     movement(mov,a_movable) -- execute the movement and wait for it to finish
--     animation(a_sprite,"anim_name") -- play an animation and wait for it to finish
--    end)
-- 
-- -- control flow
-- -- the main advantage of this is to be able to use if,else,for,while during the cinematics
--
-- Example:
--   cutscene.start_on_map(map,function()
--    local response = dialog("dialog_with_yes_no_answer")
--    if response then --
--      dialog("dialog for yes")
--    else
--      dialog("dialog for no")
--    end
--   end)
-- ---------
--  Helpers
-- ---------
--
-- wait(time)                         -- suspend execution of the cinematic for time [ms]
-- dialog(dialog_id,[info])           -- display the dialog (with optional info) and resume exec when it finishes
-- movement(a_movement,a_movable)     -- start the given movement on the given movable, resume execution when movement finishes
-- animation(a_sprite,animation_id)   -- play the animation on the given sprite and wait for it to finish
-- run_on_main(a_function)            -- run a given closure on the main thread
-- wait_for(method,object,args...)    -- wait for a method or function that accept a callback as last argument (that you must ommit, the helper adds it for you)
-- return                             -- at any time, returning from the function will end the cutscene
--
-- note that code inside the function is not restrained to those helpers,
-- any valid code still works, those helper are just here to offer blocking primitives
--
-- ----------
--  Launcher
-- ----------
-- -- map : the map where the cinematic is run, serve as context for the timers
-- -- a_function : the closure that will be run in the special environment
-- local handle = cutscene.start_on_map(map,a_function)
--
--
--
-- handle.abort() -- abort the cutscene from outside the special function (aborting from the inside is just 'return')
--
-- --------------------------------------------------------------------------------------


local co_cut = {}
local coroutine = coroutine

function co_cut.start_on_map(map,func)
  local game = map:get_game()
  local thread = coroutine.create(func)

  local aborted = false

  local function resume_thread(...)
    local status, err = coroutine.resume(thread,...)
    if not status then
      error(err) --forward errors
    end
  end

  local function yield()
    local ress = {coroutine.yield()}
    if aborted then
      coroutine.yield() --final yield, never shall we return
    end
    return unpack(ress)
  end

  local cells = {}
  --suspend cinematic execution for a while
  function cells.wait(time)
    local timer = sol.timer.start(game,time,resume_thread)
    -- resume normal engine execution
    yield()
    return timer
  end

  function cells.run_on_main(func)
    sol.timer.start(game,0,function()
                      func()
                      resume_thread()
    end)
    return yield()
  end

  function cells.dialog(id,info)
    if info then
      game:start_dialog(id,info,resume_thread)
    else
      game:start_dialog(id,resume_thread)
    end
    return yield()
  end

  function cells.movement(movement,entity)
    movement:start(entity,resume_thread)
    return yield()
  end

  function cells.animation(sprite,anim_name)
    sprite:set_animation(anim_name,resume_thread)
    return yield()
  end

  --run and wait a function that takes args and then a callback
  function cells.wait_for(method,...)
    local args = {...}
    table.insert(args,resume_thread)
    method(unpack(args))
    return yield()
  end

  local function abort()
   aborted = true --mark coroutine as dead to prevent further execution
  end

  --inherit global scope
  setmetatable(cells,{__index=getfenv(2)}) --get the env of calling function
  setfenv(func,cells) --
  resume_thread() -- launch coroutine to start executing it's content
  return {abort=cells.abort} --return a handle that you can use to abort the coroutine
end


return co_cut
