extends Resource
class_name CardResource

# Card definition properties
var id: String = ""
var title: String = ""
var card_type: String = ""  # ice, agenda, asset, program, etc.
var subtypes: Array = []
var cost: int = 0
var faction: String = ""  # corp, runner, or specific faction

# Additional properties based on type
var strength: int = 0  # For ice and icebreakers
var memory_cost: int = 0  # For programs
var advancement_requirement: int = 0  # For agendas
var agenda_points: int = 0  # For agendas
var rez_cost: int = 0  # For corp cards
var trash_cost: int = 0  # For corp cards

# Card text and visual information
var text: String = ""
var flavor_text: String = ""
var illustrator: String = ""
var art_path: String = ""

# Effect definitions
var effects: Dictionary = {}

func _init(data = null):
	if data:
		from_dictionary(data)

func from_dictionary(data: Dictionary) -> void:
	# Core properties
	if "id" in data:
		id = data.id
	if "title" in data:
		title = data.title
	if "type" in data:
		card_type = data.type
	if "cost" in data:
		cost = data.cost
	if "faction" in data:
		faction = data.faction
	if "text" in data:
		text = data.text
	
	# Handle subtypes
	if "subtype" in data:
		if data.subtype is Array:
			subtypes = data.subtype.duplicate()
		else:
			subtypes = [data.subtype]
	
	# Type-specific properties
	if "strength" in data:
		strength = data.strength
	if "memory_cost" in data:
		memory_cost = data.memory_cost
	if "advancement_requirement" in data:
		advancement_requirement = data.advancement_requirement
	if "agenda_points" in data:
		agenda_points = data.agenda_points
	if "rez_cost" in data:
		rez_cost = data.rez_cost
	if "trash_cost" in data:
		trash_cost = data.trash_cost
	
	# Visual information
	if "flavor_text" in data:
		flavor_text = data.flavor_text
	if "illustrator" in data:
		illustrator = data.illustrator
	if "art_path" in data:
		art_path = data.art_path
	
	# Effects
	if "effects" in data:
		effects = data.effects.duplicate(true)
	elif "effect" in data:  # Legacy support
		effects = data.effect.duplicate(true)

func to_dictionary() -> Dictionary:
	var dict = {
		"id": id,
		"title": title,
		"type": card_type,
		"subtype": subtypes,
		"cost": cost,
		"faction": faction,
	}
	
	# Only include non-default values
	if text:
		dict["text"] = text
	
	if strength > 0:
		dict["strength"] = strength
	
	if memory_cost > 0:
		dict["memory_cost"] = memory_cost
	
	if advancement_requirement > 0:
		dict["advancement_requirement"] = advancement_requirement
	
	if agenda_points > 0:
		dict["agenda_points"] = agenda_points
	
	if rez_cost > 0:
		dict["rez_cost"] = rez_cost
	
	if trash_cost > 0:
		dict["trash_cost"] = trash_cost
	
	if flavor_text:
		dict["flavor_text"] = flavor_text
	
	if illustrator:
		dict["illustrator"] = illustrator
	
	if art_path:
		dict["art_path"] = art_path
	
	if not effects.is_empty():
		dict["effects"] = effects.duplicate(true)
	
	return dict

func is_valid() -> bool:
	# Check required fields
	if id.is_empty():
		return false
	
	if card_type.is_empty():
		return false
	
	# Passed all validation checks
	return true
