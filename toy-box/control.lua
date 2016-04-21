--[[
toy-box-0.1.0, 2016-apr-18

  0.1.0 - Initial release.
  
This is a pretty simple mod that provides an interface for giving yourself items
that is more convenient than typing commands in the console.

TODO:

  - Fix scaling of item graphics.
  - Make item graphic buttons have borders and proper hover/click effects.
  - Categorize item graphics.
  - Provide a trash slot for discarding items.
  - Some interface for "give 1" instead of a whole stack. Can't read modifier key states
    in on_gui_click though.
	
Note that if the game is saved with the GUI displayed and then a new mod is added that
adds new items, you will have to hide then re-show the GUI to force the buttons to update.
--]]

require "defines"
require "util"
require "config"
require "names"


--[[
This is populated on first use by calling ensure_item_info_initialized appropriately. We
do not store this in global, because we want to easily make sure it's up to date with any
items that have been added or removed due to other mods.
--]]

local g_item_info = nil


--[[
Print a message.
Copied from Choumiko's TFC (https://forums.factorio.com/viewtopic.php?f=92&t=4504)
--]]

function debugDump(var, force)
  if false or force then -- s/false/true when debugging
    for i,player in pairs(game.players) do
      local msg
      if type(var) == "string" then
        msg = var
      else
        msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
      end
      player.print(msg)
    end
  end
end


--[[
Ensure global stuff is not nil. Simplifies things everywhere else.
--]]

function ensure_global_init ()

	global.player_open_position = global.player_open_position or {}

end


--[[
Check if an item can be carried. Note that this also matches probably_an_item in the
style creation code in data-final-fixes.lua, so by using this as a filter we shouldn't,
hopefully, be attempting to use styles that don't exist.
--]]

function can_be_carried (e) 

	return e.has_flag("goes-to-quickbar") or e.has_flag("goes-to-main-inventory")

end


--[[
Initialize g_item_info if it's not initialized. This should be called every time 
g_item_info is about to be accessed, to initialize on first use. This is where we load
the list of items we're providing buttons for, determine button names and stack sizes,
etc.

This is a no-op if g_item_info is non-nil already.

Postconditions:

  - g_item_info will be populated with info about the currently known items.
--]]

function ensure_item_info_initialized () 

	if g_item_info then
		return
	end
	
	debugDump("toy-box: initializing g_item_info")
	g_item_info = {}

	for name,item in pairs(game.item_prototypes) do
		if can_be_carried(item) then

			-- For now stack_size will be how many items we give the player.
			local stack_size = 1
			if item.stackable then
				stack_size = item.stack_size
			end

			g_item_info[ITEM_BUTTON_NAME_PREFIX..name] = ({
				item_name = name,
				stack_size = stack_size
			})
			
		end
	end
	
end


--[[
Create the GUI button for the given player.
--]]

function init_for_player (player) 

	if not player.gui.top[MAIN_BUTTON_NAME] then
		player.gui.top.add({
			type = "button",
			name = MAIN_BUTTON_NAME,
			style = MAIN_BUTTON_STYLE,
			caption = {"toy-box-button-collapsed-text"}
		})
	end

end	


--[[
Given a frame, build the Toy Box GUI in it. Right now there isn't much to this.
--]]

function build_gui (frame)

	ensure_item_info_initialized()
	
	-- TODO: Sort items by category. For now just cram them all up there.
	local item_table = frame.add({
		type = "table",
		name = ITEM_TABLE_NAME,
		colspan = 20,
		style = "slot_table_style"
	})
	
	-- Add a button for every item we know about.
	for button_name,info in pairs(g_item_info) do
		item_table.add({
			type = (USE_CHECKBOXES and "checkbox" or "button"),
			name = button_name,
			style = ITEM_BUTTON_STYLE_PREFIX..info.item_name,
			state = true -- ignored if not USE_CHECKBOXES
		}) 
	end

end


--[[
Hide or show the main GUI for the player. Also updates the text on the button with a +/-.
--]]

function toggle_gui (player)

	-- player position is saved on gui open so that we can close it when they move

	if is_gui_present(player) then
		player.gui.left[MAIN_FRAME_NAME].destroy()
		player.gui.top[MAIN_BUTTON_NAME].caption = {"toy-box-button-collapsed-text"}
		global.player_open_position[player.index] = nil
	else
		local frame = player.gui.left.add({
			type = "frame",
			name = MAIN_FRAME_NAME
		})
		build_gui(frame)
		player.gui.top[MAIN_BUTTON_NAME].caption = {"toy-box-button-expanded-text"}
		global.player_open_position[player.index] = player.position
	end

end


--[[
Check if the GUI currently exists.
--]]

function is_gui_present (player)

	if player.gui.left[MAIN_FRAME_NAME] then
		return true
	else
		return false
	end
	
end


--[[
Called when one of the item buttons was clicked. Info must be a value from the
g_item_info table containing info about the clicked item. This will give the 
player one stack of that item.
--]]

function item_button_clicked (player, info) 

	-- Easy.
	player.insert({
		name = info.item_name,
		count = info.stack_size
	})

end


--[[
Called on every tick. If player's have moved from their stored positions, closes
their GUI.
--]]

function check_player_positions () 

	for i,guipos in ipairs(global.player_open_position) do
		
		local curpos = game.players[i].position
		local dx = guipos.x - curpos.x
		local dy = guipos.y - curpos.y
	
		if (dx * dx + dy * dy >= GUI_CLOSE_DISTANCE * GUI_CLOSE_DISTANCE) then
			if is_gui_present(game.players[i]) then
				toggle_gui(game.players[i])
				play_sound(game.players[i], BUTTON_CLICK_SOUND_NAME)
				debugDump("toy-box: Player "..i.." moved, closing GUI.")
			end
		end
		
	end

end

--[[
Play a sound. See sounds.lua.
--]]

function play_sound (player, sound)

	player.surface.create_entity({name = sound, position = player.position})

end


-- event hooks ----------------------------------------------------------------

script.on_init(function() 
	ensure_global_init()
	for i,p in pairs(game.players) do
		init_for_player(p)
	end
end)

script.on_event(defines.events.on_tick, function(event)
	check_player_positions()
end)

script.on_event(defines.events.on_player_created, function(event)
	init_for_player(game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_click, function(event) 
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if (name == MAIN_BUTTON_NAME) then
		toggle_gui(player)
	else
		-- otherwise check if it's an item button and if so, do the thing.
		ensure_item_info_initialized()
		if (g_item_info[name]) then
			-- checkbox hack
			if USE_CHECKBOXES then
				play_sound(player, BUTTON_CLICK_SOUND_NAME)
				event.element.state = true
			end
			-- end checkbox hack
			item_button_clicked(player, g_item_info[name])
		end
	end
end)

script.on_configuration_changed(function(data) 
	ensure_global_init() -- make sure globals initialized on version updates.
	-- no matter what the old/new version, destroy the gui. new mods may have changed available items,
	-- and updates to this mod may break styles (https://forums.factorio.com/viewtopic.php?f=25&t=23968).
	for i,p in pairs(game.players) do
		if is_gui_present(p) then
			debugDump("toy-box: Configuration changed and game saved with GUI open. Destroying old GUI.", true)
			toggle_gui(p)
		end
	end
end)
