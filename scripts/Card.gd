extends Resource
class_name Card

# Base card class for all cards in the game
# This represents an instance of a card, not the card definition

# Card properties
var id: String
var title: String
var card_type: String  # ice, agenda, asset, program, etc.
var card_subtype: Array[String] = []
var cost: int
var faction: String  # corp, runner, or specific faction

# Additional properties based on type
var strength: int = 0  # For ice and icebreakers
var memory_cost: int = 0  # For programs
var advancement_requirement: int = 0  # For agendas
var agenda_points: int = 0  # For agendas
var rez_cost: int = 0  # For corp cards
var trash_cost: int = 0  # For corp cards

# State information
var is_rezzed: bool = false
var is_installed: bool = false
var advancement_tokens: int = 0
var hosted_cards: Array[Card] = []
var hosted_counters: Dictionary = {}  # counter_type: count
var controller: String = ""  # player_id
var owner: String = ""  # player_id
var location: Dictionary = {}  # where this card is (server, rig, etc.)

# Card text and effect definitions
var text: String
var effect: Dictionary = {}
var current_strength_mod: int = 0

# Visual information
var art_texture: Texture2D
var front_texture: Texture2D
var back_texture: Texture2D

func _init(card_data = null):
	if card_data:
		from_data(card_data)

func from_data(data):
	# Initialize the card from a data dictionary
	id = data.get("id", "")
	title = data.get("title", "")
	card_type = data.get("type", "")
	cost = data.get("cost", 0)
	text = data.get("text", "")
	
	# Handle subtypes as array
	if data.has("subtype"):
		if data.subtype is Array:
			card_subtype = data.subtype
		else:
			card_subtype = [data.subtype]
	
	# Specific properties by card type
	if data.has("strength"):
		strength = data.strength
	
	if data.has("memory_cost"):
		memory_cost = data.memory_cost
	
	if data.has("advancement_requirement"):
		advancement_requirement = data.advancement_requirement
	
	if data.has("agenda_points"):
		agenda_points = data.agenda_points
	
	if data.has("rez_cost"):
		rez_cost = data.rez_cost
	
	if data.has("trash_cost"):
		trash_cost = data.trash_cost
	
	# Card effects
	if data.has("effect"):
		effect = data.effect

func to_data():
	# Convert card to data dictionary for serialization
	var data = {
		"id": id,
		"title": title,
		"type": card_type,
		"cost": cost,
		"text": text,
		"subtype": card_subtype
	}
	
	# Add specific properties based on type
	if strength > 0:
		data.strength = strength
	
	if memory_cost > 0:
		data.memory_cost = memory_cost
	
	if advancement_requirement > 0:
		data.advancement_requirement = advancement_requirement
	
	if agenda_points > 0:
		data.agenda_points = agenda_points
	
	if rez_cost > 0:
		data.rez_cost = rez_cost
	
	if trash_cost > 0:
		data.trash_cost = trash_cost
	
	# Only include effect if not empty
	if not effect.is_empty():
		data.effect = effect
	
	return data

func get_total_strength():
	return strength + current_strength_mod

func add_strength_modifier(amount):
	current_strength_mod += amount

func is_corp_card():
	return card_type in ["ice", "agenda", "asset", "upgrade", "operation", "identity"]

func is_runner_card():
	return card_type in ["program", "hardware", "resource", "event", "identity"]

func add_counter(counter_type, amount=1):
	if not hosted_counters.has(counter_type):
		hosted_counters[counter_type] = 0
	
	hosted_counters[counter_type] += amount

func remove_counter(counter_type, amount=1):
	if hosted_counters.has(counter_type):
		hosted_counters[counter_type] = max(0, hosted_counters[counter_type] - amount)
		
		if hosted_counters[counter_type] == 0:
			hosted_counters.erase(counter_type)
		
		return true
	
	return false

func get_counter(counter_type):
	return hosted_counters.get(counter_type, 0)

func host_card(card):
	hosted_cards.append(card)
	card.location = {"host": self}

func get_hosted_cards():
	return hosted_cards

func set_location(location_info):
	location = location_info

func get_location_string():
	if location.is_empty():
		return "Unknown"
	
	if location.has("host"):
		return "Hosted on " + location.host.title
	
	if location.has("zone"):
		match location.zone:
			"hand":
				return "Hand"
			"deck":
				return "Deck"
			"discard":
				return "Discard pile"
			"scored":
				return "Scored area"
			"play-area":
				return "Play area"
	
	if location.has("server"):
		return "Server " + location.server
	
	if location.has("rig"):
		return "Rig"
	
	return "Unknown"

func is_active():
	# Check if the card is active (can use its abilities)
	if is_corp_card():
		return is_rezzed
	else:
		return is_installed

func can_be_advanced():
	# Only agendas and certain assets can be advanced
	if card_type == "agenda":
		return true
	
	# Some non-agenda cards can be advanced (based on card text)
	return effect.has("can_be_advanced") and effect.can_be_advanced

func get_break_cost(subroutine_type):
	# For icebreakers, get the cost to break a subroutine
	if card_type == "program" and "icebreaker" in card_subtype:
		if effect.has("break_subroutine"):
			if effect.break_subroutine.has("cost"):
				return effect.break_subroutine.cost
	
	return 0

func get_boost_strength_cost():
	# For icebreakers, get the cost to boost strength
	if card_type == "program" and "icebreaker" in card_subtype:
		if effect.has("boost_strength"):
			if effect.boost_strength.has("cost"):
				return effect.boost_strength.cost
	
	return 0

func can_break_subtype(ice_subtype):
	# Check if this icebreaker can break the given ice subtype
	if card_type == "program" and "icebreaker" in card_subtype:
		if "ai" in card_subtype:
			return true  # AI breakers can break any ice
			
		if effect.has("break_subroutine"):
			var break_ice_type = effect.break_subroutine.get("ice_type", "")
			
			match break_ice_type:
				"barrier":
					return "barrier" in ice_subtype
				"code gate":
					return "code gate" in ice_subtype
				"sentry":
					return "sentry" in ice_subtype
	
	return false
