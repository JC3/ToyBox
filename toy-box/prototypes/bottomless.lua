require "names"

local entity = util.table.deepcopy(data.raw.container["steel-chest"])
entity.name = BOTTOMLESS_ENTITY_NAME
entity.icon = "__toy-box__/graphics/bottomless-icon.png"
entity.picture.filename = "__toy-box__/graphics/bottomless-entity.png"
entity.minable.result = BOTTOMLESS_ENTITY_NAME
entity.inventory_size = 59

local item = util.table.deepcopy(data.raw.item["steel-chest"])
item.name = BOTTOMLESS_ENTITY_NAME
item.icon = "__toy-box__/graphics/bottomless-icon.png"
item.order = "a[items]-y[toy-box-bottomless]"
item.place_result = BOTTOMLESS_ENTITY_NAME

local recipe = util.table.deepcopy(data.raw.recipe["steel-chest"])
recipe.name = BOTTOMLESS_ENTITY_NAME
recipe.enabled = true
recipe.ingredients = {{"raw-wood", 1}}
recipe.result = BOTTOMLESS_ENTITY_NAME

data:extend({entity, item, recipe})
