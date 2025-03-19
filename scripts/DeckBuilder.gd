extends Control

signal deck_saved(deck_data)

# Deck building constants
const MIN_DECK_SIZE = 45
const MAX_AGENDA_POINTS = 21
const MIN_AGENDA_POINTS = 20

# Deck building state
var player_faction = "runner"
var available_cards = []
var deck_cards = {}  # card_id: count
var selected_card = null
var selected_card_display = null
var current_deck_name = "New Deck"
var identity_card = null

# UI References
@onready var deck_name_input = $MarginContainer/VBoxContainer/HSplitContainer/LeftPanel/DeckInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/DeckNameInput
@onready var deck_stats_label = $MarginContainer/VBoxContainer/HSplitContainer/LeftPanel/DeckInfoPanel/MarginContainer/VBoxContainer/DeckStatsLabel
@onready var deck_list = $MarginContainer/VBoxContainer/HSplitContainer/LeftPanel/DeckListPanel/MarginContainer/VBoxContainer/ScrollContainer/DeckList
@onready var card_grid = $MarginContainer/VBoxContainer/HSplitContainer/RightPanel/CardBrowserPanel/MarginContainer/VBoxContainer/ScrollContainer/CardGrid
@onready var search_input = $MarginContainer/VBoxContainer/HSplitContainer/RightPanel/FilterPanel/MarginContainer/VBoxContainer/HBoxContainer/SearchInput
@onready var type_filter = $MarginContainer/VBoxContainer/HSplitContainer/RightPanel/FilterPanel/MarginContainer/VBoxContainer/HBoxContainer/TypeOptionButton
@onready var back_button = $MarginContainer/VBoxContainer/ButtonPanel/HBoxContainer/BackButton
@onready var clear_button = $MarginContainer/VBoxContainer/ButtonPanel/HBoxContainer/ClearButton
@onready var save_button = $MarginContainer/VBoxContainer/ButtonPanel/HBoxContainer/SaveButton
@onready var card_dialog = $CardDialog

