require "names"

local entity = util.table.deepcopy(data.raw.container["steel-chest"])
entity.name = DUMPSTER_ENTITY_NAME
entity.icon = "__toy-box__/graphics/dumpster-icon.png"
entity.picture = { 
	filename = "__toy-box__/graphics/dumpster-entity.png",
    width = 38,
    height = 32,
    shift = {0.1, 0}
}
entity.minable.result = DUMPSTER_ENTITY_NAME
entity.inventory_size = 59

local item = util.table.deepcopy(data.raw.item["steel-chest"])
item.name = DUMPSTER_ENTITY_NAME
item.icon = "__toy-box__/graphics/dumpster-icon.png"
item.order = "a[items]-y[toy-box-dumpster]"
item.place_result = DUMPSTER_ENTITY_NAME

local recipe = util.table.deepcopy(data.raw.recipe["steel-chest"])
recipe.name = DUMPSTER_ENTITY_NAME
recipe.enabled = true
recipe.ingredients = {{"raw-wood", 1}}
recipe.result = DUMPSTER_ENTITY_NAME

data:extend({entity, item, recipe})
