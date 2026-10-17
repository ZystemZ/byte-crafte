extends RefCounted

# Fonte única para receitas já conectadas à interface. A estação documenta
# onde a receita é válida; a grade 3x3 ainda é aberta pelo inventário.
const RECIPES: Array[Dictionary] = [
	{
		"id": "oak_planks",
		"quick_action": "planks",
		"name": "4 tábuas",
		"item": 7,
		"quantity": 4,
		"max_stack": 99999,
		"station": "inventory",
		"ingredients": [{"item": 4, "quantity": 1}],
		"grid_match": "single_item",
		"grid_item": 4,
		"grid_count": 1
	},
	{
		"id": "sticks",
		"quick_action": "sticks",
		"name": "4 gravetos",
		"item": "gravetos",
		"quantity": 4,
		"max_stack": 99999,
		"station": "inventory",
		"ingredients": [{"item": 7, "quantity": 2}],
		"grid_match": "vertical_pair",
			"grid_item": 7,
			"grid_count": 2
		},
		{
			"id": "wheat_seeds",
			"quick_action": "wheat_seeds",
			"name": "2 sementes de trigo",
			"item": "sementes_trigo",
			"quantity": 2,
			"max_stack": 9999,
			"station": "inventory",
			"ingredients": [{"item": 1, "quantity": 1}],
			"grid_match": "single_item",
			"grid_item": 1,
			"grid_count": 1
		},
		{
			"id": "wood_pickaxe",
		"quick_action": "pickaxe",
		"name": "Picareta de madeira",
		"item": "picareta",
		"quantity": 1,
		"max_stack": 999,
		"station": "inventory",
		"ingredients": [
			{"item": 7, "quantity": 3},
			{"item": "gravetos", "quantity": 2}
		],
			"grid_match": "exact_pattern",
			"pattern": [7, 7, 7, null, "gravetos", null, null, "gravetos", null]
		},
		{
			"id": "crafting_table",
			"quick_action": "crafting_table",
			"name": "Mesa de craft",
			"item": "mesa_craft",
			"quantity": 1,
			"max_stack": 99,
			"station": "inventory",
			"ingredients": [{"item": 7, "quantity": 4}],
			"grid_match": "four_planks",
			"grid_item": 7,
			"grid_count": 4
		},
		{
			"id": "torch",
			"quick_action": "torch",
			"name": "4 tochas",
			"item": "tocha",
			"quantity": 4,
			"max_stack": 999,
			"station": "inventory",
			"ingredients": [{"item": "gravetos", "quantity": 1}, {"item": 15, "quantity": 1}],
			"grid_match": "exact_pattern",
			"pattern": [15, null, null, null, "gravetos", null, null, null, null]
		},
		{
			"id": "cooked_meat",
			"quick_action": "cooked_meat",
			"name": "Carne cozida",
			"item": "carne_cozida",
			"quantity": 2,
			"max_stack": 9999,
			"station": "campfire",
			"ingredients": [{"item": 12, "quantity": 1}, {"item": 15, "quantity": 1}],
			"grid_match": "exact_pattern",
			"pattern": [12, null, null, null, 15, null, null, null, null]
		},
		{
			"id": "iron_ingot",
			"quick_action": "iron_ingot",
			"name": "Lingote de ferro",
			"item": "ferro",
			"quantity": 1,
			"max_stack": 9999,
			"station": "crafting_table",
			"ingredients": [{"item": 3, "quantity": 3}, {"item": 15, "quantity": 1}],
			"grid_match": "exact_pattern",
			"pattern": [3, 3, null, 3, 15, null, null, null, null]
		},
		{
			"id": "iron_pickaxe",
			"quick_action": "iron_pickaxe",
			"name": "Picareta de ferro",
			"item": "picareta_ferro",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": "ferro", "quantity": 3}, {"item": "gravetos", "quantity": 2}],
			"grid_match": "exact_pattern",
			"pattern": ["ferro", "ferro", "ferro", null, "gravetos", null, null, "gravetos", null]
		},
		{
			"id": "iron_axe",
			"quick_action": "iron_axe",
			"name": "Machado de ferro",
			"item": "machado_ferro",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": "ferro", "quantity": 3}, {"item": "gravetos", "quantity": 2}],
			"grid_match": "exact_pattern",
			"pattern": ["ferro", "ferro", null, "ferro", "gravetos", null, null, "gravetos", null]
		},
		{
			"id": "iron_sword",
			"quick_action": "iron_sword",
			"name": "Espada de ferro",
			"item": "espada_ferro",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": "ferro", "quantity": 2}, {"item": "gravetos", "quantity": 1}],
			"grid_match": "exact_pattern",
			"pattern": ["ferro", null, null, "ferro", null, null, "gravetos", null, null]
		},
		{
			"id": "leather_helmet",
			"quick_action": "leather_helmet",
			"name": "Capacete de couro",
			"item": "armadura_couro_cabeca",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": 13, "quantity": 5}],
			"grid_match": "exact_pattern",
			"pattern": [13, 13, 13, 13, null, 13, null, null, null]
		},
		{
			"id": "leather_chestplate",
			"quick_action": "leather_chestplate",
			"name": "Peitoral de couro",
			"item": "armadura_couro_peito",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": 13, "quantity": 8}],
			"grid_match": "exact_pattern",
			"pattern": [13, null, 13, 13, 13, 13, 13, 13, 13]
		},
		{
			"id": "leather_leggings",
			"quick_action": "leather_leggings",
			"name": "Calças de couro",
			"item": "armadura_couro_pernas",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": 13, "quantity": 7}],
			"grid_match": "exact_pattern",
			"pattern": [13, 13, 13, 13, null, 13, 13, null, 13]
		},
		{
			"id": "leather_boots",
			"quick_action": "leather_boots",
			"name": "Botas de couro",
			"item": "armadura_couro_botas",
			"quantity": 1,
			"max_stack": 1,
			"station": "crafting_table",
			"ingredients": [{"item": 13, "quantity": 4}],
			"grid_match": "exact_pattern",
			"pattern": [null, null, null, 13, null, 13, 13, null, 13]
		},
		{
			"id": "crystal_lantern",
			"quick_action": "crystal_lantern",
			"name": "Lanterna de cristal",
			"item": "lanterna_cristal",
			"quantity": 2,
			"max_stack": 999,
			"station": "crafting_table",
			"ingredients": [{"item": 18, "quantity": 1}, {"item": 15, "quantity": 1}],
			"grid_match": "exact_pattern",
			"pattern": [18, null, null, null, 15, null, null, null, null]
		}
]


