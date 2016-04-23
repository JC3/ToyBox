--[[
toy-box-0.2.1, 2016-apr-22

  0.1.0 - Initial release.
  0.1.1 - GUI cleanup.
  0.2.0 - Settings dialog, item categorization.
  0.2.1 - Dumpster and bottomless chests. Moved default options to config.lua.
  
This is a pretty simple mod that provides an interface for giving yourself items
that is more convenient than typing commands in the console.

TODO:

  - Some interface for "give 1" instead of a whole stack. Can't read modifier key states
    in on_gui_click though.
  - Finish graphical category buttons.  
--]]

require "defines"
require "util"
require "config"
require "names"


--[[
These are populated on first use by calling ensure_item_info_initialized appropriately. We
do not store these in global, because we want to easily make sure it's up to date with any
items that have been added or removed due to other mods.
--]]

local g_item_info = nil
local g_item_info_cat = nil


--[[
Default user settings. Must match key names from names.lua.
--]]

local DEFAULT_SETTINGS = {
	autoclose = DEFAULT_AUTOCLOSE,
	no_vehicle_autoclose = DEFAULT_NO_VEHICLE_AUTOCLOSE,
	table_columns = DEFAULT_TABLE_COLUMNS,
	group_items = DEFAULT_GROUP_ITEMS,
	categorize_items = DEFAULT_CATEGORIZE_ITEMS,
	dont_group_all = DEFAULT_DONT_GROUP_ALL
}


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

Postconditions:

  - global.player_data is not nil.
--]]

function ensure_global_init ()

	--[[ player_data is indexed by player index and contains:
	  open_position: player's position when gui opened
	  settings: misc. gui settings
	  category_view: last category viewed
	--]]
	global.player_data = global.player_data or {}
	global.dumpster = global.dumpster or {}			-- this is a list of LuaEntities
	global.bottomless = global.bottomless or {}		-- see bottomless_created()

	-- there's also global.to_chest_update and global.to_position_update, they
	-- aren't initialized here, they're down in the script tick event handler.

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
Initialize g_item_info and friends if they're not initialized. This should be called
every time g_item_info is about to be accessed, to initialize on first use. This is 
where we load the list of items we're providing buttons for, determine button names
and stack sizes, categories, etc.

This is a no-op if g_item_info is non-nil already.

Postconditions:

  - g_item_info will be populated with info about the currently known items.
  - g_item_info_cat will be populated as well.
--]]

function ensure_item_info_initialized () 

	if g_item_info then
		return
	end
	
	debugDump("toy-box: initializing g_item_info")
	g_item_info = {}
	g_item_info_cat = {}

	g_item_info_cat[CATEGORY_BUTTON_NAME_PREFIX.."ALL"] = {
		category = "",
		description = "ALL"
	}
	
	for name,item in pairs(game.item_prototypes) do
		if can_be_carried(item) then

			-- For now stack_size will be how many items we give the player.
			local stack_size = 1
			if item.stackable then
				stack_size = item.stack_size
			end
			
			local infoname = ITEM_BUTTON_NAME_PREFIX..name

			local catname
			if item.group and item.group.name then
				catname = string.upper(item.group.name)
			else
				catname = "UNCATEGORIZED"
			end

			g_item_info[infoname] = {
				item_name = name,
				stack_size = stack_size,
				category = catname,
				group = (item.subgroup and item.subgroup.name or nil)
			}
			
			g_item_info_cat[CATEGORY_BUTTON_NAME_PREFIX..catname] = {
				category = catname,
				description = catname
			}
			
		end
	end
	
end


