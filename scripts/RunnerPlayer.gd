extends "res://scripts/Player.gd"

# RunnerPlayer handles runner-specific gameplay logic

var memory_limit = 4
var memory_used = 0
var tags = 0
var brain_damage = 0
var installed_programs = []
var installed_resources = []
var installed_hardware = []
var current_run = null

func _init():
	player_type = PlayerType.RUNNER
	faction = "runner"

func _ready():
	# Connect to specific runner events
	GameState.connect("tags_changed", self, "_on_tags_changed")
	GameState.connect("memory_changed", self, "_on_memory_changed")
	GameState.connect("run_started", self, "_on_run_started")
	GameState.connect("run_ended", self, "_on_run_ended")

func setup_player():
	# Runner-specific setup
	max_hand_size = 5
	starting_credits = 5
	draw_starting_hand()

func draw_starting_hand():
	# Draw 5 cards for runner
	for i in range(5):
		draw_card()

func start_turn():
	super.start_turn()
	# Runner gets 4 clicks per turn
	add_clicks(4)

func calculate_memory_used():
	# Calculate memory usage from all installed programs
	var total_memory = 0
	
	for program in installed_programs:
		total_memory += program.memory_cost
	
	# Apply memory modifications from installed hardware
	for hardware in installed_hardware:
		if hardware.effect.has("modify_memory"):
			total_memory -= hardware.effect.modify_memory
	
	memory_used = total_memory
	
	# Emit updated memory signal
	GameState.emit_signal("memory_changed", player_id, memory_used, memory_limit)
	
	return memory_used

func has_enough_memory(memory_cost):
	return (memory_used + memory_cost) <= memory_limit

func install_card(card, payment = null):
	# Check if we can pay the cost
	if credits < card.cost:
		return false
	
	match card.card_type:
		"program":
			# Check memory limits
			if not has_enough_memory(card.memory_cost):
				return false
			
			# Spend credits
			modify_credits(-card.cost)
			
			# Install the program
			installed_programs.append(card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "rig", "type": "program"})
			
			# Update memory
			calculate_memory_used()
			
			emit_signal("card_installed", card)
			return true
			
		"hardware":
			# Spend credits
			modify_credits(-card.cost)
			
			# Install the hardware
			installed_hardware.append(card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "rig", "type": "hardware"})
			
			# Console is unique - remove any existing console
			if "console" in card.card_subtype:
				for hw in installed_hardware:
					if hw != card and "console" in hw.card_subtype:
						uninstall_card(hw)
			
			# Apply memory modifications and recalculate
			calculate_memory_used()
			
			emit_signal("card_installed", card)
			return true
			
		"resource":
			# Spend credits
			modify_credits(-card.cost)
			
			# Install the resource
			installed_resources.append(card)
			card.is_installed = true
			card.controller = player_id
			card.set_location({"zone": "rig", "type": "resource"})
			
			emit_signal("card_installed", card)
			return true
			
		"event":
			# Events are played, not installed
			return play_event(card)
	
	return false

func play_event(card):
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

func uninstall_card(card):
	match card.card_type:
		"program":
			installed_programs.erase(card)
			calculate_memory_used()
		"hardware":
			installed_hardware.erase(card)
			calculate_memory_used()
		"resource":
			installed_resources.erase(card)
	
	card.is_installed = false
	discard_pile.append(card)
	card.set_location({"zone": "discard"})
	
	emit_signal("card_uninstalled", card)

func initiate_run(server_id, card_used = null):
	# Check if runner has at least 1 click
	if clicks <= 0:
		return false
	
	# Spend a click to run
	spend_click()
	
	# Start the run in GameState
	current_run = {
		"server_id": server_id,
		"card_used": card_used,
		"successful": false,
		"step": "initiation"
	}
	
	GameState.start_run(server_id)
	return true

func jack_out():
	# Runner voluntarily ends the run
	if current_run and current_run.step != "complete":
		GameState.end_run(current_run, false)
		current_run.step = "complete"
		current_run = null
		return true
	
	return false

func add_tag(amount = 1):
	tags += amount
	GameState.emit_signal("tags_changed", player_id, tags)

func remove_tag(amount = 1):
	tags = max(0, tags - amount)
	GameState.emit_signal("tags_changed", player_id, tags)

func get_installed_cards():
	var all_cards = []
	all_cards.append_array(installed_programs)
	all_cards.append_array(installed_hardware)
	all_cards.append_array(installed_resources)
	return all_cards

func _on_tags_changed(player, new_tags):
	if player == player_id:
		tags = new_tags

func _on_memory_changed(player, used, limit):
	if player == player_id:
		memory_used = used
		memory_limit = limit

func _on_run_started(runner, server):
	if runner == player_id:
		current_run = {
			"server_id": server,
			"successful": false,
			"step": "initiation"
		}

func _on_run_ended(run_data):
	if current_run and run_data.runner_id == player_id:
		current_run.successful = run_data.successful
		current_run.step = "complete"
