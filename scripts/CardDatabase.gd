extends Node

# CardDatabase handles loading, storing, and accessing all card definitions
# This is an adapted, simplified version of Netrunner's card system

signal database_loaded
signal card_loaded(card_data)

var cards = {}
var corp_cards = []
var runner_cards = []
var card_types = {
	"corp": ["ice", "agenda", "asset", "upgrade", "operation"],
	"runner": ["program", "hardware", "resource", "event"]
}

var card_subtypes = {
	"ice": ["barrier", "code gate", "sentry", "mythic", "trap"],
	"program": ["icebreaker", "virus", "ai"],
	"icebreaker": ["fracter", "decoder", "killer"],
	"hardware": ["console", "chip"],
	"resource": ["connection", "job", "location", "virtual"]
}

func _ready():
	# Initialize the card database
	load_card_database()

func load_card_database():
	# In a full implementation, this would load from a JSON file or server
	# For now, we'll create a sample database directly
	create_sample_database()
	emit_signal("database_loaded")

func create_sample_database():
	# Sample Ice cards
	add_corp_card({
		"id": "ice_wall",
		"title": "Ice Wall",
		"type": "ice",
		"subtype": ["barrier"],
		"cost": 1,
		"rez_cost": 1,
		"strength": 1,
		"text": "End the run.",
		"effect": {
			"subroutines": [
				{"type": "end_run"}
			]
		}
	})
	
	add_corp_card({
		"id": "enigma",
		"title": "Enigma",
		"type": "ice",
		"subtype": ["code gate"],
		"cost": 3,
		"rez_cost": 3,
		"strength": 2,
		"text": "The Runner loses [click], if able. End the run.",
		"effect": {
			"subroutines": [
				{"type": "lose_click", "amount": 1},
				{"type": "end_run"}
			]
		}
	})
	
	# Sample Agenda cards
	add_corp_card({
		"id": "project_atlas",
		"title": "Project Atlas",
		"type": "agenda",
		"cost": 3,
		"advancement_requirement": 3,
		"agenda_points": 2,
		"text": "When you score Project Atlas, place 1 agenda counter on it for each advancement token on it above 3. Hosted agenda counter: Search R&D for 1 card and add it to HQ. Shuffle R&D.",
		"effect": {
			"on_score": {"type": "add_counter", "counter_type": "agenda", "condition": "over_advancement", "threshold": 3},
			"hosted_counter": {"type": "search_rd", "amount": 1}
		}
	})
	
	# Sample Asset cards
	add_corp_card({
		"id": "pad_campaign",
		"title": "PAD Campaign",
		"type": "asset",
		"cost": 2,
		"rez_cost": 2,
		"trash_cost": 4,
		"text": "When your turn begins, gain 1 credit.",
		"effect": {
			"on_turn_begin": {"type": "gain_credits", "amount": 1}
		}
	})
	
	# Sample Operation cards
	add_corp_card({
		"id": "hedge_fund",
		"title": "Hedge Fund",
		"type": "operation",
		"cost": 5,
		"text": "Gain 9 credits.",
		"effect": {
			"type": "gain_credits",
			"amount": 9
		}
	})
	
	# Sample Icebreaker programs
	add_runner_card({
		"id": "corroder",
		"title": "Corroder",
		"type": "program",
		"subtype": ["icebreaker", "fracter"],
		"cost": 2,
		"memory_cost": 1,
		"strength": 2,
		"text": "1 credit: Break barrier subroutine.\n1 credit: +1 strength for the remainder of this run.",
		"effect": {
			"break_subroutine": {"cost": 1, "ice_type": "barrier"},
			"boost_strength": {"cost": 1, "amount": 1}
		}
	})
	
	# Sample Hardware cards
	add_runner_card({
		"id": "astrolabe",
		"title": "Astrolabe",
		"type": "hardware",
		"subtype": ["console"],
		"cost": 3,
		"text": "+1 memory unit\nThe first time you make a successful run on a remote server each turn, draw 1 card.\nLimit 1 console per player.",
		"effect": {
			"modify_memory": 1,
			"on_successful_run": {"condition": "first_remote_each_turn", "effect": {"type": "draw", "amount": 1}}
		}
	})
	
	# Sample Resource cards
	add_runner_card({
		"id": "kati_jones",
		"title": "Kati Jones",
		"type": "resource",
		"subtype": ["connection"],
		"cost": 2,
		"text": "[click]: Place 3 credits on Kati Jones.\n[click]: Take all credits from Kati Jones.",
		"effect": {
			"click_ability": [
				{"cost": 1, "effect": {"type": "place_credits", "amount": 3}},
				{"cost": 1, "effect": {"type": "take_credits"}}
			]
		}
	})
	
	# Sample Event cards
	add_runner_card({
		"id": "sure_gamble",
		"title": "Sure Gamble",
		"type": "event",
		"cost": 5,
		"text": "Gain 9 credits.",
		"effect": {
			"type": "gain_credits",
			"amount": 9
		}
	})
	
	# Add Corp identities
	add_corp_card({
		"id": "weyland_building_better",
		"title": "Weyland Consortium: Building a Better World",
		"type": "identity",
		"subtype": ["megacorp"],
		"text": "Gain 1 credit whenever you play a transaction operation.",
		"deck_size_min": 45,
		"influence_limit": 15,
		"effect": {
			"on_play": {"condition": "card_subtype", "subtype": "transaction", "effect": {"type": "gain_credits", "amount": 1}}
		}
	})
	
	# Add Runner identities
	add_runner_card({
		"id": "gabriel_santiago",
		"title": "Gabriel Santiago: Consummate Professional",
		"type": "identity",
		"subtype": ["criminal", "natural"],
		"text": "The first time you make a successful run on HQ each turn, gain 2 credits.",
		"deck_size_min": 45,
		"influence_limit": 15,
		"effect": {
			"on_successful_run": {"condition": "first_hq_each_turn", "effect": {"type": "gain_credits", "amount": 2}}
		}
	})