func _ready():
	# Connect UI signals
	back_button.pressed.connect(_on_back_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	search_input.text_changed.connect(_on_search_text_changed)
	type_filter.item_selected.connect(_on_type_filter_changed)
	card_dialog.get_ok_button().pressed.connect(_on_add_card_button_pressed)
	
	# Connect to CardDatabase signals
	CardDatabase.database_loaded.connect(_on_card_database_loaded)
	
	# Clear placeholder card displays
	for child in card_grid.get_children():
		child.queue_free()
	
	# Clear placeholder deck list items
	for child in deck_list.get_children():
		child.queue_free()

func initialize(player_data):
	# Set player faction from player data
	player_faction = player_data.faction
	
	# Load available cards for this faction
	load_available_cards()
	
	# Clear the deck
	clear_deck()
	
	# Load player's first deck if they have one
	if player_data.has("decks") and player_data.decks.size() > 0:
		load_deck(player_data.decks[0])
	else:
		# Create an empty deck
		deck_name_input.text = "New " + player_faction.capitalize() + " Deck"
		update_deck_stats()
	
	# Display all available cards
	display_available_cards()

func load_available_cards():
	available_cards = []
	
	# Get cards based on faction
	if player_faction == "corp":
		available_cards = CardDatabase.get_corp_cards()
	else:
		available_cards = CardDatabase.get_runner_cards()

func display_available_cards():
	# Clear existing card displays
	for child in card_grid.get_children():
		child.queue_free()
	
	# Filter cards based on search and type filter
	var search_text = search_input.text.to_lower()
	var type_index = type_filter.selected
	var type_filter_text = type_filter.get_item_text(type_index).to_lower()
	
	var filtered_cards = []
	for card in available_cards:
		# Apply search filter
		if search_text != "" and not card.title.to_lower().contains(search_text):
			continue
		
		# Apply type filter (if not "All Types")
		if type_index > 0 and type_filter_text != "all types":
			if card.type.to_lower() != type_filter_text.to_lower():
				continue
		
		filtered_cards.append(card)
	
	# Display filtered cards
	for card in filtered_cards:
		var card_display = preload("res://scenes/CardDisplay.tscn").instantiate()
		card_grid.add_child(card_display)
		card_display.initialize(card)
		
		# Connect card clicked signal
		card_display.card_clicked.connect(_on_card_browser_card_clicked.bind(card, card_display))

func update_deck_list():
	# Clear existing deck list items
	for child in deck_list.get_children():
		child.queue_free()
	
	# Show identity card first if we have one
	if identity_card:
		add_card_to_deck_list(identity_card, 1)
	
	# Sort cards by type for better organization
	var cards_by_type = {}
	
	for card_id in deck_cards:
		var card = CardDatabase.get_card(card_id)
		if card:
			if not cards_by_type.has(card.type):
				cards_by_type[card.type] = []
			cards_by_type[card.type].append(card)
	
	# Display cards grouped by type
	var type_order = ["agenda", "asset", "ice", "operation", "upgrade", "program", "hardware", "resource", "event"]
	
	for type in type_order:
		if cards_by_type.has(type):
			# Add type header
			var header = Label.new()
			header.text = type.to_upper()
			header.add_theme_color_override("font_color", Color(0, 0.639, 0.909))
			deck_list.add_child(header)
			
			# Sort cards by name within type
			cards_by_type[type].sort_custom(func(a, b): return a.title < b.title)
			
			# Add cards of this type
			for card in cards_by_type[type]:
				var count = deck_cards[card.id]
				add_card_to_deck_list(card, count)

func add_card_to_deck_list(card, count):
	var item = HBoxContainer.new()
	deck_list.add_child(item)
	
	var count_label = Label.new()
	count_label.text = str(count) + "x "
	count_label.custom_minimum_size.x = 30
	item.add_child(count_label)
	
	var title_label = Label.new()
	title_label.text = card.title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(title_label)
	
	if card.type != "identity":
		var add_button = Button.new()
		add_button.text = "+"
		add_button.custom_minimum_size.x = 30
		item.add_child(add_button)
		add_button.pressed.connect(_on_deck_card_add_pressed.bind(card))
		
		var remove_button = Button.new()
		remove_button.text = "-"
		remove_button.custom_minimum_size.x = 30
		item.add_child(remove_button)
		remove_button.pressed.connect(_on_deck_card_remove_pressed.bind(card))

func update_deck_stats():
	var card_count = 0
	var agenda_points = 0
	var identity_name = "None"
	
	# Count regular cards
	for card_id in deck_cards:
		var card = CardDatabase.get_card(card_id)
		if card and card.type != "identity":
			card_count += deck_cards[card_id]
			
			# Count agenda points
			if card.type == "agenda" and card.has("agenda_points"):
				agenda_points += card.agenda_points * deck_cards[card_id]
	
	# Get identity name
	if identity_card:
		identity_name = identity_card.title
	
	# Update stats label
	var stats_text = "Cards: " + str(card_count) + "/" + str(MIN_DECK_SIZE)
	stats_text += "   Identity: " + identity_name
	
	# Show agenda points for corp decks
	if player_faction == "corp":
		stats_text += "   Agenda Points: " + str(agenda_points) + "/" + str(MIN_AGENDA_POINTS) + "-" + str(MAX_AGENDA_POINTS)
	
	deck_stats_label.text = stats_text
	
	# Update save button state
	save_button.disabled = not is_deck_valid()

func is_deck_valid():
	var card_count = 0
	var agenda_points = 0
	var has_identity = identity_card != null
	
	# Count regular cards
	for card_id in deck_cards:
		var card = CardDatabase.get_card(card_id)
		if card and card.type != "identity":
			card_count += deck_cards[card_id]
			
			# Count agenda points
			if card.type == "agenda" and card.has("agenda_points"):
				agenda_points += card.agenda_points * deck_cards[card_id]
	
	# Basic validation
	if not has_identity:
		return false
	
	if card_count < MIN_DECK_SIZE:
		return false
	
	# Validate agenda points for corp decks
	if player_faction == "corp":
		if agenda_points < MIN_AGENDA_POINTS or agenda_points > MAX_AGENDA_POINTS:
			return false
	
	return true

func add_card_to_deck(card, count = 1):
	# Add the specified card to the deck
	if card.type == "identity":
		# Only one identity allowed
		identity_card = card
	else:
		# Add regular card
		if deck_cards.has(card.id):
			deck_cards[card.id] += count
		else:
			deck_cards[card.id] = count
	
	# Update UI
	update_deck_list()
	update_deck_stats()

func remove_card_from_deck(card, count = 1):
	if card.type == "identity":
		# Remove identity
		identity_card = null
	else:
		# Remove regular card
		if deck_cards.has(card.id):
			deck_cards[card.id] -= count
			
			if deck_cards[card.id] <= 0:
				deck_cards.erase(card.id)
	
	# Update UI
	update_deck_list()
	update_deck_stats()

func clear_deck():
	# Reset deck building state
	deck_cards = {}
	identity_card = null
	
	# Update UI
	update_deck_list()
	update_deck_stats()

func load_deck(deck_data):
	# Clear current deck
	clear_deck()
	
	# Set deck name
	if deck_data.has("name"):
		deck_name_input.text = deck_data.name
		current_deck_name = deck_data.name
	
	# Add cards to deck
	if deck_data.has("cards"):
		for card_item in deck_data.cards:
			var card = CardDatabase.get_card(card_item.id)
			if card:
				if card.type == "identity":
					identity_card = card
				else:
					deck_cards[card.id] = card_item.count
	
	# Update UI
	update_deck_list()
	update_deck_stats()

func get_current_deck_data():
	var deck_data = {
		"name": deck_name_input.text,
		"faction": player_faction,
		"cards": []
	}
	
	# Add identity
	if identity_card:
		deck_data.cards.append({
			"id": identity_card.id,
			"count": 1
		})
	
	# Add other cards
	for card_id in deck_cards:
		deck_data.cards.append({
			"id": card_id,
			"count": deck_cards[card_id]
		})
	
	return deck_data

func _on_card_browser_card_clicked(card, card_display):
	# Set as selected card
	selected_card = card
	
	# Deselect previously selected card display
	if selected_card_display:
		selected_card_display.set_selected(false)
	
	# Set new card as selected
	selected_card_display = card_display
	selected_card_display.set_selected(true)
	
	# Show card dialog
	show_card_dialog(card)

func show_card_dialog(card):
	# Update dialog content with card details
	card_dialog.title = card.title
	card_dialog.get_node("MarginContainer/VBoxContainer/TitleLabel").text = card.title
	card_dialog.get_node("MarginContainer/VBoxContainer/TypeLabel").text = "Type: " + card.type.capitalize()
	
	if card.has("subtype") and card.subtype.size() > 0:
		card_dialog.get_node("MarginContainer/VBoxContainer/TypeLabel").text += " - " + " ".join(card.subtype)
	
	card_dialog.get_node("MarginContainer/VBoxContainer/CostLabel").text = "Cost: " + str(card.cost)
	
	var stats_text = ""
	if card.has("strength"):
		stats_text += "Strength: " + str(card.strength)
	
	if card.has("memory_cost"):
		if stats_text != "":
			stats_text += ", "
		stats_text += "Memory: " + str(card.memory_cost)
	
	if card.has("advancement_requirement"):
		if stats_text != "":
			stats_text += ", "
		stats_text += "Advancement: " + str(card.advancement_requirement)
	
	if card.has("agenda_points"):
		if stats_text != "":
			stats_text += ", "
		stats_text += "Agenda Points: " + str(card.agenda_points)
	
	card_dialog.get_node("MarginContainer/VBoxContainer/StatsLabel").text = stats_text
	card_dialog.get_node("MarginContainer/VBoxContainer/StatsLabel").visible = stats_text != ""
	
	card_dialog.get_node("MarginContainer/VBoxContainer/TextLabel").text = card.text
	
	# Show current amount in deck
	var current_amount = 0
	var max_amount = 3  # Default max
	
	if card.type == "identity":
		max_amount = 1  # Only one identity allowed
		
		if identity_card and identity_card.id == card.id:
			current_amount = 1
	else:
		if deck_cards.has(card.id):
			current_amount = deck_cards[card.id]
	
	card_dialog.get_node("MarginContainer/VBoxContainer/AmountLabel").text = "Amount in deck: " + str(current_amount) + "/" + str(max_amount)
	
	# Set up spin box
	var amount_spin = card_dialog.get_node("MarginContainer/VBoxContainer/AmountSpinBox")
	amount_spin.min_value = 0
	amount_spin.max_value = max_amount
	amount_spin.value = current_amount
	
	# Show dialog
	card_dialog.popup_centered()

func _on_deck_card_add_pressed(card):
	add_card_to_deck(card, 1)

func _on_deck_card_remove_pressed(card):
	remove_card_from_deck(card, 1)

func _on_add_card_button_pressed():
	if selected_card:
		var amount_spin = card_dialog.get_node("MarginContainer/VBoxContainer/AmountSpinBox")
		var current_amount = 0
		
		if selected_card.type == "identity":
			if identity_card and identity_card.id == selected_card.id:
				current_amount = 1
		else:
			if deck_cards.has(selected_card.id):
				current_amount = deck_cards[selected_card.id]
		
		var new_amount = int(amount_spin.value)
		
		if new_amount > current_amount:
			# Add cards
			add_card_to_deck(selected_card, new_amount - current_amount)
		elif new_amount < current_amount:
			# Remove cards
			remove_card_from_deck(selected_card, current_amount - new_amount)
		
		# Update dialog
		card_dialog.get_node("MarginContainer/VBoxContainer/AmountLabel").text = "Amount in deck: " + str(new_amount) + "/" + str(amount_spin.max_value)

func _on_back_button_pressed():
	# Return to lobby without saving
	get_parent().get_parent().show_screen(get_parent().get_parent().GameScreen.LOBBY)

func _on_clear_button_pressed():
	# Confirm before clearing
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to clear the deck? This will remove all cards."
	dialog.confirmed.connect(_confirm_clear_deck)
	add_child(dialog)
	dialog.popup_centered()

func _confirm_clear_deck():
	clear_deck()

func _on_save_button_pressed():
	if is_deck_valid():
		# Get deck data
		var deck_data = get_current_deck_data()
		
		# Emit signal
		emit_signal("deck_saved", deck_data)
	else:
		# Show error
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Deck is not valid. Please make sure you have a valid identity, at least " + str(MIN_DECK_SIZE) + " cards"
		if player_faction == "corp":
			dialog.dialog_text += ", and between " + str(MIN_AGENDA_POINTS) + "-" + str(MAX_AGENDA_POINTS) + " agenda points"
		dialog.dialog_text += "."
		add_child(dialog)
		dialog.popup_centered()

func _on_search_text_changed(new_text):
	display_available_cards()

func _on_type_filter_changed(index):
	display_available_cards()

func _on_card_database_loaded():
	load_available_cards()
	display_available_cards()