--[[
Create the GUI button for the given player and initialize their global data.
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
	
	if not global.player_data[player.index] then
		global.player_data[player.index] = {}
	end

end	


--[[
Utility function to get the number of keys in a non-array table.
--]]

function table_length (t) 

	local count = 0
	
	for k,v in pairs(t) do
		count = count + 1
	end
	
	return count
	
end


--[[
Rebuilds the item GUI table, where cat is a g_item_info_cat entry for a category filter, or
nil for no filter. Grouping, category filtering, etc. are taken care of here. No-op if GUI is
not currently visible.

The ITEM_TABLE_FRAME_NAME is the frame that contains the table. The old table is destroyed if
there is one and a new one is created.

Preconditions:
   - If GUI visible, the ITEM_TABLE_FRAME_NAME element exists.
   
Postconditions:
   - ITEM_TABLE_NAME is updated with item buttons.
   - global.player_data[].category_view is set to the category being viewed, a key into
     g_item_info_cat, or nil.

This is called when the GUI is built, and when the category buttons are pressed.
--]]

function rebuild_item_table (player, cat)

	if not is_gui_present(player) then
		return
	end
	
	local table_frame = find_child(player.gui.left[MAIN_FRAME_NAME], ITEM_TABLE_FRAME_NAME)
	local old_table = find_child(table_frame, ITEM_TABLE_NAME)
	local column_count = get_setting(player, SETTING_COLUMNS)
	
	if old_table then
		old_table.destroy()
	end
	
	local item_table = table_frame.add({
		type = "table",
		name = ITEM_TABLE_NAME,
		colspan = column_count,
		style = ITEM_TABLE_STYLE
	})

	local filtercat
	if cat and cat.category and cat.category ~= "" then
		filtercat = cat.category
	else
		filtercat = nil
	end
	
	local group = get_setting(player, SETTING_GROUP)
	if group and get_setting(player, SETTING_NGROUPALL) and filtercat == nil then
		group = false
	end
	
	if not group then
	
		-- This is easy, just add a button for every item we care about.
		for button_name,info in pairs(g_item_info) do
			if filtercat == nil or filtercat == info.category then
				item_table.add({
					type = (USE_CHECKBOXES and "checkbox" or "button"),
					name = button_name,
					style = ITEM_BUTTON_STYLE_PREFIX..info.item_name,
					state = true -- ignored if not USE_CHECKBOXES
				}) 
			end
		end
		
	else
	
		-- This is bit trickier. To maintain table alignment we have to insert spacers
		-- in the table to take up space. TODO: Get rid of this silly thing, and consider
		-- just using multiple tables instead.
		
		-- First organize items into subgroups.
		local grouped_items = {}
		for button_name,info in pairs(g_item_info) do
			local groupname = (info.group and info.group or "")
			if filtercat == nil or filtercat == info.category then
				if not grouped_items[groupname] then
					grouped_items[groupname] = {}
				end
				grouped_items[groupname][button_name] = info
			end
		end
		
		-- Now add things to the table
		for _,group in pairs(grouped_items) do
			for button_name,info in pairs(group) do
				item_table.add({
					type = (USE_CHECKBOXES and "checkbox" or "button"),
					name = button_name,
					style = ITEM_BUTTON_STYLE_PREFIX..info.item_name,
					state = true -- ignored if not USE_CHECKBOXES
				})
			end
			-- Placeholders to take up remaining elements in row
			local count = table_length(group)
			while count % column_count > 0 do
				item_table.add({
					type = "label",
					style = "label_style"
				})
				count = count + 1
			end
		end
	
	end
	
	global.player_data[player.index].category_view = filtercat -- save last viewed category 
	debugDump("toy-box: Last viewed category set to '"..(filtercat and filtercat or "nil").."'")
	
end


--[[
Given a frame, build the Toy Box GUI in it.
--]]

function build_gui (player, frame)

	ensure_item_info_initialized()
	
	local categorize = get_setting(player, SETTING_CATEGORIZE)

	local top_flow = frame.add({
		type = "flow",
		name = "--toy-box-build_gui-211",
		direction = "vertical"
	})
	
	local action_flow = top_flow.add({
		type = "flow",
		direction = "horizontal"
	})
	
	if categorize then
		for bname,catinfo in pairs(g_item_info_cat) do
			action_flow.add({
				type = "button",
				name = bname,
				style = CATEGORY_BUTTON_STYLE,
				caption = catinfo.description
			})
			--[[ coming in 0.2.3 
			if catinfo.category ~= "" then
				action_flow.add({
					type = "checkbox",
					name = bname,
					style = IMG_CATEGORY_BUTTON_STYLE_PREFIX..catinfo.category,
					state = true
				})
			end
			--]]
		end
	end
	
	action_flow.add({
		type = "button",
		name = SETTINGS_BUTTON_NAME,
		style = FUNCTION_BUTTON_STYLE,
		caption = {"toy-box-action-settings"}
	})

	local table_frame = top_flow.add({
		type = "frame",
		name = ITEM_TABLE_FRAME_NAME,
		style = "outer_frame_style"
	})
	
	-- restore last viewed category
	
	local catinfo = nil
	if categorize then
		local lastcatname = global.player_data[player.index].category_view
		if lastcatname then
			debugDump("toy-box: Last viewed category was '"..(lastcatname and lastcatname or "nil").."'")
			for _,info in pairs(g_item_info_cat) do
				if info.category == lastcatname then
					catinfo = info
					break
				end
			end
		end
	end
	
	rebuild_item_table(player, catinfo)
	
end


--[[
Hide or show the main GUI for the player. Also updates the text on the button with a +/-.

Postconditions:
  - GUI state toggled.
  - If GUI opened, global.player_data[].open_position set to player's position, for auto
    close on player movement.
--]]

function toggle_gui (player)

	-- player position is saved on gui open so that we can close it when they move

	if is_gui_present(player) then
		player.gui.left[MAIN_FRAME_NAME].destroy()
		player.gui.top[MAIN_BUTTON_NAME].caption = {"toy-box-button-collapsed-text"}
		global.player_data[player.index].open_position = nil
	elseif is_settings_dialog_present(player) then
		debugDump("toy-box: Settings dialog is open, not showing main GUI.")
	else
		local frame = player.gui.left.add({
			type = "frame",
			style = "inner_frame_in_outer_frame_style",
			name = MAIN_FRAME_NAME
		})
		build_gui(player, frame)
		player.gui.top[MAIN_BUTTON_NAME].caption = {"toy-box-button-expanded-text"}
		global.player_data[player.index].open_position = player.position
	end

end


--[[
Hide GUI if visible. Returns true if GUI was visible, false if not. I know it's weird that
"hide" is based on "toggle" rather than "toggle" being based on "show" and "hide", but this
was added later.
--]]

function hide_gui (player)

	if is_gui_present(player) then
		toggle_gui(player)
		return true
	else
		return false
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

All of the rest of the code in this module is just to do this one stupid thing.
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
their GUI (depending on current settings).
--]]

