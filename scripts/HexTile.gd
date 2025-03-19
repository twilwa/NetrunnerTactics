extends Node3D

# HexTile represents a single hexagonal territory on the map

signal tile_clicked(tile)
signal tile_hovered(tile)
signal tile_unhovered(tile)

@export var territory_id: String = ""
@export var grid_x: int = 0
@export var grid_y: int = 0
@export var territory_type: String = "data_node"

# Territory data
var owner_id: String = ""
var strength: int = 1
var resources: int = 1
var contested: bool = false

# Reference to parent map
var map = null

# Visual components
@onready var hex_mesh = $HexMesh
@onready var highlight = $Highlight
@onready var owner_indicator = $OwnerIndicator
@onready var type_icon = $TypeIcon
@onready var strength_label = $StrengthLabel
@onready var contested_indicator = $ContestedIndicator

# Colors for different territory types
var type_colors = {
	"data_node": Color(0.2, 0.6, 1.0),
	"security_hub": Color(1.0, 0.2, 0.2),
	"credit_farm": Color(0.2, 1.0, 0.2),
	"research_lab": Color(0.8, 0.2, 1.0),
	"blacksite": Color(1.0, 0.5, 0.0)
}

# Colors for player ownership
var player_colors = {
	"": Color(0.5, 0.5, 0.5, 0.5),  # No owner
	"player": Color(0.0, 0.8, 1.0, 0.8),  # Current player
	"opponent": Color(1.0, 0.3, 0.3, 0.8)  # Opponent
}

func _ready():
	highlight.visible = false
	contested_indicator.visible = false
	
	# Setup collision detection for mouse interaction
	var area = $Area3D
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)
	
	# Update visuals
	update_appearance()

func initialize(data, parent_map):
	map = parent_map
	territory_id = data.id
	grid_x = data.grid_x
	grid_y = data.grid_y
	territory_type = data.type
	
	if data.has("owner"):
		owner_id = data.owner
	
	if data.has("strength"):
		strength = data.strength
	
	if data.has("resources"):
		resources = data.resources
	
	if data.has("contested"):
		contested = data.contested
	
	update_appearance()

func update_from_data(data):
	if data.has("owner"):
		owner_id = data.owner
	
	if data.has("strength"):
		strength = data.strength
	
	if data.has("resources"):
		resources = data.resources
	
	if data.has("contested"):
		contested = data.contested
	
	update_appearance()

func update_appearance():
	# Update hex color based on territory type
	if type_colors.has(territory_type):
		hex_mesh.material_override.albedo_color = type_colors[territory_type]
	
	# Update owner indicator
	if owner_id == "":
		owner_indicator.visible = false
	else:
		owner_indicator.visible = true
		
		var owner_type = "opponent"
		if owner_id == NetworkManager.player_id:
			owner_type = "player"
		
		owner_indicator.material_override.albedo_color = player_colors[owner_type]
	
	# Update strength label
	strength_label.text = str(strength)
	
	# Update contested indicator
	contested_indicator.visible = contested
	
	# Update type icon (using a text label for simplicity)
	match territory_type:
		"data_node":
			type_icon.text = "D"
		"security_hub":
			type_icon.text = "S"
		"credit_farm":
			type_icon.text = "$"
		"research_lab":
			type_icon.text = "R"
		"blacksite":
			type_icon.text = "B"

func highlight_tile(show = true):
	highlight.visible = show

func is_adjacent_to(other_tile):
	# Check if another tile is adjacent to this one
	var is_odd_row = grid_y % 2 == 1
	var directions = []
	
	if is_odd_row:
		directions = [
			Vector2i(0, -1),  # North
			Vector2i(1, -1),  # Northeast
			Vector2i(1, 0),   # Southeast
			Vector2i(0, 1),   # South
			Vector2i(-1, 0),  # Southwest
			Vector2i(-1, -1)  # Northwest
		]
	else:
		directions = [
			Vector2i(0, -1),  # North
			Vector2i(1, 0),   # Northeast
			Vector2i(1, 1),   # Southeast
			Vector2i(0, 1),   # South
			Vector2i(-1, 1),  # Southwest
			Vector2i(-1, 0)   # Northwest
		]
	
	for dir in directions:
		var adj_x = grid_x + dir.x
		var adj_y = grid_y + dir.y
		
		if other_tile.grid_x == adj_x and other_tile.grid_y == adj_y:
			return true
	
	return false

func can_be_claimed_by_player():
	# Player can claim if:
	# 1. Territory is unclaimed, or
	# 2. Territory is owned by opponent and adjacent to player territory
	
	if owner_id == "":
		# Check if adjacent to any player-owned territory
		return map.is_adjacent_to_player_territory(self)
	elif owner_id != NetworkManager.player_id:
		# Territory owned by opponent
		return map.is_adjacent_to_player_territory(self)
	
	return false

func _on_mouse_entered():
	highlight_tile(true)
	emit_signal("tile_hovered", self)

func _on_mouse_exited():
	highlight_tile(false)
	emit_signal("tile_unhovered", self)

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("tile_clicked", self)
