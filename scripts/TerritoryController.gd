extends Node

# TerritoryController manages the city grid map and territory control mechanics

signal territory_claimed(territory, player_id)
signal territory_abandoned(territory, player_id)
signal territory_attacked(territory, attacker_id)
signal territory_defended(territory, defender_id)
signal map_generated(map_data)

# Map generation parameters
const MAP_WIDTH = 32
const MAP_HEIGHT = 24
const MIN_TERRITORIES = 48
const MAX_TERRITORIES = 64

# Territory types and their properties
const TERRITORY_TYPES = {
	"data_node": {
		"name": "Data Node",
		"description": "Network hub that generates data resources",
		"resource_type": "data",
		"base_strength": 2,
		"resource_gen": 1
	},
	"security_hub": {
		"name": "Security Hub",
		"description": "Fortified server that protects connected territories",
		"resource_type": "security",
		"base_strength": 4,
		"resource_gen": 1
	},
	"finance_center": {
		"name": "Finance Center",
		"description": "Economic node that generates credits",
		"resource_type": "credits",
		"base_strength": 3,
		"resource_gen": 2
	},
	"research_lab": {
		"name": "Research Lab",
		"description": "R&D facility that accelerates card development",
		"resource_type": "research",
		"base_strength": 2,
		"resource_gen": 1
	},
	"black_market": {
		"name": "Black Market",
		"description": "Underground market with rare resources",
		"resource_type": "contraband",
		"base_strength": 1,
		"resource_gen": 3
	}
}

# Current map data
var city_map = []
var territory_data = {}
var available_territories = []
var claimed_territories = {}

func _ready():
	# Generate initial map when the game starts
	generate_map()

func generate_map():
	# Reset map data
	city_map = []
	territory_data = {}
	available_territories = []
	claimed_territories = {}
	
	# Initialize empty map
	for x in range(MAP_WIDTH):
		city_map.append([])
		for y in range(MAP_HEIGHT):
			city_map[x].append(null)
	
	# Decide how many territories to generate
	var territory_count = randi() % (MAX_TERRITORIES - MIN_TERRITORIES + 1) + MIN_TERRITORIES
	
	# Generate territories
	var territories_generated = 0
	var attempts = 0
	var max_attempts = 1000
	
	while territories_generated < territory_count and attempts < max_attempts:
		attempts += 1
		
		# Pick a random position (adjusted for hex grid)
		var x = randi() % MAP_WIDTH
		var y = randi() % MAP_HEIGHT
		
		# Adjust y position for even columns on a hex grid
		if x % 2 == 0:
			y = max(0, min(MAP_HEIGHT - 1, y))
		
		# Check if position is empty and has valid neighbors
		if city_map[x][y] == null and is_valid_territory_position(x, y):
			# Create a new territory
			var territory_id = "t_" + str(territories_generated)
			var territory_type = get_random_territory_type()
			
			# Store territory data
			territory_data[territory_id] = {
				"id": territory_id,
				"x": x,
				"y": y,
				"type": territory_type,
				"name": TERRITORY_TYPES[territory_type].name,
				"description": TERRITORY_TYPES[territory_type].description,
				"strength": TERRITORY_TYPES[territory_type].base_strength,
				"resource_type": TERRITORY_TYPES[territory_type].resource_type,
				"resource_amount": TERRITORY_TYPES[territory_type].resource_gen,
				"owner": null,
				"neighbors": get_neighboring_territories(x, y)
			}
			
			# Mark the position as occupied by this territory
			city_map[x][y] = territory_id
			
			# Add to available territories
			available_territories.append(territory_id)
			
			# Successfully generated a territory
			territories_generated += 1
	
	# Emit signal with generated map data
	emit_signal("map_generated", {
		"map": city_map,
		"territories": territory_data,
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT
	})

func is_valid_territory_position(x, y):
	# Check bounds
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT:
		return false
	
	# Check if already occupied
	if city_map[x][y] != null:
		return false
	
	# A position is valid if it either:
	# 1. Has at least one neighbor territory (for connectivity)
	# 2. Is one of the first few territories being placed
	
	var has_neighbor = false
	var neighbors = get_neighboring_coordinates(x, y)
	
	for neighbor in neighbors:
		var nx = neighbor.x
		var ny = neighbor.y
		
		if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
			if city_map[nx][ny] != null:
				has_neighbor = true
				break
	
	# Allow isolated territories if the map is mostly empty
	var territory_count = 0
	for t in territory_data:
		territory_count += 1
	
	if territory_count < 5:
		return true
	
	return has_neighbor

func get_neighboring_coordinates(x, y):
	var neighbors = []
	var offsets = []
	
	# Hex grid neighbor offsets (depends on even/odd column)
	if x % 2 == 0:  # Even column
		offsets = [
			Vector2(1, 0),   # Right
			Vector2(1, -1),  # Up-Right
			Vector2(0, -1),  # Up
			Vector2(-1, -1), # Up-Left
			Vector2(-1, 0),  # Left
			Vector2(0, 1)    # Down
		]
	else:  # Odd column
		offsets = [
			Vector2(1, 0),   # Right
			Vector2(1, 1),   # Down-Right
			Vector2(0, -1),  # Up
			Vector2(-1, 1),  # Down-Left
			Vector2(-1, 0),  # Left
			Vector2(0, 1)    # Down
		]
	
	for offset in offsets:
		neighbors.append(Vector2(x + offset.x, y + offset.y))
	
	return neighbors