function check_player_positions () 

	for i,pdata in ipairs(global.player_data) do
		if pdata.open_position then
		
			local player = game.players[i]
			local autoclose = get_setting(player, SETTING_AUTOCLOSE)
			
			if autoclose and player.driving and get_setting(player, SETTING_NVAUTOCLOSE) then
				autoclose = false
			end
		
			if autoclose then
				
				local curpos = player.position
				local dx = pdata.open_position.x - curpos.x
				local dy = pdata.open_position.y - curpos.y
			
				if (dx * dx + dy * dy >= GUI_CLOSE_DISTANCE * GUI_CLOSE_DISTANCE) then
					if is_gui_present(player) then
						toggle_gui(player)
						play_sound(player, BUTTON_CLICK_SOUND_NAME)
						debugDump("toy-box: Player "..i.." moved, closing GUI.")
					end
				end

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


--[[
Get the value of a setting from global.player_data[].settings. If it isn't set, this will
return the value from DEFAULT_SETTINGS instead.

Preconditions:
  - global.player_data[player.index] is not nil
--]]

function get_setting (player, key) 

	local pdata = global.player_data[player.index]
	
	if pdata.settings and pdata.settings[key] ~= nil then
		return pdata.settings[key]
	else
		return DEFAULT_SETTINGS[key]
	end

