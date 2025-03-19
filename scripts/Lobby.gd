extends Control

signal game_joined(game_data)
signal deck_builder_requested

var games_list = []
var selected_game = null

@onready var username_label = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/UsernameLabel
@onready var faction_label = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/FactionLabel
@onready var level_label = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/LevelLabel
@onready var experience_bar = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/ExperienceBar
@onready var experience_label = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/ExperienceBar/ExperienceLabel
@onready var games_list_container = $MarginContainer/VBoxContainer/HSplitContainer/GamesPanel/VBoxContainer/ScrollContainer/GamesList
@onready var deck_builder_button = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/DeckBuilderButton
@onready var territory_button = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/TerritoryButton
@onready var refresh_button = $MarginContainer/VBoxContainer/HSplitContainer/GamesPanel/VBoxContainer/HBoxContainer/RefreshButton
@onready var create_game_button = $MarginContainer/VBoxContainer/HSplitContainer/GamesPanel/VBoxContainer/HBoxContainer/CreateGameButton
@onready var logout_button = $MarginContainer/VBoxContainer/HSplitContainer/ProfilePanel/VBoxContainer/LogoutButton
@onready var create_game_dialog = $CreateGameDialog
@onready var game_name_input = $CreateGameDialog/VBoxContainer/GameNameInput
@onready var max_players_spin = $CreateGameDialog/VBoxContainer/MaxPlayersSpinBox

func _ready():
        # Connect button signals
        deck_builder_button.pressed.connect(_on_deck_builder_button_pressed)
        territory_button.pressed.connect(_on_territory_button_pressed)
        refresh_button.pressed.connect(_on_refresh_button_pressed)
        create_game_button.pressed.connect(_on_create_game_button_pressed)
        logout_button.pressed.connect(_on_logout_button_pressed)
        
        # Connect dialog signals
        create_game_dialog.confirmed.connect(_on_create_game_dialog_confirmed)
        
        # Clear placeholder game entry
        games_list_container.get_node("GameEntryPlaceholder").queue_free()
        
        # Connect to network manager signals
        NetworkManager.game_state_updated.connect(_on_game_state_updated)

func initialize(player_data):
        # Update profile UI with player data
        username_label.text = "HANDLE: " + player_data.name
        faction_label.text = "FACTION: " + player_data.faction.to_upper()
        level_label.text = "LEVEL: " + str(player_data.level)
        
        # Set up experience bar
        var current_level_exp = ProgressionSystem.XP_REQUIREMENTS[player_data.level]
        var next_level_exp = ProgressionSystem.XP_REQUIREMENTS[min(player_data.level + 1, 10)]
        var level_progress = 0
        
        if next_level_exp > current_level_exp:
                level_progress = float(player_data.experience - current_level_exp) / float(next_level_exp - current_level_exp) * 100
        
        experience_bar.value = level_progress
        experience_label.text = "EXP: " + str(player_data.experience) + "/" + str(next_level_exp)
        
        # Refresh the games list
        refresh_game_list()

func refresh_game_list():
        # Clear existing entries
        for child in games_list_container.get_children():
                child.queue_free()
        
        # Get games from server
        games_list = HttpServer.handle_request("games/list", {})
        
        if games_list and games_list.size() > 0:
                for game in games_list:
                        add_game_to_list(game)
        else:
                # Add a label if no games are available
                var label = Label.new()
                label.text = "No games available. Create a new game to start playing!"
                label.autowrap_mode = true
                games_list_container.add_child(label)