func get_neighboring_territories(x, y):
	var neighbors = []
	var neighbor_coords = get_neighboring_coordinates(x, y)
	
	for coord in neighbor_coords:
		var nx = coord.x
		var ny = coord.y
		
		if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
			if city_map[nx][ny] != null:
				neighbors.append(city_map[nx][ny])
	
	return neighbors

func get_random_territory_type():
	var types = TERRITORY_TYPES.keys()
	return types[randi() % types.size()]

func claim_territory(territory_id, player_id):
	if not territory_data.has(territory_id):
		return false
	
	var territory = territory_data[territory_id]
	
	# Check if already claimed
	if territory.owner != null:
		return false
	
	# Claim the territory
	territory.owner = player_id
	
	# Remove from available territories
	available_territories.erase(territory_id)
	
	# Add to claimed territories
	if not claimed_territories.has(player_id):
		claimed_territories[player_id] = []
	claimed_territories[player_id].append(territory_id)
	
	# Emit signal about claimed territory
	emit_signal("territory_claimed", territory, player_id)
	
	return true

func abandon_territory(territory_id, player_id):
	if not territory_data.has(territory_id):
		return false
	
	var territory = territory_data[territory_id]
	
	# Check if claimed by the player
	if territory.owner != player_id:
		return false
	
	# Abandon the territory
	territory.owner = null
	
	# Add to available territories
	available_territories.append(territory_id)
	
	# Remove from claimed territories
	if claimed_territories.has(player_id):
		claimed_territories[player_id].erase(territory_id)
	
	# Emit signal about abandoned territory
	emit_signal("territory_abandoned", territory, player_id)
	
	return true

func attack_territory(territory_id, attacker_id, attack_strength):
	if not territory_data.has(territory_id):
		return false
	
	var territory = territory_data[territory_id]
	
	# Can only attack territories owned by others
	if territory.owner == null or territory.owner == attacker_id:
		return false
	
	# Compare attack strength with territory defense
	var defense_strength = territory.strength
	
	# Emit signal about the attack
	emit_signal("territory_attacked", territory, attacker_id)
	
	# If attack is successful, transfer ownership
	if attack_strength > defense_strength:
		var previous_owner = territory.owner
		
		# Remove from previous owner's claimed territories
		if claimed_territories.has(previous_owner):
			claimed_territories[previous_owner].erase(territory_id)
		
		# Claim for the attacker
		territory.owner = attacker_id
		
		# Add to claimed territories
		if not claimed_territories.has(attacker_id):
			claimed_territories[attacker_id] = []
		claimed_territories[attacker_id].append(territory_id)
		
		return true
	else:
		# Defense was successful
		emit_signal("territory_defended", territory, territory.owner)
		return false

func get_player_territories(player_id):
	if claimed_territories.has(player_id):
		return claimed_territories[player_id]
	return []

func get_territory_info(territory_id):
	if territory_data.has(territory_id):
		return territory_data[territory_id]
	return null

func get_available_territories():
	return available_territories

func calculate_territory_resources(player_id):
	var resources = {
		"data": 0,
		"security": 0,
		"credits": 0,
		"research": 0,
		"contraband": 0
	}
	
	if claimed_territories.has(player_id):
		for territory_id in claimed_territories[player_id]:
			var territory = territory_data[territory_id]
			var resource_type = territory.resource_type
			var amount = territory.resource_amount
			
			if resources.has(resource_type):
				resources[resource_type] += amount
	
	return resources

func increase_territory_strength(territory_id, amount):
	if territory_data.has(territory_id):
		territory_data[territory_id].strength += amount
		return true
	return false

func decrease_territory_strength(territory_id, amount):
	if territory_data.has(territory_id):
		territory_data[territory_id].strength = max(1, territory_data[territory_id].strength - amount)
		return true
	return false

func get_connected_territories(territory_id):
	var connected = []
	
	if territory_data.has(territory_id):
		var territory = territory_data[territory_id]
		var owner_id = territory.owner
		
		# If territory is not claimed, return empty list
		if owner_id == null:
			return []
		
		# Start with this territory
		var to_check = [territory_id]
		var checked = []
		
		# Breadth-first search for connected territories
		while to_check.size() > 0:
			var current = to_check.pop_front()
			
			if checked.has(current):
				continue
			
			checked.append(current)
			connected.append(current)
			
			# Check neighbors of the same owner
			for neighbor_id in territory_data[current].neighbors:
				if territory_data.has(neighbor_id) and territory_data[neighbor_id].owner == owner_id:
					if not checked.has(neighbor_id) and not to_check.has(neighbor_id):
						to_check.append(neighbor_id)
	
	return connected