end


--[[
Store a player setting.

Preconditions:
  - global.player_data[player.index] is not nil
  
Postconditions:
  - global.player_data[player.index].settings exists.
  - The specified key/value has been added to that table.
--]]

function save_setting (player, key, value)

	local pdata = global.player_data[player.index]
	
	if not pdata.settings then
		pdata.settings = {}
	end
	
	pdata.settings[key] = value
	
end


--[[
Return true if settings dialog is visible, false if not.
--]]

function is_settings_dialog_present (player)

	return player.gui.center[SETTINGS_FRAME_NAME] and true or false
	
end


--[[
Helper function to add a label and a GUI element to the settings dialog.
--]]

function add_setting_elements (parent, labelcaption, element)

	parent.add({
		type = "label",
		style = DESCRIPTION_LABEL_STYLE,
		caption = labelcaption
	})
	
	return parent.add(element)

end


--[[
Show the settings dialog. This will also hide the main GUI (which will be displayed again when
the settings dialog is closed. The settings dialog is populated with the current settings, and
will update the stored settings if OK is pressed. This is a no-op if the dialog is already 
visible.

Preconditions:
  - global.player_data[player.index] exists.

Postconditions:
  - Main GUI is hidden.
  - Settings dialog is displayed in player.gui.center.
--]]

function show_settings_dialog (player) 

	hide_gui(player)
	
	if not is_settings_dialog_present(player) then
	
		local frame = player.gui.center.add({
			type = "frame",
			style = "inner_frame_in_outer_frame_style",
			name = SETTINGS_FRAME_NAME,
			caption = {"toy-box-settings"}
		})

		-- all elements between settings elements and the frame must have a name
		-- so that settings elements can be found by find_child.
		
		local mainflow = frame.add({
			type = "flow",
			name = "--toy-box-637",	-- must have a name for find_child
			direction = "vertical"
		})

		local maintable = mainflow.add({
			type = "table",
			name = "--toy-box-643",	-- must have a name for find_child
			style = "table_style",
			colspan = 2
		})
		
		add_setting_elements(maintable, {"toy-box-settings-columns"}, {
			type = "textfield",
			name = SETTING_COLUMNS_ELEMENT_NAME,
			style = "number_textfield_style",
			text = get_setting(player, SETTING_COLUMNS)
		})
		
		add_setting_elements(maintable, {"toy-box-settings-categorize"}, {
			type = "checkbox",
			name = SETTING_CATEGORIZE_ELEMENT_NAME,
			style = "checkbox_style",
			state = get_setting(player, SETTING_CATEGORIZE)
		})
		
		add_setting_elements(maintable, {"toy-box-settings-group"}, {
			type = "checkbox",
			name = SETTING_GROUP_ELEMENT_NAME,
			style = "checkbox_style",
			state = get_setting(player, SETTING_GROUP)
		})

		add_setting_elements(maintable, {"toy-box-settings-ngroupall"}, {
			type = "checkbox",
			name = SETTING_NGROUPALL_ELEMENT_NAME,
			style = "checkbox_style",
			state = get_setting(player, SETTING_NGROUPALL)
		})
		
		add_setting_elements(maintable, {"toy-box-settings-autoclose"}, {
			type = "checkbox",
			name = SETTING_AUTOCLOSE_ELEMENT_NAME,
			style = "checkbox_style",
			state = get_setting(player, SETTING_AUTOCLOSE)
		})
		
		add_setting_elements(maintable, {"toy-box-settings-nvautoclose"}, {
			type = "checkbox",
			name = SETTING_NVAUTOCLOSE_ELEMENT_NAME,
			style = "checkbox_style",
			state = get_setting(player, SETTING_NVAUTOCLOSE)
		})
		
		local buttonflow = mainflow.add({
			type = "flow",
			direction = "horizontal"
		})
				
		buttonflow.add({
			type = "button",
			name = SETTINGS_OK_BUTTON_NAME,
			style = ACTION_BUTTON_STYLE,
			caption = {"toy-box-ok"}
		})

		buttonflow.add({
			type = "button",
			name = SETTINGS_CANCEL_BUTTON_NAME,
			style = ACTION_BUTTON_STYLE,
			caption = {"toy-box-cancel"}
		})
		
	end

end


--[[
Utility function to recursively find a child element by name. Every element in the path
from parent to child must have a name for this to work. Returns nil if child not found.
--]]

function find_child (parent, name)

	for _,childname in pairs(parent.children_names) do
		if parent[childname] then
			if childname == name then
				return parent[childname]
			end
			local result = find_child(parent[childname], name)
			if result then
				return result
			end
		end
	end
	
	return nil

end


--[[
Close the settings dialog, possibly saving settings if accept is true. Restores visibility of main
GUI window. No-op if dialog not visible.

Preconditions:
  - global.player_data[player.index] exists.
  
Postconditions:
  - global.player_data[player.index].settings set to valid values if accept = true, unmodified
    if accept = false.
  - Settings dialog destroyed.
  - Main GUI visible.
--]]

function close_settings_dialog (player, accept)

	if is_settings_dialog_present(player) then

		local dialog = player.gui.center[SETTINGS_FRAME_NAME]
	
		if accept then 
			save_setting(player, SETTING_AUTOCLOSE, find_child(dialog, SETTING_AUTOCLOSE_ELEMENT_NAME).state)
			save_setting(player, SETTING_NVAUTOCLOSE, find_child(dialog, SETTING_NVAUTOCLOSE_ELEMENT_NAME).state)
			save_setting(player, SETTING_CATEGORIZE, find_child(dialog, SETTING_CATEGORIZE_ELEMENT_NAME).state)
			save_setting(player, SETTING_GROUP, find_child(dialog, SETTING_GROUP_ELEMENT_NAME).state)
			save_setting(player, SETTING_NGROUPALL, find_child(dialog, SETTING_NGROUPALL_ELEMENT_NAME).state)
			local columns = tonumber(find_child(dialog, SETTING_COLUMNS_ELEMENT_NAME).text)
			if columns == nil or columns < 3 then
				columns = 3
			elseif columns > 100 then
				columns = 100
			end
			save_setting(player, SETTING_COLUMNS, columns)
		end
	
		dialog.destroy()	
		toggle_gui(player) -- only way to get to settings dialog now is through main one, so show it again		
		return true
		
	else
	
		return false
	
	end

end


--[[
Update behavior of normal and logistic dumpsters. Just empties the trash. Called
periodically on dumpster entities, ent should be a LuaEntity.
--]]

function dumpster_update (ent)

	ent.clear_items_inside()

end


--[[
Called when dumpster built, adds to tracking list, ent should be a LuaEntity.

Postconditions:
  - Entity is in global.dumpster.
--]]

function dumpster_created (ent)

	table.insert(global.dumpster, ent)

end


--[[
Called when dumpster destroyed, removes from tracking list. Also removes the items
inside it so the player doesn't get them back if we're between updates. The 'ent'
should be a LuaEntity.

Postconditions:
  - Entity is no longer in global.dumpster.
--]]

function dumpster_destroyed (ent)

	for i,e in ipairs(global.dumpster) do
		if e == ent then
			ent.clear_items_inside()
			table.remove(global.dumpster, i)
			break
		end
	end

end


--[[
Update behavior of normal and logistic bottomless chests. Determines the item 
the chest should be producing, if necessary, and fills the inventory with that
item. Called periodically on bottomless chests entities, 'info' should be the
table inserted by bottomless_created() -- see that function for details.

The high level behavior this goes for is the first item a player inserts into
a bottomless chest beceomes the item it produces. Also, once that is determined,
any other items besides that one that are found in the chest are destroyed so
they don't get in the way (I think this makes the in-game behavior of these
chests a little more clean-cut and predictable).
--]]

