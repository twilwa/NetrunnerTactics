extends Control

signal card_clicked(card_display)

var card_data = null
var is_facedown = false
var is_selected = false

@onready var card_panel = $CardPanel
@onready var title_label = $CardPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var cost_label = $CardPanel/MarginContainer/VBoxContainer/CostLabel
@onready var type_label = $CardPanel/MarginContainer/VBoxContainer/TypeLabel
@onready var subtype_label = $CardPanel/MarginContainer/VBoxContainer/SubtypeLabel
@onready var text_label = $CardPanel/MarginContainer/VBoxContainer/TextLabel
@onready var strength_label = $CardPanel/MarginContainer/VBoxContainer/StrengthLabel

func _ready():
	# Connect input events
	gui_input.connect(_on_gui_input)

func initialize(card):
	card_data = card
	is_facedown = false
	
	# Set card info
	title_label.text = card.title
	cost_label.text = "Cost: " + str(card.cost)
	type_label.text = "Type: " + card.type.capitalize()
	
	# Set subtype if present
	if card.has("subtype") and card.subtype.size() > 0:
		subtype_label.text = " ".join(card.subtype)
		subtype_label.visible = true
	else:
		subtype_label.visible = false
	
	# Set card text (truncated for display)
	text_label.text = truncate_text(card.text, 100)
	
	# Show strength for ice and programs
	if card.has("strength"):
		strength_label.text = "Strength: " + str(card.strength)
		strength_label.visible = true
	else:
		strength_label.visible = false
	
	# Set card color based on faction
	var card_color = Color(0.129, 0.129, 0.157)  # Default color
	
	if card.type == "identity":
		if "corp" in card.subtype or card.title.to_lower().contains("corp"):
			card_color = Color(0.15, 0.15, 0.3)  # Corp blue
		else:
			card_color = Color(0.25, 0.15, 0.15)  # Runner red
	else:
		# Color based on card type
		match card.type:
			"ice":
				card_color = Color(0.15, 0.15, 0.3)  # Blue
			"agenda":
				card_color = Color(0.25, 0.25, 0.1)  # Yellow
			"asset", "upgrade":
				card_color = Color(0.15, 0.25, 0.15)  # Green
			"operation":
				card_color = Color(0.2, 0.1, 0.25)  # Purple
			"program":
				card_color = Color(0.1, 0.25, 0.25)  # Cyan
			"hardware":
				card_color = Color(0.25, 0.15, 0.1)  # Orange
			"resource":
				card_color = Color(0.2, 0.2, 0.2)  # Gray
			"event":
				card_color = Color(0.25, 0.1, 0.1)  # Red
	
	# Apply color to panel
	var style_box = card_panel.get_theme_stylebox("panel").duplicate()
	style_box.bg_color = card_color
	card_panel.add_theme_stylebox_override("panel", style_box)

func initialize_facedown():
	is_facedown = true
	
	# Hide all card details
	title_label.text = "???"
	cost_label.text = ""
	type_label.text = ""
	subtype_label.visible = false
	text_label.text = ""
	strength_label.visible = false
	
	# Set card back color
	var style_box = card_panel.get_theme_stylebox("panel").duplicate()
	style_box.bg_color = Color(0.1, 0.1, 0.1)
	card_panel.add_theme_stylebox_override("panel", style_box)

func set_selected(selected):
	is_selected = selected
	
	# Apply visual selection effect
	var style_box = card_panel.get_theme_stylebox("panel").duplicate()
	
	if selected:
		style_box.border_color = Color(1, 0.8, 0)  # Gold highlight
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
	else:
		style_box.border_color = Color(0, 0.639, 0.909)  # Default blue border
		style_box.border_width_left = 1
		style_box.border_width_top = 1
		style_box.border_width_right = 1
		style_box.border_width_bottom = 1
	
	card_panel.add_theme_stylebox_override("panel", style_box)

func truncate_text(text, max_length):
	if text.length() <= max_length:
		return text
	
	return text.substr(0, max_length) + "..."

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_clicked", self)
