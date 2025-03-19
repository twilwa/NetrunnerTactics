extends Control

# GameBoard handles the main gameplay interface and controls the flow of the game

signal game_ended(result_data)

enum ActionType { DRAW, GAIN_CREDIT, INSTALL, PLAY, RUN, END_TURN }

# Player data
var player_id = ""
var player_type = GameState.PlayerType.RUNNER
var player_name = ""
var opponent_id = ""
var opponent_type = GameState.PlayerType.CORP
var opponent_name = ""

# Game state tracking
var is_player_turn = false
var selected_card = null
var selected_card_index = -1
var selected_server = null
var can_perform_actions = true
var run_active = false

# UI References
@onready var player_cards_container = $GameGrid/VBoxContainer/PlayerArea/PlayerPanel/MarginContainer/VBoxContainer/PlayerCards
@onready var opponent_cards_container = $GameGrid/VBoxContainer/OpponentArea/OpponentPanel/MarginContainer/VBoxContainer/OpponentCards
@onready var remote_servers_container = $GameGrid/VBoxContainer/MiddleArea/ServersPanel/MarginContainer/HBoxContainer/RemoteServers/RemoteServersContainer
@onready var central_servers_container = $GameGrid/VBoxContainer/MiddleArea/ServersPanel/MarginContainer/HBoxContainer/CentralServers

# Info labels
@onready var player_info_name_label = $GameGrid/VBoxContainer/PlayerArea/PlayerPanel/MarginContainer/VBoxContainer/PlayerInfo/NameLabel
@onready var player_info_type_label = $GameGrid/VBoxContainer/PlayerArea/PlayerPanel/MarginContainer/VBoxContainer/PlayerInfo/TypeLabel
@onready var player_credits_label = $GameGrid/VBoxContainer/PlayerArea/PlayerPanel/MarginContainer/VBoxContainer/ResourceInfo/CreditsLabel
@onready var player_clicks_label = $GameGrid/VBoxContainer/PlayerArea/PlayerPanel/MarginContainer/VBoxContainer/ResourceInfo/ClicksLabel
@onready var player_cards_label = $GameGrid/VBoxContainer/PlayerArea/PlayerPanel/MarginContainer/VBoxContainer/ResourceInfo/CardsLabel

@onready var opponent_info_name_label = $GameGrid/VBoxContainer/OpponentArea/OpponentPanel/MarginContainer/VBoxContainer/OpponentInfo/NameLabel
@onready var opponent_info_type_label = $GameGrid/VBoxContainer/OpponentArea/OpponentPanel/MarginContainer/VBoxContainer/OpponentInfo/TypeLabel
@onready var opponent_credits_label = $GameGrid/VBoxContainer/OpponentArea/OpponentPanel/MarginContainer/VBoxContainer/ResourceInfo/CreditsLabel
@onready var opponent_clicks_label = $GameGrid/VBoxContainer/OpponentArea/OpponentPanel/MarginContainer/VBoxContainer/ResourceInfo/ClicksLabel
@onready var opponent_cards_label = $GameGrid/VBoxContainer/OpponentArea/OpponentPanel/MarginContainer/VBoxContainer/ResourceInfo/CardsLabel

# Action buttons
@onready var draw_button = $ActionPanel/MarginContainer/ActionButtons/DrawButton
@onready var gain_credit_button = $ActionPanel/MarginContainer/ActionButtons/GainCreditButton
@onready var install_button = $ActionPanel/MarginContainer/ActionButtons/InstallButton
@onready var play_button = $ActionPanel/MarginContainer/ActionButtons/PlayButton
@onready var run_button = $ActionPanel/MarginContainer/ActionButtons/RunButton
@onready var end_turn_button = $ActionPanel/MarginContainer/ActionButtons/EndTurnButton

# Dialogs
@onready var run_dialog = $RunDialog
@onready var install_dialog = $InstallDialog
@onready var action_timer = $ActionTimer
@onready var game_over_panel = $GameOverPanel