function bottomless_update (info)

	local ent = info.entity

	-- If we don't know our item yet, figure it out.
	if not info.item then
		local contents = ent.get_inventory(defines.inventory.chest).get_contents()
		for item,_ in pairs(contents) do
			info.item = item
			info.stack_size = game.get_item_prototype(item).stack_size
			debugDump("toy-box: Bottomless chest item set to "..item..":"..info.stack_size)
			break
		end
	end -- info.item may be set now
	
	-- If we know our item now, fill 'er up.
	if info.item then
		local inv = ent.get_inventory(defines.inventory.chest)
		-- remove rogue items
		local contents = inv.get_contents()
		for item,number in pairs(contents) do 
			if item ~= info.item then
				inv.remove({name=item,count=number})
			end
		end
		-- fill chest
		local stack = {name=info.item,count=info.stack_size}
		while inv.can_insert(stack) do
			inv.insert(stack)
		end
	end

end


--[[
Called when bottomless chest built, adds to tracking list, ent should be a 
LuaEntity. See code for info about what's added to global.bottomless.

Postconditions:
  - Information about entity is in global.bottomless.
--]]

function bottomless_created (ent)

	table.insert(global.bottomless, {
		entity = ent,		-- The LuaEntity
		item = nil,			-- bottomless_update will set this to the item
		stack_size = nil	-- bottomless_update will set this, too
	})