func add_game_to_list(game_data):
        # Create game entry panel
        var panel = Panel.new()
        panel.custom_minimum_size = Vector2(0, 80)
        games_list_container.add_child(panel)
        
        # Create container for content
        var margin = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 10)
        margin.add_theme_constant_override("margin_right", 10)
        margin.add_theme_constant_override("margin_top", 10)
        margin.add_theme_constant_override("margin_bottom", 10)
        panel.add_child(margin)
        margin.set_anchors_preset(Control.PRESET_FULL_RECT)
        
        var hbox = HBoxContainer.new()
        margin.add_child(hbox)
        
        var vbox = VBoxContainer.new()
        vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vbox.theme_override_constants_override("separation", 4)
        hbox.add_child(vbox)
        
        # Game name
        var name_label = Label.new()
        name_label.text = game_data.name
        name_label.add_theme_color_override("font_color", Color(0, 0.639, 0.909))
        vbox.add_child(name_label)
        
        # Players info
        var players_label = Label.new()
        players_label.text = "Players: " + str(game_data.players.size()) + "/" + str(game_data.max_players)
        players_label.add_theme_font_size_override("font_size", 12)
        vbox.add_child(players_label)
        
        # Game status
        var status_label = Label.new()
        status_label.text = "Status: " + game_data.state.capitalize()
        status_label.add_theme_font_size_override("font_size", 12)
        vbox.add_child(status_label)
        
        # Join button
        var join_button = Button.new()
        join_button.text = "JOIN"
        join_button.custom_minimum_size = Vector2(100, 0)
        join_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        hbox.add_child(join_button)
        
        # Disable join button if game is full or already started
        join_button.disabled = (game_data.players.size() >= game_data.max_players) or (game_data.state != "waiting")
        
        # Connect join button
        join_button.pressed.connect(_on_join_button_pressed.bind(game_data.id))

func _on_deck_builder_button_pressed():
        emit_signal("deck_builder_requested")

func _on_territory_button_pressed():
        # Show the territory map
        get_parent().get_parent().show_screen(get_parent().get_parent().GameScreen.TERRITORY_MAP)

func _on_refresh_button_pressed():
        refresh_game_list()

func _on_create_game_button_pressed():
        # Reset dialog fields
        game_name_input.text = ""
        max_players_spin.value = 2
        
        # Show dialog
        create_game_dialog.popup_centered()

func _on_logout_button_pressed():
        # Disconnect from server
        NetworkManager.disconnect_from_server()
        
        # Show login screen
        get_parent().get_parent().show_screen(get_parent().get_parent().GameScreen.LOGIN)

func _on_create_game_dialog_confirmed():
        # Get data from dialog
        var game_name = game_name_input.text.strip_edges()
        var max_players = int(max_players_spin.value)
        
        if game_name.length() < 3:
                # Show error
                var dialog = AcceptDialog.new()
                dialog.dialog_text = "Game name must be at least 3 characters long."
                add_child(dialog)
                dialog.popup_centered()
                return
        
        # Create game data
        var game_data = {
                "name": game_name,
                "max_players": max_players,
                "creator": {
                        "id": NetworkManager.player_id,
                        "name": get_parent().get_parent().player_data.name,
                        "type": get_parent().get_parent().player_data.faction
                }
        }
        
        # Send create game request
        var result = HttpServer.handle_request("games/create", game_data)
        
        if result:
                # Join the created game
                _join_game(result.id)
        else:
                # Show error
                var dialog = AcceptDialog.new()
                dialog.dialog_text = "Failed to create game."
                add_child(dialog)
                dialog.popup_centered()

func _on_join_button_pressed(game_id):
        _join_game(game_id)

func _join_game(game_id):
        # Create player data to join with
        var player_data = {
                "id": NetworkManager.player_id,
                "name": get_parent().get_parent().player_data.name,
                "type": get_parent().get_parent().player_data.faction
        }
        
        # Join request data
        var join_data = {
                "game_id": game_id,
                "player": player_data
        }
        
        # Send join request
        var result = HttpServer.handle_request("games/join", join_data)
        
        if result:
                # Construct game data to pass to game board
                var game_data = {
                        "game_id": result.id,
                        "name": result.name,
                        "players": result.players
                }
                
                # Emit signal that game was joined
                emit_signal("game_joined", game_data)
        else:
                # Show error
                var dialog = AcceptDialog.new()
                dialog.dialog_text = "Failed to join game."
                add_child(dialog)
                dialog.popup_centered()

func _on_game_state_updated(game_data):
        # Update our games list if we receive a game state update
        refresh_game_list()
