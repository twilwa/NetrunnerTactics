extends Node

# NetworkManager handles all network communication with the server

signal connection_established
signal connection_failed
signal game_state_updated(game_data)
signal player_joined(player_data)
signal player_left(player_id)
signal chat_message_received(message_data)
signal card_played(card_data)
signal run_initiated(run_data)
signal territory_updated(territory_data)
signal auth_response_received(response_data)
signal game_created(game_data)
signal game_joined(game_data)
signal error_received(error_data)

var peer = WebSocketPeer.new()
var server_url = "ws://localhost:5000" # Local server for development
var is_connected = false
var connection_in_progress = false
var player_id = ""
var auth_token = ""
var message_queue = []
var reconnect_timer = null
var auto_reconnect = true

func _ready():
        # Initialize reconnect timer
        reconnect_timer = Timer.new()
        reconnect_timer.wait_time = 3.0
        reconnect_timer.one_shot = true
        reconnect_timer.timeout.connect(_on_reconnect_timer_timeout)
        add_child(reconnect_timer)

func _process(delta):
        if is_connected or connection_in_progress:
                peer.poll()
                var state = peer.get_ready_state()
                
                if state == WebSocketPeer.STATE_OPEN:
                        if connection_in_progress:
                                _on_connection_established()
                        
                        # Process any queued messages
                        while message_queue.size() > 0:
                                var message = message_queue.pop_front()
                                var err = peer.send_text(message)
                                if err != OK:
                                        print("Failed to send queued message: ", err)
                        
                        # Process incoming messages
                        while peer.get_available_packet_count():
                                _on_data_received()
                                
                elif state == WebSocketPeer.STATE_CLOSING:
                        # WebSocket is in closing state.
                        print("WebSocket connection closing...")
                        
                elif state == WebSocketPeer.STATE_CLOSED:
                        var code = peer.get_close_code()
                        var reason = peer.get_close_reason()
                        is_connected = false
                        connection_in_progress = false
                        _on_connection_closed(code == 1000)
                        
                        # Try to reconnect if enabled
                        if auto_reconnect:
                                print("Scheduling reconnection attempt...")
                                reconnect_timer.start()

func initialize():
        # Connect to the server with default configuration
        connect_to_server()

func _on_reconnect_timer_timeout():
        if !is_connected and !connection_in_progress:
                print("Attempting to reconnect...")
                connect_to_server(auth_token)

func connect_to_server(token = ""):
        if is_connected or connection_in_progress:
                return
                
        auth_token = token
        connection_in_progress = true
        
        var err = peer.connect_to_url(server_url)
        if err != OK:
                connection_in_progress = false
                emit_signal("connection_failed")
                print("Failed to connect to server: ", err)

func disconnect_from_server():
        if is_connected:
                peer.close()
                is_connected = false

func _on_connection_established():
        print("Connection established")
        is_connected = true
        connection_in_progress = false
        
        # Authenticate with the server if we have a token
        if auth_token != "":
                send_message("authenticate", {"token": auth_token})
        
        emit_signal("connection_established")

func _on_connection_failed():
        print("Connection failed!")
        is_connected = false
        connection_in_progress = false
        emit_signal("connection_failed")

func _on_connection_closed(was_clean_close):
        print("Connection closed, clean: ", was_clean_close)
        is_connected = false
        connection_in_progress = false

func _on_data_received():
        var data = peer.get_packet().get_string_from_utf8()
        var json = JSON.parse_string(data)
        
        if json == null:
                print("Failed to parse JSON from server")
                return
                
        handle_message(json)

func handle_message(message):
        match message.type:
                "game_state":
                        emit_signal("game_state_updated", message.data)
                "player_joined":
                        emit_signal("player_joined", message.data)
                "player_left":
                        emit_signal("player_left", message.data.player_id)
                "chat":
                        emit_signal("chat_message_received", message.data)
                "card_played":
                        emit_signal("card_played", message.data)
                "run_initiated":
                        emit_signal("run_initiated", message.data)
                "territory_updated":
                        emit_signal("territory_updated", message.data)
                "auth_response":
                        if message.data.success:
                                player_id = message.data.player_id
                        else:
                                print("Authentication failed: ", message.data.message)
                _:
                        print("Unknown message type: ", message.type)

func send_message(type, data):
        if not is_connected:
                print("Cannot send message, not connected to server")
                return
        
        var message = {
                "type": type,
                "data": data
        }
        
        var json_str = JSON.stringify(message)
        var err = peer.send_text(json_str)
        if err != OK:
                print("Failed to send message: ", err)

func join_game(game_id):
        send_message("join_game", {"game_id": game_id})

func create_game(game_data):
        send_message("create_game", game_data)

func play_card(card_data):
        send_message("play_card", card_data)

func initiate_run(target_data):
        send_message("initiate_run", target_data)

func send_chat(message):
        send_message("chat", {"message": message})

func claim_territory(territory_data):
        send_message("claim_territory", territory_data)