end


--[[
Called when bottomless chest destroyed, removes from tracking list. Also removes
the items inside it so the player doesn't get them back (since it'll probably 
fill their inventory). The 'ent' should be a LuaEntity.

Postconditions:
  - Information about ent is no longer in global.bottomless.
--]]

function bottomless_destroyed (ent)

	for i,e in ipairs(global.bottomless) do
		if e.entity == ent then
			ent.clear_items_inside()
			table.remove(global.bottomless, i)
			break
		end
	end

end


-- event hooks ----------------------------------------------------------------

script.on_init(function() 
	ensure_global_init()
	for i,p in pairs(game.players) do
		init_for_player(p)
	end
end)

script.on_event(defines.events.on_tick, function(event)
	-- position check
	if not global.to_position_check or global.to_position_check <= 1 then
		check_player_positions()
		global.to_position_check = POSITION_CHECK_INTERVAL
	else
		global.to_position_check = global.to_position_check - 1
	end
	-- chest update
	if not global.to_chest_update or global.to_chest_update <= 1 then
		for _,e in pairs(global.dumpster) do
			dumpster_update(e)
		end
		for _,e in pairs(global.bottomless) do
			bottomless_update(e)
		end
		global.to_chest_update = CHEST_UPDATE_INTERVAL - 1
	else
		global.to_chest_update = global.to_chest_update - 1
	end
end)

