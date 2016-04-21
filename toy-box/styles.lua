require "config"
require "names"

data.raw["gui-style"].default[MAIN_BUTTON_STYLE] = {
	type = "button_style",
	parent = "button_style",
	left_click_sound = {{
		filename = "__core__/sound/gui-click.ogg",
        volume = 1
    }}
}

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
		parent = "button_style",
		width = 32,
		height = 32,
		left_click_sound = {{
			filename = "__core__/sound/gui-click.ogg",
			volume = 1
		}}
	}
end
