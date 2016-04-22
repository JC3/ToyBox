--[[
This idea of dynamically generated styles was copied from Outsider's Advanced Logistics System.
https://forums.factorio.com/viewtopic.php?f=92&t=14388 
  
The code below goes through everything defined in data.raw and creates a button style named
toy-box-item-icons-X, where X is replaced with the item name. Couple of notes:

  - We can't just go through data.raw.item, we have to do everything, because item types
    aren't always "item" (e.g. "mining-tool" for the iron-axe, etc.)
  - We do test to see if it is a creatable item by making sure it has flags set and that 
    the flags contain goes-to-main-inventory or goes-to-quickbar. The reason is just to get
	the graphics right. There are many non-item things in data.raw that have the same name
	as an item but have the wrong icon. This way we make sure we're getting item graphics.
	Checking for these flags is the only way I know of to test if an object is an item.
  - We want to do this in data-final-fixes so we get all items, and all items created by any
    mods the player may have loaded, too.
--]]

require "util"
require "config"
require "names"


--[[
Returns a picture table given an icon filename, optionally highlighted (a boolean) as
in the case of click / hover.
--]]

function item_picture (icon, highlight) 
	local pic = {
		filename = icon,
		width = 32,
		height = 32
	}
	if USE_CHECKBOXES then
		pic.shift = { 0, -8 }
	end
	if highlight then
		-- setting values > 1 seems to just make the image disappear. in any case this
		-- is just temporary until i figure out how to draw a slot-style highlighted bg.
		pic.tint = {r=0.5,g=0.5,b=0.5,a=1}
	end
	return pic
end


--[[
Returns a graphical_set table given an icon filename, optionally highlighted (a boolean)
as in the case of click / hover.
--]]

function item_graphical_set (icon, highlight) 
	return {
		type = "monolith",
		monolith_image = item_picture(icon, highlight)
	}
end


--[[
Check if an object has a flag set. Note that data.raw is not LuaItemPrototype yet, so there is
no .has_flag() function. We just check in .flags.
--]]

function has_flag (flags, flag)
	if not flags then
		return false
	end
	for _,f in pairs(flags) do
		if f == flag then
			return true
		end
	end
	return false
end


--[[
Check if an object is probably an item (we hope). See comments at top of file.
--]]

function probably_an_item (e) 
	return has_flag(e.flags, "goes-to-quickbar") or has_flag(e.flags, "goes-to-main-inventory")
end


--[[
Go through all defined data, look for items and create styles. See comments at
top of file.
--]]

for _,types in pairs(data.raw) do
	for _,entity in pairs(types) do
		if entity.icon and probably_an_item(entity) then
			if USE_CHECKBOXES then
				local style = {
					-- we base on checkbox, not button, because buttons mercilessly scale their images
					type = "checkbox_style", 
					parent = ITEM_BUTTON_BASE_STYLE,
					checked = item_picture(entity.icon, false)
				}
				data.raw["gui-style"].default[ITEM_BUTTON_STYLE_PREFIX .. entity.name] = style
			else
				local style = {
					-- we base on checkbox, not button, because buttons mercilessly scale their images
					type = "button_style", 
					parent = ITEM_BUTTON_BASE_STYLE,
					default_graphical_set = item_graphical_set(entity.icon, false),
					hovered_graphical_set = item_graphical_set(entity.icon, true),
					clicked_graphical_set = item_graphical_set(entity.icon, true),
					disabled_graphical_set = item_graphical_set(entity.icon, false)
				}
				data.raw["gui-style"].default[ITEM_BUTTON_STYLE_PREFIX .. entity.name] = style
			end
		end
	end
end