script.on_event(defines.events.on_player_created, function(event)
	init_for_player(game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_click, function(event) 
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if name == MAIN_BUTTON_NAME then
		toggle_gui(player)
	elseif name == SETTINGS_BUTTON_NAME then
		show_settings_dialog(player)
	elseif name == SETTINGS_OK_BUTTON_NAME then
		close_settings_dialog(player, true)
	elseif name == SETTINGS_CANCEL_BUTTON_NAME then
		close_settings_dialog(player, false)
	else
		-- otherwise check if it's an item or category button
		ensure_item_info_initialized()
		if (g_item_info[name]) then
			-- checkbox hack
			if USE_CHECKBOXES then
				play_sound(player, BUTTON_CLICK_SOUND_NAME)
				event.element.state = true
			end
			-- end checkbox hack
			item_button_clicked(player, g_item_info[name])
		elseif (g_item_info_cat[name]) then
			rebuild_item_table(player, g_item_info_cat[name])
		end
	end
end)

script.on_event({defines.events.on_built_entity,defines.events.on_robot_built_entity}, function (event)
	if event.created_entity.name == DUMPSTER_ENTITY_NAME or event.created_entity.name == LOGISTIC_DUMPSTER_ENTITY_NAME then
		dumpster_created(event.created_entity)
	elseif event.created_entity.name == BOTTOMLESS_ENTITY_NAME or event.created_entity.name == LOGISTIC_BOTTOMLESS_ENTITY_NAME then
		bottomless_created(event.created_entity)
	end
end)

script.on_event({defines.events.on_entity_died,defines.events.on_robot_pre_mined,defines.events.on_preplayer_mined_item}, function(event)
	if event.entity.name == DUMPSTER_ENTITY_NAME or event.entity.name == LOGISTIC_DUMPSTER_ENTITY_NAME then
		dumpster_destroyed(event.entity)
	elseif event.entity.name == BOTTOMLESS_ENTITY_NAME or event.entity.name == LOGISTIC_BOTTOMLESS_ENTITY_NAME then
		bottomless_destroyed(event.entity)
	end
end)

function enable_if_researched (tech, recipe)
	for i, player in ipairs(game.players) do 
		if player.force.technologies[tech].researched then 
			player.force.recipes[recipe].enabled = true
			debugDump("toy-box: "..tech.." researched, enabling "..recipe..".", true)
		end
	end
end

script.on_configuration_changed(function(data) 

	-- make sure globals initialized on version updates.
	ensure_global_init()
	
	if data.mod_changes ~= nil and data.mod_changes["toy-box"] ~= nil then
	
		local oldv = data.mod_changes["toy-box"].old_version
		local curv = data.mod_changes["toy-box"].new_version
		
		if curv and curv >= "0.2.0" then
			
			debugDump("toy-box: Updating player data...", true)
			
			if not global.player_data then
				global.player_data = {}
			end
			
			if global.player_open_position then
				for i,pos in pairs(global.player_open_position) do
					if not global.player_data[i] then
						global.player_data[i] = {}
					end
					global.player_data[i].open_position = pos
				end
				global.player_open_position = nil -- went away in 0.2.0
			end
			
			for _,p in pairs(game.players) do
				if not global.player_data[p.index] then
					global.player_data[p.index] = {}
				end
			end
			
			-- that got weird. sorry.
			
		end

		if curv and curv >= "0.2.1" then
		
			debugDump("toy-box: Updating entity tables...", true)		
			global.dumpster = global.dumpster or {}
			global.bottomless = global.bottomless or {}

			enable_if_researched("logistic-robotics", LOGISTIC_BOTTOMLESS_ENTITY_NAME)
			enable_if_researched("construction-robotics", LOGISTIC_BOTTOMLESS_ENTITY_NAME)
			enable_if_researched("logistic-system", LOGISTIC_DUMPSTER_ENTITY_NAME)
			
		end
		--[[
		if (oldv == nil or oldv <= "0.1.1") and (curv ~= nil and curv >= "0.2.0") then
			debugDump("toy-box: Updating player data...", true)
			global.player_data = {}
			if global.player_open_position then -- if oldv == 0.1.1
				for i,pos in pairs(global.player_open_position) do
					global.player_data[i] = {}
					global.player_data[i].open_position = pos
				end
				global.player_open_position = nil
			end
		end
		--]]
		
	end

	-- no matter what the old/new version, destroy the gui. new mods may have changed available items,
	-- and updates to this mod may break styles (https://forums.factorio.com/viewtopic.php?f=25&t=23968).
	for i,p in pairs(game.players) do
		if close_settings_dialog(p, false) then
			debugDump("toy-box: Configuration changed and game saved with settings dialog open. Closing settings dialog.", true)
		end
		if hide_gui(p) then
			debugDump("toy-box: Configuration changed and game saved with GUI open. Destroying old GUI.", true)
		end
	end
		
end)