static func get_quick_recipe(action_id: String) -> Dictionary:
	for recipe: Dictionary in RECIPES:
		if str(recipe.get("quick_action", "")) == action_id:
			return recipe.duplicate(true)
	return {}


static func find_grid_recipe(grid: Array) -> Dictionary:
	if grid.size() != 9:
		return {}
	for recipe: Dictionary in RECIPES:
		var matches := false
		match str(recipe.get("grid_match", "")):
			"single_item":
				matches = _is_single_item_grid(grid, recipe.get("grid_item", null), int(recipe.get("grid_count", 0)))
			"vertical_pair":
				matches = _is_vertical_pair_grid(grid, recipe.get("grid_item", null), int(recipe.get("grid_count", 0)))
			"four_planks":
				matches = _is_four_corner_grid(grid, recipe.get("grid_item", null))
			"exact_pattern":
				matches = grid == recipe.get("pattern", [])
		if matches:
			return recipe.duplicate(true)
	return {}


static func _is_single_item_grid(grid: Array, item_id: Variant, expected_count: int) -> bool:
	var found := 0
	for cell_item: Variant in grid:
		if cell_item == null:
			continue
		if typeof(cell_item) != typeof(item_id) or cell_item != item_id:
			return false
		found += 1
	return found == expected_count


static func _is_vertical_pair_grid(grid: Array, item_id: Variant, expected_count: int) -> bool:
	var occupied: Array[int] = []
	for index in range(grid.size()):
		var cell_item: Variant = grid[index]
		if cell_item == null:
			continue
		if typeof(cell_item) != typeof(item_id) or cell_item != item_id:
			return false
		occupied.append(index)
	if occupied.size() != expected_count:
		return false
	return occupied[0] % 3 == occupied[1] % 3 and abs(occupied[0] - occupied[1]) == 3


static func _is_four_corner_grid(grid: Array, item_id: Variant) -> bool:
	var corners := [0, 2, 6, 8]
	for index in range(grid.size()):
		if index in corners:
			if typeof(grid[index]) != typeof(item_id) or grid[index] != item_id:
				return false
		elif grid[index] != null:
			return false
	return true