func add_corp_card(card_data):
	cards[card_data.id] = card_data
	corp_cards.append(card_data.id)
	emit_signal("card_loaded", card_data)

func add_runner_card(card_data):
	cards[card_data.id] = card_data
	runner_cards.append(card_data.id)
	emit_signal("card_loaded", card_data)

func get_card(card_id):
	if cards.has(card_id):
		return cards[card_id]
	return null

func get_corp_cards():
	var result = []
	for card_id in corp_cards:
		result.append(get_card(card_id))
	return result

func get_runner_cards():
	var result = []
	for card_id in runner_cards:
		result.append(get_card(card_id))
	return result

func get_cards_by_type(player_type, card_type):
	var result = []
	
	var all_cards = get_corp_cards() if player_type == "corp" else get_runner_cards()
	
	for card in all_cards:
		if card.type == card_type:
			result.append(card)
	
	return result

func get_starter_deck(player_type, identity_id = ""):
	# Create a basic starter deck for the chosen faction
	var deck = []
	
	if player_type == "corp":
		# Use default identity if none specified
		var identity = identity_id if identity_id else "weyland_building_better"
		
		# Add some basic cards for a corp deck
		deck.append({"id": identity, "count": 1})
		deck.append({"id": "hedge_fund", "count": 3})
		deck.append({"id": "ice_wall", "count": 3})
		deck.append({"id": "enigma", "count": 3})
		deck.append({"id": "project_atlas", "count": 3})
		deck.append({"id": "pad_campaign", "count": 3})
		# Add more cards to get to minimum deck size...
	
	else:  # runner deck
		# Use default identity if none specified
		var identity = identity_id if identity_id else "gabriel_santiago"
		
		# Add some basic cards for a runner deck
		deck.append({"id": identity, "count": 1})
		deck.append({"id": "sure_gamble", "count": 3})
		deck.append({"id": "corroder", "count": 2})
		deck.append({"id": "astrolabe", "count": 1})
		deck.append({"id": "kati_jones", "count": 2})
		# Add more cards to get to minimum deck size...
	
	return deck

func expand_deck_to_cards(deck):
	# Convert a deck definition (with card IDs and counts) to a list of card objects
	var cards = []
	
	for item in deck:
		var card = get_card(item.id)
		if card:
			for i in range(item.count):
				cards.append(card.duplicate())
	
	return cards

func is_deck_valid(player_type, deck):
	# Check if a deck is valid according to Netrunner rules
	# This is a simplified version for our adaptation
	
	if player_type == "corp":
		# Corp deck needs at least 1 identity, minimum deck size, and agendas
		var has_identity = false
		var card_count = 0
		var agenda_points = 0
		
		for item in deck:
			var card = get_card(item.id)
			if card:
				if card.type == "identity":
					has_identity = true
					var min_deck_size = card.deck_size_min if card.has("deck_size_min") else 45
				elif card.type == "agenda":
					agenda_points += card.agenda_points * item.count
				
				card_count += item.count
		
		# Quick validation (simplified)
		if not has_identity or card_count < 45:
			return false
		
		# Check agenda points (simplified rule: 20-21 points in a 45-49 card deck)
		if agenda_points < 20 or agenda_points > 21:
			return false
	
	else:  # runner deck
		# Runner deck needs at least 1 identity and minimum deck size
		var has_identity = false
		var card_count = 0
		
		for item in deck:
			var card = get_card(item.id)
			if card:
				if card.type == "identity":
					has_identity = true
					var min_deck_size = card.deck_size_min if card.has("deck_size_min") else 45
				
				card_count += item.count
		
		# Quick validation (simplified)
		if not has_identity or card_count < 45:
			return false
	
	return true
