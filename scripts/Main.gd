extends Node

# Main controller script for the CyberRunner game
# Handles transitions between different game states and scenes

enum GameScreen {
	LOGIN,
	LOBBY,
	DECK_BUILDER,
	TERRITORY_MAP,
	GAME_BOARD
}

var current_screen = GameScreen.LOGIN
var player_data = {}
var is_logged_in = false

@onready var login_scene = $Login
@onready var lobby_scene = $Lobby
@onready var deck_builder_scene = $DeckBuilder
@onready var territory_map_scene = $TerritoryMap
@onready var game_board_scene = $GameBoard

func _ready():
	# Start with only login visible, hide other screens
	show_screen(GameScreen.LOGIN)
	
	# Connect signals from child scenes
	login_scene.login_successful.connect(_on_login_successful)
	lobby_scene.game_joined.connect(_on_game_joined)
	lobby_scene.deck_builder_requested.connect(_on_deck_builder_requested)
	deck_builder_scene.deck_saved.connect(_on_deck_saved)
	territory_map_scene.location_selected.connect(_on_location_selected)
	game_board_scene.game_ended.connect(_on_game_ended)
	
	# Initialize network manager
	NetworkManager.connection_established.connect(_on_connection_established)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.initialize()

func show_screen(screen):
	# Hide all screens
	login_scene.visible = false
	lobby_scene.visible = false
	deck_builder_scene.visible = false 
	territory_map_scene.visible = false
	game_board_scene.visible = false
	
	# Show requested screen
	current_screen = screen
	match screen:
		GameScreen.LOGIN:
			login_scene.visible = true
		GameScreen.LOBBY:
			lobby_scene.visible = true
			lobby_scene.refresh_game_list()
		GameScreen.DECK_BUILDER:
			deck_builder_scene.visible = true
		GameScreen.TERRITORY_MAP:
			territory_map_scene.visible = true
			territory_map_scene.refresh_map()
		GameScreen.GAME_BOARD:
			game_board_scene.visible = true

func _on_login_successful(user_data):
	player_data = user_data
	is_logged_in = true
	show_screen(GameScreen.LOBBY)
	
func _on_game_joined(game_data):
	GameState.initialize_game(game_data)
	show_screen(GameScreen.GAME_BOARD)
	
func _on_deck_builder_requested():
	show_screen(GameScreen.DECK_BUILDER)
	
func _on_deck_saved(deck_data):
	player_data.decks = player_data.decks or []
	player_data.decks.append(deck_data)
	show_screen(GameScreen.LOBBY)
	
func _on_location_selected(location_data):
	GameState.set_game_location(location_data)
	show_screen(GameScreen.GAME_BOARD)
	
func _on_game_ended(result_data):
	# Update player progress based on game results
	if result_data.is_victory:
		ProgressionSystem.add_experience(player_data, result_data.xp_gained)
		ProgressionSystem.add_territory(player_data, result_data.territory_gained)
	
	# Return to the territory map
	show_screen(GameScreen.TERRITORY_MAP)

func _on_connection_established():
	print("Connection to server established")
	
func _on_connection_failed():
	print("Connection to server failed")
	# Show error message to user
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Failed to connect to the game server. Please check your connection and try again."
	dialog.dialog_autowrap = true
	add_child(dialog)
	dialog.popup_centered()
