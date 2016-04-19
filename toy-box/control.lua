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

local GUI_TOY_BOX_BUTTON = "toy-box-button"
local GUI_TOY_BOX_FRAME = "toy-box-frame"
local GUI_ITEM_BUTTON_PREFIX = "toy-box-item-button-"
local GUI_ITEM_STYLE_PREFIX = "toy-box-item-icons-"


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

			g_item_info[GUI_ITEM_BUTTON_PREFIX..name] = ({
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

	if not player.gui.top[GUI_TOY_BOX_BUTTON] then
		player.gui.top.add({
			type = "button",
			name = GUI_TOY_BOX_BUTTON,
			style = "toy-box-button-style",
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
		name = "toy-box-item-table",
		colspan = 20
	})
	
	-- Add a button for every item we know about.
	for button_name,info in pairs(g_item_info) do
		item_table.add({
			type = "button",
			name = button_name,
			style = GUI_ITEM_STYLE_PREFIX..info.item_name
		})
	end

end


--[[
Hide or show the main GUI for the player. Also updates the text on the button with a +/-.
--]]

function toggle_gui (player)

	if player.gui.left[GUI_TOY_BOX_FRAME] then
		player.gui.left[GUI_TOY_BOX_FRAME].destroy()
		player.gui.top[GUI_TOY_BOX_BUTTON].caption = {"toy-box-button-collapsed-text"}
	else
		local frame = player.gui.left.add({
			type = "frame",
			name = GUI_TOY_BOX_FRAME
		})
		build_gui(frame)
		player.gui.top[GUI_TOY_BOX_BUTTON].caption = {"toy-box-button-expanded-text"}
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


-- event hooks ----------------------------------------------------------------

script.on_init(function() 
	for i,p in ipairs(game.players) do
		init_for_player(p)
	end
end)

script.on_event(defines.events.on_player_created, function(event)
	init_for_player(game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_click, function(event) 
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if (name == GUI_TOY_BOX_BUTTON) then
		toggle_gui(player)
	else
		-- otherwise check if it's an item button and if so, do the thing.
		ensure_item_info_initialized()
		if (g_item_info[name]) then
			item_button_clicked(player, g_item_info[name])
		end
	end
end)