func _ready():
	# Connect to GameState signals
	GameState.game_started.connect(_on_game_started)
	GameState.turn_changed.connect(_on_turn_changed)
	GameState.credits_changed.connect(_on_credits_changed)
	GameState.card_drawn.connect(_on_card_drawn)
	GameState.card_played.connect(_on_card_played)
	GameState.run_started.connect(_on_run_started)
	GameState.run_ended.connect(_on_run_ended)
	GameState.game_over.connect(_on_game_over)
	
	# Connect action buttons
	draw_button.pressed.connect(_on_draw_button_pressed)
	gain_credit_button.pressed.connect(_on_gain_credit_button_pressed)
	install_button.pressed.connect(_on_install_button_pressed)
	play_button.pressed.connect(_on_play_button_pressed)
	run_button.pressed.connect(_on_run_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	
	# Connect dialog signals
	run_dialog.confirmed.connect(_on_run_dialog_confirmed)
	install_dialog.confirmed.connect(_on_install_dialog_confirmed)
	action_timer.timeout.connect(_on_action_timer_timeout)
	
	# Connect game over button
	$GameOverPanel/VBoxContainer/ContinueButton.pressed.connect(_on_continue_button_pressed)
	
	# Initialize UI
	setup_ui()
	game_over_panel.visible = false

func initialize_game(game_data):
	# Clear existing UI elements
	clear_ui()
	
	# Set player and opponent info
	player_id = NetworkManager.player_id
	
	for player in game_data.players:
		if player.id == player_id:
			player_name = player.name
			player_type = GameState.PlayerType.CORP if player.type == "corp" else GameState.PlayerType.RUNNER
		else:
			opponent_id = player.id
			opponent_name = player.name
			opponent_type = GameState.PlayerType.CORP if player.type == "corp" else GameState.PlayerType.RUNNER
	
	# Update UI with player info
	update_player_info()
	
	# Initialize GameState with game data
	GameState.initialize_game(game_data)

func setup_ui():
	# Clear placeholder card displays
	for child in player_cards_container.get_children():
		child.queue_free()
	
	for child in opponent_cards_container.get_children():
		child.queue_free()
	
	# Clear remote server placeholders (except the first one which we'll use as a template)
	var template_server = remote_servers_container.get_child(0)
	for i in range(1, remote_servers_container.get_child_count()):
		remote_servers_container.get_child(i).queue_free()
	
	# Hide the template server - we'll instantiate new ones as needed
	if template_server:
		template_server.visible = false

func clear_ui():
	# Clear cards
	for child in player_cards_container.get_children():
		child.queue_free()
	
	for child in opponent_cards_container.get_children():
		child.queue_free()
	
	# Reset server displays
	for child in remote_servers_container.get_children():
		if child.visible:
			child.visible = false

func update_player_info():
	# Update player info
	player_info_name_label.text = player_name
	player_info_type_label.text = "(" + ("Corp" if player_type == GameState.PlayerType.CORP else "Runner") + ")"
	
	# Update opponent info
	opponent_info_name_label.text = opponent_name
	opponent_info_type_label.text = "(" + ("Corp" if opponent_type == GameState.PlayerType.CORP else "Runner") + ")"

func update_resources():
	if GameState.players.has(player_id):
		var player = GameState.players[player_id]
		player_credits_label.text = "Credits: " + str(player.credits)
		player_clicks_label.text = "Clicks: " + str(player.clicks)
		player_cards_label.text = "Cards: " + str(player.hand.size())
	
	if GameState.players.has(opponent_id):
		var opponent = GameState.players[opponent_id]
		opponent_credits_label.text = "Credits: " + str(opponent.credits)
		opponent_clicks_label.text = "Clicks: " + str(opponent.clicks)
		opponent_cards_label.text = "Cards: " + str(opponent.hand.size())

func update_hand():
	# Clear existing cards
	for child in player_cards_container.get_children():
		child.queue_free()
	
	# Add cards from hand
	if GameState.players.has(player_id):
		var player = GameState.players[player_id]
		for i in range(player.hand.size()):
			var card = player.hand[i]
			var card_display = preload("res://scenes/CardDisplay.tscn").instantiate()
			player_cards_container.add_child(card_display)
			card_display.initialize(card)
			
			# Connect card clicked signal
			card_display.card_clicked.connect(_on_player_card_clicked.bind(i))

func update_opponent_hand():
	# Clear existing cards
	for child in opponent_cards_container.get_children():
		child.queue_free()
	
	# Add cards from opponent's hand (face down)
	if GameState.players.has(opponent_id):
		var opponent = GameState.players[opponent_id]
		for i in range(opponent.hand.size()):
			var card_display = preload("res://scenes/CardDisplay.tscn").instantiate()
			opponent_cards_container.add_child(card_display)
			card_display.initialize_facedown()

func update_servers():
	# Update central servers
	var central_servers = []
	if player_type == GameState.PlayerType.CORP:
		central_servers = ["HQ", "R&D", "Archives"]
	else:
		# For runner, we see them from the opponent's perspective
		central_servers = ["HQ", "R&D", "Archives"]
	
	# Update central server UI
	for i in range(central_servers.size()):
		var server_node = central_servers_container.get_child(i + 1)  # +1 to skip the label
		if server_node:
			server_node.get_node("Label").text = central_servers[i]
	
	# Update remote servers
	update_remote_servers()

func update_remote_servers():
	# Get remote servers from GameState
	var remote_servers = []
	if player_type == GameState.PlayerType.CORP:
		remote_servers = GameState.servers.keys()
	else:
		# For runner, get remote servers from corp player
		var corp_id = GameState.get_corp_id()
		if corp_id:
			remote_servers = GameState.servers.keys()
	
	# Remove any servers that start with "remote_"
	var filtered_servers = []
	for server in remote_servers:
		if server.begins_with("remote_"):
			filtered_servers.append(server)
	
	# Create/update remote server UI
	for i in range(filtered_servers.size()):
		var server_id = filtered_servers[i]
		var server_panel = null
		
		# Check if we need to create a new server panel
		if i >= remote_servers_container.get_child_count():
			var template = remote_servers_container.get_child(0)
			server_panel = template.duplicate()
			remote_servers_container.add_child(server_panel)
			
			# Connect server clicked signal
			server_panel.gui_input.connect(_on_server_clicked.bind(server_id))
		else:
			server_panel = remote_servers_container.get_child(i)
		
		# Update server panel
		server_panel.visible = true
		server_panel.get_node("Label").text = "REMOTE " + str(i + 1)
		
		# Store server_id in the panel for reference
		server_panel.set_meta("server_id", server_id)

func update_action_buttons():
	# Enable/disable action buttons based on current game state
	if not is_player_turn or not can_perform_actions:
		disable_all_action_buttons()
		return
	
	var player = GameState.players[player_id]
	
	# Draw button - requires a click
	draw_button.disabled = player.clicks <= 0
	
	# Gain credit button - requires a click
	gain_credit_button.disabled = player.clicks <= 0
	
	# Install button - requires a click and a card in hand
	install_button.disabled = player.clicks <= 0 or player.hand.size() <= 0
	
	# Play button - requires a click and event/operation in hand
	var has_playable_card = false
	for card in player.hand:
		if (player_type == GameState.PlayerType.RUNNER and card.card_type == "event") or \
		   (player_type == GameState.PlayerType.CORP and card.card_type == "operation"):
			has_playable_card = true
			break
	play_button.disabled = player.clicks <= 0 or not has_playable_card
	
	# Run button - only for runner and requires a click
	run_button.disabled = player.clicks <= 0 or player_type != GameState.PlayerType.RUNNER
	run_button.visible = player_type == GameState.PlayerType.RUNNER
	
	# End turn button - always enabled during player's turn
	end_turn_button.disabled = false

func disable_all_action_buttons():
	draw_button.disabled = true
	gain_credit_button.disabled = true
	install_button.disabled = true
	play_button.disabled = true
	run_button.disabled = true
	end_turn_button.disabled = true

func perform_action(action_type):
	# Disable action buttons during animation
	can_perform_actions = false
	disable_all_action_buttons()
	
	# Start timer to re-enable buttons after animation
	action_timer.start()
	
	# Execute the action
	match action_type:
		ActionType.DRAW:
			GameState.draw_card(player_id)
			GameState.spend_click(player_id)
		
		ActionType.GAIN_CREDIT:
			GameState.modify_credits(player_id, 1)
			GameState.spend_click(player_id)
		
		ActionType.END_TURN:
			GameState.end_turn()

func _on_player_card_clicked(card_index):
	if not is_player_turn or not can_perform_actions:
		return
	
	selected_card_index = card_index
	selected_card = GameState.players[player_id].hand[card_index]
	
	# Highlight the selected card
	for i in range(player_cards_container.get_child_count()):
		var card_display = player_cards_container.get_child(i)
		card_display.set_selected(i == card_index)

func _on_server_clicked(event, server_id):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_player_turn or not can_perform_actions:
			return
		
		selected_server = server_id
		
		# If we're in a run and clicked a server, this would indicate the target
		if run_active:
			_initiate_run(server_id)

func _on_draw_button_pressed():
	perform_action(ActionType.DRAW)

func _on_gain_credit_button_pressed():
	perform_action(ActionType.GAIN_CREDIT)

func _on_install_button_pressed():
	if selected_card_index >= 0:
		# Show install dialog with selected card info
		var card = GameState.players[player_id].hand[selected_card_index]
		
		install_dialog.get_node("VBoxContainer/CardLabel").text = "Install card: " + card.title
		install_dialog.get_node("VBoxContainer/CostLabel").text = "Cost: " + str(card.cost) + " credits"
		
		# Populate server list based on card type
		var server_list = install_dialog.get_node("VBoxContainer/ServerList")
		server_list.clear()
		
		if player_type == GameState.PlayerType.CORP:
			if card.card_type == "ice":
				# Ice can be installed on any server
				server_list.add_item("HQ")
				server_list.add_item("R&D")
				server_list.add_item("Archives")
				
				for i in range(remote_servers_container.get_child_count()):
					var server_panel = remote_servers_container.get_child(i)
					if server_panel.visible:
						server_list.add_item("Remote " + str(i + 1))
			
			elif card.card_type in ["agenda", "asset", "upgrade"]:
				# These can only be installed in remote servers
				for i in range(remote_servers_container.get_child_count()):
					var server_panel = remote_servers_container.get_child(i)
					if server_panel.visible:
						server_list.add_item("Remote " + str(i + 1))
				
				# Add option to create a new remote server
				server_list.add_item("New Remote Server")
		
		elif player_type == GameState.PlayerType.RUNNER:
			# Runner cards are installed in the rig, no server selection needed
			install_dialog.dialog_text = "Install " + card.title + " for " + str(card.cost) + " credits?"
			server_list.visible = false
			install_dialog.get_node("VBoxContainer/ServerLabel").visible = false
		
		install_dialog.popup_centered()
	else:
		# No card selected, show message
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Please select a card to install first."
		add_child(dialog)
		dialog.popup_centered()

func _on_play_button_pressed():
	if selected_card_index >= 0:
		var card = GameState.players[player_id].hand[selected_card_index]
		
		# Check if this is a playable card type
		if (player_type == GameState.PlayerType.RUNNER and card.card_type == "event") or \
		   (player_type == GameState.PlayerType.CORP and card.card_type == "operation"):
			# Play the card
			var success = GameState.play_card(player_id, selected_card_index)
			
			if success:
				# Card was played successfully
				selected_card_index = -1
				selected_card = null
				
				# Deselect all cards
				for card_display in player_cards_container.get_children():
					card_display.set_selected(false)
			else:
				# Failed to play card (likely can't afford it)
				var dialog = AcceptDialog.new()
				dialog.dialog_text = "Cannot play this card. Check if you have enough credits or clicks."
				add_child(dialog)
				dialog.popup_centered()
		else:
			# Not a playable card type
			var dialog = AcceptDialog.new()
			dialog.dialog_text = "This card type cannot be played directly. Try installing it instead."
			add_child(dialog)
			dialog.popup_centered()
	else:
		# No card selected
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Please select a card to play first."
		add_child(dialog)
		dialog.popup_centered()

func _on_run_button_pressed():
	if player_type != GameState.PlayerType.RUNNER:
		return
	
	# Populate server list for run dialog
	var server_list = run_dialog.get_node("VBoxContainer/ServerList")
	server_list.clear()
	
	# Add central servers
	server_list.add_item("HQ")
	server_list.add_item("R&D")
	server_list.add_item("Archives")
	
	# Add remote servers
	for i in range(remote_servers_container.get_child_count()):
		var server_panel = remote_servers_container.get_child(i)
		if server_panel.visible:
			server_list.add_item("Remote " + str(i + 1))
	
	# Show run dialog
	run_dialog.popup_centered()

func _on_end_turn_button_pressed():
	perform_action(ActionType.END_TURN)

func _on_run_dialog_confirmed():
	var server_list = run_dialog.get_node("VBoxContainer/ServerList")
	var selected_index = server_list.get_selected_items()[0]
	var server_name = server_list.get_item_text(selected_index)
	
	var server_id = ""
	
	# Convert server name to server ID
	if server_name == "HQ":
		server_id = "hq"
	elif server_name == "R&D":
		server_id = "rd"
	elif server_name == "Archives":
		server_id = "archives"
	else:
		# Remote server - extract number and find the matching server panel
		var remote_num = int(server_name.split(" ")[1]) - 1
		if remote_num >= 0 and remote_num < remote_servers_container.get_child_count():
			var server_panel = remote_servers_container.get_child(remote_num)
			if server_panel.has_meta("server_id"):
				server_id = server_panel.get_meta("server_id")
	
	if server_id != "":
		_initiate_run(server_id)

func _initiate_run(server_id):
	# Start a run on the selected server
	run_active = true
	GameState.initiate_run(server_id)
	
	# Disable action buttons during run
	disable_all_action_buttons()
	
	# Update UI to show run in progress
	# This would be expanded with animations and more detailed UI in a full implementation
	var server_node = null
	
	if server_id == "hq":
		server_node = central_servers_container.get_node("HQ")
	elif server_id == "rd":
		server_node = central_servers_container.get_node("RD")
	elif server_id == "archives":
		server_node = central_servers_container.get_node("Archives")
	else:
		# Find remote server node
		for i in range(remote_servers_container.get_child_count()):
			var panel = remote_servers_container.get_child(i)
			if panel.has_meta("server_id") and panel.get_meta("server_id") == server_id:
				server_node = panel
				break
	
	if server_node:
		# Highlight the server being run on
		var original_color = server_node.get_theme_color("default_color", "Panel")
		server_node.add_theme_color_override("default_color", Color(1, 0.3, 0.3))
		
		# Reset after run animation
		await get_tree().create_timer(1.0).timeout
		server_node.add_theme_color_override("default_color", original_color)

func _on_install_dialog_confirmed():
	var server_list = install_dialog.get_node("VBoxContainer/ServerList")
	var server_id = ""
	
	if player_type == GameState.PlayerType.CORP:
		var selected_index = server_list.get_selected_items()[0]
		var server_name = server_list.get_item_text(selected_index)
		
		# Convert server name to server ID
		if server_name == "HQ":
			server_id = "hq"
		elif server_name == "R&D":
			server_id = "rd"
		elif server_name == "Archives":
			server_id = "archives"
		elif server_name == "New Remote Server":
			# Create a new remote server
			var new_server = GameState.create_remote_server()
			server_id = new_server.server_id
			
			# Update the UI to show the new server
			update_remote_servers()
		else:
			# Remote server - extract number and find the matching server panel
			var remote_num = int(server_name.split(" ")[1]) - 1
			if remote_num >= 0 and remote_num < remote_servers_container.get_child_count():
				var server_panel = remote_servers_container.get_child(remote_num)
				if server_panel.has_meta("server_id"):
					server_id = server_panel.get_meta("server_id")
	
	# Install the card
	var target_data = null
	if server_id != "":
		target_data = {"server_id": server_id}
	
	var success = GameState.play_card(player_id, selected_card_index, target_data)
	
	if success:
		# Card was installed successfully
		selected_card_index = -1
		selected_card = null
		
		# Deselect all cards
		for card_display in player_cards_container.get_children():
			card_display.set_selected(false)
		
		# Update the UI
		update_hand()
		update_resources()
		update_servers()
	else:
		# Failed to install card
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Cannot install this card. Check if you have enough credits or clicks."
		add_child(dialog)
		dialog.popup_centered()

func _on_action_timer_timeout():
	# Re-enable actions after animation completes
	can_perform_actions = true
	update_action_buttons()
	update_resources()
	update_hand()

func _on_game_started():
	update_player_info()
	update_resources()
	update_hand()
	update_opponent_hand()
	update_servers()

func _on_turn_changed(new_player_id):
	is_player_turn = (new_player_id == player_id)
	update_resources()
	update_action_buttons()
	
	if is_player_turn:
		# Update hand at start of turn
		update_hand()
		
		# Notify player of their turn
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "It's your turn!"
		add_child(dialog)
		dialog.popup_centered()
	else:
		# Opponent's turn
		disable_all_action_buttons()
		
		# Deselect any selected card
		selected_card_index = -1
		selected_card = null
		for card_display in player_cards_container.get_children():
			card_display.set_selected(false)

func _on_credits_changed(changed_player_id, new_amount):
	update_resources()

func _on_card_drawn(player_draw_id, card_data):
	update_resources()
	
	if player_draw_id == player_id:
		update_hand()
	else:
		update_opponent_hand()

func _on_card_played(player_played_id, card_data):
	update_resources()
	
	if player_played_id == player_id:
		update_hand()
	else:
		update_opponent_hand()

func _on_run_started(runner_id, server_id):
	run_active = true
	disable_all_action_buttons()
	
	# Show run animation/effects
	# This would be expanded in a full implementation

func _on_run_ended(run_data):
	run_active = false
	update_action_buttons()
	
	# Show run results
	var message = "Run on " + run_data.server_id + " "
	message += "was successful!" if run_data.successful else "was unsuccessful."
	
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	
	# Update UI after run
	update_resources()
	update_hand()
	update_servers()

func _on_game_over(result_data):
	# Display game over panel
	game_over_panel.visible = true
	
	# Update game over info
	var result_label = $GameOverPanel/VBoxContainer/ResultLabel
	if result_data.winner_id == player_id:
		result_label.text = "You Won!"
		result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	else:
		result_label.text = "You Lost!"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	
	# Show rewards
	$GameOverPanel/VBoxContainer/XPLabel.text = "Experience: +" + str(result_data.xp_gained) + " XP"
	
	var territory_label = $GameOverPanel/VBoxContainer/TerritoryLabel
	if result_data.territory_gained and result_data.winner_id == player_id:
		territory_label.text = "Territory Gained: Sector " + str(result_data.territory_gained.grid_x) + "-" + str(result_data.territory_gained.grid_y)
		territory_label.visible = true
	else:
		territory_label.visible = false
	
	# Disable all game controls
	disable_all_action_buttons()

func _on_continue_button_pressed():
	# Signal to Main.gd that the game has ended
	emit_signal("game_ended", {
		"is_victory": $GameOverPanel/VBoxContainer/ResultLabel.text == "You Won!",
		"xp_gained": 10,  # Placeholder - in real game this would come from result_data
		"territory_gained": GameState.location_data
	})
	
	# Hide game over panel
	game_over_panel.visible = false
