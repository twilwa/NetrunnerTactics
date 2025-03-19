extends Control

signal login_successful(user_data)

var selected_faction = ""

@onready var username_input = $CenterContainer/LoginPanel/VBoxContainer/UsernameInput
@onready var corp_button = $CenterContainer/LoginPanel/VBoxContainer/FactionButtons/CorpButton
@onready var runner_button = $CenterContainer/LoginPanel/VBoxContainer/FactionButtons/RunnerButton
@onready var connect_button = $CenterContainer/LoginPanel/VBoxContainer/ConnectButton
@onready var error_label = $CenterContainer/LoginPanel/VBoxContainer/ErrorLabel

func _ready():
        # Connect button signals
        corp_button.pressed.connect(_on_corp_button_pressed)
        runner_button.pressed.connect(_on_runner_button_pressed)
        connect_button.pressed.connect(_on_connect_button_pressed)
        username_input.text_changed.connect(_validate_login_form)
        
        # Style the faction buttons
        corp_button.add_theme_color_override("font_color", Color(0.1, 0.6, 0.9))
        runner_button.add_theme_color_override("font_color", Color(0.1, 0.6, 0.9))
        
        # Initialize with connect button disabled
        connect_button.disabled = true

func _on_corp_button_pressed():
        selected_faction = "corp"
        update_faction_button_styles()
        _validate_login_form()

func _on_runner_button_pressed():
        selected_faction = "runner"
        update_faction_button_styles()
        _validate_login_form()

func update_faction_button_styles():
        # Reset both buttons
        corp_button.add_theme_color_override("font_color", Color(0.1, 0.6, 0.9))
        runner_button.add_theme_color_override("font_color", Color(0.1, 0.6, 0.9))
        
        # Highlight selected button
        if selected_faction == "corp":
                corp_button.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
        elif selected_faction == "runner":
                runner_button.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))

func _validate_login_form():
        var username = username_input.text.strip_edges()
        
        # Enable connect button only if username is valid and faction is selected
        connect_button.disabled = (username.length() < 3 || selected_faction == "")
        
        # Hide any previous error
        error_label.visible = false

func _on_connect_button_pressed():
        var username = username_input.text.strip_edges()
        
        # Show connecting indicator
        error_label.text = "Connecting..."
        error_label.add_theme_color_override("font_color", Color(0.1, 0.6, 0.9))
        error_label.visible = true
        
        # Disable the button during connection attempt
        connect_button.disabled = true
        
        # Attempt to create player
        var player_data = {
                "name": username,
                "faction": selected_faction
        }
        
        # Register with the server
        var result = HttpServer.handle_request("register", player_data)
        
        if result:
                # Create user data to pass to main
                var user_data = {
                        "id": result.id,
                        "name": result.name,
                        "faction": selected_faction,
                        "level": result.level,
                        "experience": result.experience,
                        "territories": result.territories,
                        "decks": result.decks
                }
                
                # Connect to server
                NetworkManager.auth_token = result.id  # Use ID as auth token
                NetworkManager.connect_to_server(result.id)
                
                # Wait for connection before proceeding
                await NetworkManager.connection_established
                
                # Emit signal that login was successful
                emit_signal("login_successful", user_data)
        else:
                # Show error message
                error_label.text = "Failed to create player profile"
                error_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
                error_label.visible = true
                
                # Re-enable the button
                connect_button.disabled = false
