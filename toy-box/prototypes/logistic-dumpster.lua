require "names"

local entity = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])
entity.name = LOGISTIC_DUMPSTER_ENTITY_NAME
entity.icon = "__toy-box__/graphics/logistic-dumpster-icon.png"
entity.picture = { 
	filename = "__toy-box__/graphics/logistic-dumpster-entity.png",
    width = 38,
    height = 32,
    shift = {0.1, 0}
}
entity.minable.result = LOGISTIC_DUMPSTER_ENTITY_NAME
entity.inventory_size = 59

local item = util.table.deepcopy(data.raw.item["logistic-chest-requester"])
item.name = LOGISTIC_DUMPSTER_ENTITY_NAME
item.icon = "__toy-box__/graphics/logistic-dumpster-icon.png"
item.order = "b[storage]-y[toy-box-logistic-dumpster]"
item.place_result = LOGISTIC_DUMPSTER_ENTITY_NAME

local recipe = util.table.deepcopy(data.raw.recipe["logistic-chest-requester"])
recipe.name = LOGISTIC_DUMPSTER_ENTITY_NAME
recipe.result = LOGISTIC_DUMPSTER_ENTITY_NAME

data:extend({entity, item, recipe})

table.insert(data.raw["technology"]["logistic-system"].effects, { 
	type = "unlock-recipe", 
	recipe = LOGISTIC_DUMPSTER_ENTITY_NAME
})
