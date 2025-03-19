extends "res://scripts/Player.gd"

# CorpPlayer handles corp-specific gameplay logic

var bad_publicity = 0
var installed_ice = []
var installed_assets = []
var installed_upgrades = []
var installed_agendas = []
var remote_servers = []
var hq_upgrades = []
var rd_upgrades = []
var archives_upgrades = []

# Central server data
var hq = {"ice": [], "content": []}
var rd = {"ice": [], "content": []}
var archives = {"ice": [], "content": []}

func _init():
	player_type = PlayerType.CORP
	faction = "corp"

func _ready():
	# Connect to specific corp events
	GameState.connect("bad_publicity_changed", self, "_on_bad_publicity_changed")

func setup_player():
	# Corp-specific setup
	max_hand_size = 5
	starting_credits = 5
	
	# Create central servers
	create_central_servers()
	draw_starting_hand()

func create_central_servers():
	# HQ, R&D, and Archives are predefined
	hq = {"ice": [], "content": [], "server_id": "hq", "name": "HQ"}
	rd = {"ice": [], "content": [], "server_id": "rd", "name": "R&D"}
	archives = {"ice": [], "content": [], "server_id": "archives", "name": "Archives"}

func create_remote_server():
	var server_id = "remote_" + str(remote_servers.size() + 1)
	var server = {"ice": [], "content": [], "server_id": server_id, "name": "Remote " + str(remote_servers.size() + 1)}
	remote_servers.append(server)
	
	# Emit signal for UI update
	emit_signal("server_created", server)
	
	return server

func draw_starting_hand():
	# Draw 5 cards for corp
	for i in range(5):
		draw_card()

func start_turn():
	super.start_turn()
	
	# Corp gets 3 clicks per turn
	add_clicks(3)
	
	# Corp draws a card at the start of turn
	if not is_deck_empty():
		draw_card()
	else:
		# If corp is forced to draw and can't, runner wins
		GameState.end_game(GameState.get_runner_id())

func install_card(card, server=null, payment=null):
	# Check if we can pay the cost (ice needs to be rezzed separately)
	if card.card_type != "ice" and credits < card.cost:
		return false
	
	match card.card_type:
		"ice":
			# We need a server to install ice on
			if server == null:
				return false
			
			# Position determines where in the server's ice array this goes
			var position = payment.get("position", server.ice.size())
			
			# Install the ice
			server.ice.insert(position, card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "server", "server": server.server_id, "position": position, "type": "ice"})
			
			emit_signal("card_installed", card)
			return true
			
		"agenda":
			# We need a server to install the agenda in
			if server == null:
				return false
			
			# Pay the cost
			modify_credits(-card.cost)
			
			# Install the agenda
			server.content.append(card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "server", "server": server.server_id, "type": "agenda"})
			
			emit_signal("card_installed", card)
			return true
			
		"asset":
			# We need a server to install the asset in
			if server == null:
				return false
			
			# Pay the cost
			modify_credits(-card.cost)
			
			# Each remote server can only have one asset or agenda
			for existing in server.content:
				if existing.card_type == "asset" or existing.card_type == "agenda":
					# Trash the existing card
					trash_card(existing)
			
			# Install the asset
			server.content.append(card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "server", "server": server.server_id, "type": "asset"})
			
			emit_signal("card_installed", card)
			return true
			
		"upgrade":
			# We need a server to install the upgrade in
			if server == null:
				return false
			
			# Pay the cost
			modify_credits(-card.cost)
			
			# Install the upgrade
			server.content.append(card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "server", "server": server.server_id, "type": "upgrade"})
			
			emit_signal("card_installed", card)
			return true
			
		"operation":
			# Operations are played, not installed
			return play_operation(card)
	
	return false

func play_operation(card):
	# Check if we can pay the cost
	if credits < card.cost:
		return false
	
	# Spend credits
	modify_credits(-card.cost)
	
	# Apply card effect
	GameState.apply_card_effect(player_id, card, null)
	
	# Move to discard
	discard_pile.append(card)
	card.set_location({"zone": "discard"})
	
	emit_signal("card_played", card)
	return true

func rez_card(card):
	# Check if card is installed and unrezzed
	if not card.is_installed or card.is_rezzed:
		return false
	
	# Check if corp can afford the rez cost
	if credits < card.rez_cost:
		return false
	
	# Pay the cost
	modify_credits(-card.rez_cost)
	
	# Rez the card
	card.is_rezzed = true
	
	# Apply any "when rezzed" effects
	if card.effect.has("on_rez"):
		GameState.apply_card_effect(player_id, card, null)
	
	emit_signal("card_rezzed", card)
	return true

func advance_card(card):
	# Check if card can be advanced
	if not card.is_installed or not card.can_be_advanced():
		return false
	
	# Check if corp has a click and a credit
	if clicks <= 0 or credits <= 0:
		return false
	
	# Pay the costs
	spend_click()
	modify_credits(-1)
	
	# Add advancement token
	card.advancement_tokens += 1
	
	# Check if agenda can be scored
	if card.card_type == "agenda" and card.advancement_tokens >= card.advancement_requirement:
		score_agenda(card)
	
	emit_signal("card_advanced", card)
	return true

func score_agenda(card):
	# Make sure it's an agenda
	if card.card_type != "agenda":
		return false
	
	# Make sure it's advanced enough
	if card.advancement_tokens < card.advancement_requirement:
		return false
	
	# Remove from server
	var location = card.location
	if location.has("server"):
		var server = get_server_by_id(location.server)
		if server:
			server.content.erase(card)
	
	# Add to scored area
	scored_agendas.append(card)
	card.set_location({"zone": "scored"})
	
	# Apply "when scored" effects
	if card.effect.has("on_score"):
		GameState.apply_card_effect(player_id, card, null)
	
	# Check for win condition
	GameState.check_win_condition()
	
	emit_signal("agenda_scored", card)
	return true

func trash_card(card):
	# Can only trash installed cards
	if not card.is_installed:
		return false
	
	# Remove from server
	var location = card.location
	if location.has("server"):
		var server = get_server_by_id(location.server)
		if server:
			if location.get("type") == "ice":
				server.ice.erase(card)
			else:
				server.content.erase(card)
	
	# Add to archives
	archives.content.append(card)
	card.is_installed = false
	card.is_rezzed = false
	card.set_location({"zone": "discard"})
	
	emit_signal("card_trashed", card)
	return true

func get_server_by_id(server_id):
	match server_id:
		"hq":
			return hq
		"rd":
			return rd
		"archives":
			return archives
	
	# Look for remote server
	for server in remote_servers:
		if server.server_id == server_id:
			return server
	
	return null

func add_bad_publicity(amount = 1):
	bad_publicity += amount
	GameState.emit_signal("bad_publicity_changed", player_id, bad_publicity)

func remove_bad_publicity(amount = 1):
	bad_publicity = max(0, bad_publicity - amount)
	GameState.emit_signal("bad_publicity_changed", player_id, bad_publicity)

func get_all_servers():
	var servers = [hq, rd, archives]
	servers.append_array(remote_servers)
	return servers

func get_installed_cards():
	var all_cards = []
	
	# Get ice from all servers
	for server in get_all_servers():
		all_cards.append_array(server.ice)
		all_cards.append_array(server.content)
	
	return all_cards

func _on_bad_publicity_changed(player, new_amount):
	if player == player_id:
		bad_publicity = new_amount
