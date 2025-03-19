extends Node3D

signal location_selected(location_data)

var hex_scene = preload("res://scenes/HexTile.tscn")
var hex_tiles = {}
var grid_width = 10
var grid_height = 10
var hex_size = 1.0
var selected_tile = null

@onready var camera = $Camera3D
@onready var tile_container = $TileContainer
@onready var info_panel = $CanvasLayer/InfoPanel
@onready var claim_button = $CanvasLayer/InfoPanel/ClaimButton

func _ready():
	# Initialize the territory map
	initialize_map()
	
	# Setup UI connections
	info_panel.visible = false
	claim_button.pressed.connect(_on_claim_button_pressed)
	
	# Connect to territory controller signals
	TerritoryController.territory_updated.connect(_on_territory_updated)
	TerritoryController.territory_claimed.connect(_on_territory_claimed)
	TerritoryController.territory_lost.connect(_on_territory_lost)

func initialize_map():
	# Clear existing tiles
	for child in tile_container.get_children():
		tile_container.remove_child(child)
		child.queue_free()
	
	hex_tiles.clear()
	
	# Create hex grid
	var territories = TerritoryController.get_all_territories()
	
	for territory in territories:
		create_hex_tile(territory)

func create_hex_tile(territory_data):
	var hex = hex_scene.instantiate()
	tile_container.add_child(hex)
	
	# Set position based on hex grid coordinates
	var pos_x = territory_data.position.x * (hex_size * 1.5)
	var pos_z = territory_data.position.y * (hex_size * sqrt(3))
	hex.position = Vector3(pos_x, 0, pos_z)
	
	# Initialize hex data
	hex.initialize(territory_data, self)
	
	# Connect signals
	hex.tile_clicked.connect(_on_tile_clicked)
	hex.tile_hovered.connect(_on_tile_hovered)
	hex.tile_unhovered.connect(_on_tile_unhovered)
	
	# Store reference
	hex_tiles[territory_data.id] = hex

func refresh_map():
	# Update all territories from the controller
	var territories = TerritoryController.get_all_territories()
	
	for territory in territories:
		if hex_tiles.has(territory.id):
			hex_tiles[territory.id].update_from_data(territory)
		else:
			create_hex_tile(territory)

func is_adjacent_to_player_territory(tile):
	# Check if a tile is adjacent to any player-owned territory
	for territory_id in hex_tiles:
		var other_tile = hex_tiles[territory_id]
		
		if other_tile.owner_id == NetworkManager.player_id and tile.is_adjacent_to(other_tile):
			return true
	
	return false

func get_player_territories():
	var player_territories = []
	
	for territory_id in hex_tiles:
		var tile = hex_tiles[territory_id]
		if tile.owner_id == NetworkManager.player_id:
			player_territories.append(tile)
	
	return player_territories

func _on_tile_clicked(tile):
	# Select the tile
	if selected_tile != null:
		selected_tile.highlight_tile(false)
	
	selected_tile = tile
	selected_tile.highlight_tile(true)
	
	# Show info panel
	update_info_panel(tile)
	info_panel.visible = true
	
	# Enable/disable claim button based on ownership
	claim_button.disabled = not tile.can_be_claimed_by_player()

func _on_tile_hovered(tile):
	# Show hover state
	update_info_panel(tile)

func _on_tile_unhovered(tile):
	# If no tile is selected, hide info panel
	if selected_tile == null:
		info_panel.visible = false

func update_info_panel(tile):
	info_panel.get_node("TitleLabel").text = "Sector " + str(tile.grid_x) + "-" + str(tile.grid_y)
	info_panel.get_node("TypeLabel").text = "Type: " + tile.territory_type.capitalize()
	info_panel.get_node("StrengthLabel").text = "Strength: " + str(tile.strength)
	info_panel.get_node("ResourcesLabel").text = "Resources: " + str(tile.resources)
	
	var owner_text = "Unclaimed"
	if tile.owner_id != "":
		if tile.owner_id == NetworkManager.player_id:
			owner_text = "Owned by you"
		else:
			owner_text = "Owned by opponent"
	
	info_panel.get_node("OwnerLabel").text = "Status: " + owner_text
	
	# Show contested state if applicable
	info_panel.get_node("ContestedLabel").visible = tile.contested
	
	# Set info panel visible
	info_panel.visible = true

func _on_claim_button_pressed():
	if selected_tile != null and selected_tile.can_be_claimed_by_player():
		# Claim territory
		var result = TerritoryController.claim_territory(NetworkManager.player_id, selected_tile.territory_id)
		
		if result:
			# If territory is contested, start a game to resolve it
			if selected_tile.contested:
				# Create location data for the game
				var location_data = {
					"territory_id": selected_tile.territory_id,
					"territory_type": selected_tile.territory_type,
					"strength": selected_tile.strength,
					"resources": selected_tile.resources,
					"defender_id": selected_tile.owner_id
				}
				
				emit_signal("location_selected", location_data)

func _on_territory_updated(territory_data):
	if hex_tiles.has(territory_data.id):
		hex_tiles[territory_data.id].update_from_data(territory_data)
		
		# Update info panel if this is the selected tile
		if selected_tile and selected_tile.territory_id == territory_data.id:
			update_info_panel(selected_tile)

func _on_territory_claimed(player_id, territory):
	if hex_tiles.has(territory.id):
		hex_tiles[territory.id].update_from_data(territory)
		
		# Update info panel if this is the selected tile
		if selected_tile and selected_tile.territory_id == territory.id:
			update_info_panel(selected_tile)

func _on_territory_lost(player_id, territory):
	if hex_tiles.has(territory.id):
		hex_tiles[territory.id].update_from_data(territory)
		
		# Update info panel if this is the selected tile
		if selected_tile and selected_tile.territory_id == territory.id:
			update_info_panel(selected_tile)
