require "config"
require "names"

data.raw["gui-style"].default[BASE_SOUND_BUTTON_STYLE] = {
	type = "button_style",
	parent = "button_style",
	left_click_sound = {{
		filename = "__core__/sound/gui-click.ogg",
		volume = 1
	}}
}

data.raw["gui-style"].default[MAIN_BUTTON_STYLE] = {
	type = "button_style",
	parent = BASE_SOUND_BUTTON_STYLE
}

data.raw["gui-style"].default[ITEM_TABLE_STYLE] = {
	type = "table_style",
	parent = "slot_table_style"
	-- todo: see if there's a workaround for https://forums.factorio.com/viewtopic.php?f=7&t=24068
}	

data.raw["gui-style"].default[SETTINGS_BUTTON_STYLE] = {
	type = "button_style",
	parent = BASE_SOUND_BUTTON_STYLE,
	width = (USE_CHECKBOXES and 36 or 32),
	height = (USE_CHECKBOXES and 36 or 32),
	top_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	right_padding = 0,
	align = "center"
}

data.raw["gui-style"].default[MISC_BUTTON_STYLE] = {
	type = "button_style",
	parent = BASE_SOUND_BUTTON_STYLE,
	top_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	right_padding = 0,
	align = "center"
}

data.raw["gui-style"].default[ACTION_BUTTON_STYLE] = {
	type = "button_style",
	--parent = MISC_BUTTON_STYLE,
	--width = 96
	parent = "dialog_button_style"
}

data.raw["gui-style"].default[DESCRIPTION_LABEL_STYLE] = {
	type = "label_style",
	parent = "caption_label_style",
	minimal_height = 30,
	align = "center"
}

data.raw["gui-style"].default[CATEGORY_BUTTON_STYLE] = {
	type = "button_style",
	parent = MISC_BUTTON_STYLE,
	font = CATEGORY_FONT_NAME,
	default_font_color = { r=0.98, g=0.66, b=0.22 },
	hovered_font_color = { r=1, g=1, b=1 },
	clicked_font_color = { r=1, g=1, b=1 },
	disabled_font_color = { r=0.7, g=0.7, b=0.7 }
}

data.raw["gui-style"].default[FUNCTION_BUTTON_STYLE] = {
	type = "button_style",
	parent = CATEGORY_BUTTON_STYLE,
	default_font_color = { r=0.22, g=0.66, b=0.98 },
	hovered_font_color = { r=1, g=1, b=1 },
	clicked_font_color = { r=1, g=1, b=1 },
	disabled_font_color = { r=0.7, g=0.7, b=0.7 }
}

--[[
data.raw["gui-style"].default[DIALOG_PADDING_LABEL_STYLE] = {
	type = "label_style",
	parent = "label_style",
	width = 180
}
--]]

function checkbox_border_sprite (xoff) 
	return {
		filename = "__toy-box__/graphics/slot-34.png",
		width = 34,
		height = 34,
		x = xoff,
		shift = {0, -8}
	}
end

if USE_CHECKBOXES then
	data.raw["gui-style"].default[ITEM_BUTTON_BASE_STYLE] = {
		-- we base on checkbox, not button, because buttons mercilessly scale their images
		type = "checkbox_style",
		parent = "checkbox_style",
		width = 36,
		height = 36,
		default_background = checkbox_border_sprite(0),
		hovered_background = checkbox_border_sprite(34),
		clicked_background = checkbox_border_sprite(68),
		disabled_background = checkbox_border_sprite(0)
	}
else
	data.raw["gui-style"].default[ITEM_BUTTON_BASE_STYLE] = {
		type = "button_style",
		parent = BASE_SOUND_BUTTON_STYLE,
		width = 32,
		height = 32,
		left_click_sound = {{
			filename = "__core__/sound/gui-click.ogg",
			volume = 1
		}}
	}
end
