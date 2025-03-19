extends Node
class_name Player

# Base Player class for both Runner and Corp players

signal credits_changed(new_amount)
signal clicks_changed(new_amount)
signal card_drawn(card)
signal card_played(card)
signal card_installed(card)
signal card_trashed(card)
signal card_uninstalled(card)
signal card_rezzed(card)
signal card_advanced(card)
signal agenda_scored(card)
signal server_created(server)

enum PlayerType { CORP, RUNNER }

# Player identification
var player_id = ""
var player_name = ""
var player_type = PlayerType.RUNNER  # Default, will be set in subclasses
var faction = ""

# Resources
var credits = 0
var clicks = 0
var starting_credits = 5
var max_hand_size = 5

# Card collections
var deck = []
var hand = []
var discard_pile = []
var scored_agendas = []
var identity_card = null

func _init():
	# Will be overridden by subclasses
	pass

func _ready():
	# Connect to game state events
	GameState.connect("game_started", self, "_on_game_started")
	GameState.connect("turn_changed", self, "_on_turn_changed")

func initialize(id, name, deck_data):
	player_id = id
	player_name = name
	
	# Set up deck from deck data
	var processed_deck = []
	
	# Identify and set identity card
	for card_item in deck_data:
		if card_item.count == 1 and CardDatabase.get_card(card_item.id).type == "identity":
			identity_card = Card.new(CardDatabase.get_card(card_item.id))
			break
	
	# Process the rest of the deck
	for card_item in deck_data:
		if card_item.id != identity_card.id:
			var card_def = CardDatabase.get_card(card_item.id)
			for i in range(card_item.count):
				processed_deck.append(Card.new(card_def))
	
	deck = processed_deck
	shuffle_deck()
	
	# Set initial credits
	modify_credits(starting_credits)

func setup_player():
	# To be implemented by subclasses (Runner and Corp)
	pass

func start_turn():
	# Common turn start logic
	spend_all_clicks()

func end_turn():
	# Common turn end logic
	spend_all_clicks()
	
	# Check hand size
	discard_down_to_max_hand_size()

func discard_down_to_max_hand_size():
	# At the end of turn, players must discard down to their max hand size
	# This is typically handled via UI, so we don't auto-discard here
	pass

func add_clicks(amount):
	clicks += amount
	emit_signal("clicks_changed", clicks)

func spend_click(amount = 1):
	if clicks >= amount:
		clicks -= amount
		emit_signal("clicks_changed", clicks)
		return true
	return false

func spend_all_clicks():
	clicks = 0
	emit_signal("clicks_changed", clicks)

func modify_credits(amount):
	credits += amount
	emit_signal("credits_changed", credits)

func draw_card():
	if deck.size() > 0:
		var card = deck.pop_front()
		hand.append(card)
		card.set_location({"zone": "hand"})
		emit_signal("card_drawn", card)
		return card
	
	return null

func is_deck_empty():
	return deck.size() <= 0

func discard_card(card_index):
	if card_index >= 0 and card_index < hand.size():
		var card = hand[card_index]
		hand.remove_at(card_index)
		discard_pile.append(card)
		card.set_location({"zone": "discard"})
		emit_signal("card_trashed", card)
		return true
	
	return false

func shuffle_deck():
	deck.shuffle()

func _on_game_started():
	# Set up initial game state for this player
	setup_player()

func _on_turn_changed(active_player_id):
	if active_player_id == player_id:
		start_turn()
	else:
		end_turn()
