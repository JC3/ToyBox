require "names"

local entity = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-passive-provider"])
entity.name = LOGISTIC_BOTTOMLESS_ENTITY_NAME
entity.icon = "__toy-box__/graphics/logistic-bottomless-icon.png"
entity.picture = { 
	filename = "__toy-box__/graphics/logistic-bottomless-entity.png",
    width = 38,
    height = 32,
    shift = {0.1, 0}
}
entity.minable.result = LOGISTIC_BOTTOMLESS_ENTITY_NAME
entity.inventory_size = 59

local item = util.table.deepcopy(data.raw.item["logistic-chest-passive-provider"])
item.name = LOGISTIC_BOTTOMLESS_ENTITY_NAME
item.icon = "__toy-box__/graphics/logistic-bottomless-icon.png"
item.order = "b[storage]-y[toy-box-logistic-bottomless]"
item.place_result = LOGISTIC_BOTTOMLESS_ENTITY_NAME

local recipe = util.table.deepcopy(data.raw.recipe["logistic-chest-passive-provider"])
recipe.name = LOGISTIC_BOTTOMLESS_ENTITY_NAME
recipe.result = LOGISTIC_BOTTOMLESS_ENTITY_NAME

data:extend({entity, item, recipe})

table.insert(data.raw["technology"]["construction-robotics"].effects, { 
	type = "unlock-recipe", 
	recipe = LOGISTIC_BOTTOMLESS_ENTITY_NAME
})

table.insert(data.raw["technology"]["logistic-robotics"].effects, { 
	type = "unlock-recipe", 
	recipe = LOGISTIC_BOTTOMLESS_ENTITY_NAME
})
