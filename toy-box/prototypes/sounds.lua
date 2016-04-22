--[[
Concept of using an explosion to play a sound copied from Supercheese's
Red Alerts mod https://forums.factorio.com/viewtopic.php?f=92&t=19579

We're using this as a hack to play a sound when the user clicks one of the
buttons (because we're using checkboxes (with the icons as the checkmarks to
display the graphics (because buttons don't support disabling image scaling))
as the buttons) because checkboxes don't support sound. Got it?
--]]

require "names"

data:extend({{
	type = "explosion",
	name = BUTTON_CLICK_SOUND_NAME,
	flags = {"not-on-map"},
	animations = {{
		filename = "__toy-box__/graphics/empty.png",
		priority = "low",
		width = 32,
		height = 32,
		frame_count = 1,
		line_length = 1,
		animation_speed = 1
	}},
	light = {intensity = 0, size = 0},
	sound =	{{
		filename = "__core__/sound/gui-click.ogg",
		volume = 1
	}}
}})
