extends Node

# WebSocket server implementation for the CyberRunner game
# Handles both local development and networked multiplayer

signal game_created(game_data)
signal game_joined(game_data)
signal game_updated(game_data)
signal player_connected(player_id)
signal player_disconnected(player_id)
signal chat_message_received(message_data)
signal error_occurred(error_message)

# Game data
var active_games = {}
var players = {}
var territories = {}
var connected_clients = {}

# WebSocket server using proper class name
var server = TCPServer.new()
var server_port = 5000

func _ready():
        # Initialize game data
        initialize_game_data()
        
        # Initialize the TCP server
        var err = server.listen(server_port)
        if err != OK:
                print("ERROR: Failed to start TCP server on port %d: %d" % [server_port, err])
                return
                
        print("TCP server started on port %d" % server_port)

func _process(delta):
        # Process TCP connections
        if server.is_listening():
                # Accept new connections
                if server.is_connection_available():
                        var connection = server.take_connection()
                        print("New connection accepted: ", connection)
                        
                        # Process the connection as needed
                        # For TCP server, you would typically handle this differently than WebSockets

func initialize_game_data():
        # Create some initial games for testing
        create_mock_game("Demo Game", 2)
        create_mock_game("New Players Welcome", 2)
        create_mock_game("Territory Control Game", 4)
        
        # Initialize territory grid
        initialize_territory_grid()

func create_mock_game(name, max_players):
        var game_id = "game_" + str(randi())
        
        active_games[game_id] = {
                "id": game_id,
                "name": name,
                "max_players": max_players,
                "players": [],
                "state": "waiting",
                "created_at": Time.get_unix_time_from_system()
        }

func initialize_territory_grid():
        var grid_width = 10
        var grid_height = 10
        
        for x in range(grid_width):
                for y in range(grid_height):
                        var territory_id = "territory_" + str(x) + "_" + str(y)
                        
                        # Create territory data
                        territories[territory_id] = {
                                "id": territory_id,
                                "position": {"x": x + (y % 2) * 0.5, "y": y * 0.75},
                                "grid_x": x,
                                "grid_y": y,
                                "owner": null,
                                "type": get_random_territory_type(),
                                "strength": randi() % 5 + 1,
                                "resources": randi() % 3 + 1
                        }

func get_random_territory_type():
        var types = ["data_node", "security_hub", "credit_farm", "research_lab", "blacksite"]
        return types[randi() % types.size()]

func register_player(player_data):
        var player_id = "player_" + str(randi())
        
        players[player_id] = {
                "id": player_id,
                "name": player_data.name,
                "experience": 0,
                "level": 1,
                "territories": [],
                "decks": []
        }
        
        # Add a starter deck
        var starter_deck = CardDatabase.get_starter_deck(player_data.faction)
        players[player_id].decks.append({
                "name": "Starter Deck",
                "faction": player_data.faction,
                "cards": starter_deck
        })
        
        return players[player_id]

func get_active_games():
        # Return a list of active games
        var games_list = []
        
        for game_id in active_games:
                var game = active_games[game_id]
                
                if game.state == "waiting" and game.players.size() < game.max_players:
                        games_list.append(game)
        
        return games_list

func create_game(game_data):
        var game_id = "game_" + str(randi())
        
        var new_game = {
                "id": game_id,
                "name": game_data.name,
                "max_players": int(game_data.max_players),
                "players": [game_data.creator],
                "state": "waiting",
                "created_at": Time.get_unix_time_from_system()
        }
        
        active_games[game_id] = new_game
        emit_signal("game_created", new_game)
        
        return new_game

func join_game(game_id, player_data):
        if active_games.has(game_id):
                var game = active_games[game_id]
                
                # Check if game is joinable
                if game.state == "waiting" and game.players.size() < game.max_players:
                        # Check if player is already in the game
                        for player in game.players:
                                if player.id == player_data.id:
                                        emit_signal("error_occurred", "You are already in this game")
                                        return null
                        
                        # Add player to game
                        game.players.append(player_data)
                        
                        # If game is now full, change state
                        if game.players.size() >= game.max_players:
                                game.state = "starting"
                        
                        emit_signal("game_joined", game)
                        emit_signal("game_updated", game)
                        
                        return game
                else:
                        emit_signal("error_occurred", "Game is not joinable")
        else:
                emit_signal("error_occurred", "Game not found")
        
        return null

func get_game(game_id):
        if active_games.has(game_id):
                return active_games[game_id]
        
        emit_signal("error_occurred", "Game not found")
        return null

func start_game(game_id):
        if active_games.has(game_id):
                var game = active_games[game_id]
                
                # Ensure there are at least 2 players
                if game.players.size() >= 2:
                        game.state = "in_progress"
                        emit_signal("game_updated", game)
                        return game
                else:
                        emit_signal("error_occurred", "Not enough players to start game")
        else:
                emit_signal("error_occurred", "Game not found")
        
        return null

func get_territories():
        return territories.values()

func get_territory(territory_id):
        if territories.has(territory_id):
                return territories[territory_id]
        
        emit_signal("error_occurred", "Territory not found")
        return null

func claim_territory(player_id, territory_id):
        if territories.has(territory_id):
                var territory = territories[territory_id]
                
                # Territory is unclaimed or being taken from another player
                territory.owner = player_id
                
                if players.has(player_id):
                        players[player_id].territories.append(territory_id)
                
                return territory
        
        emit_signal("error_occurred", "Territory not found")
        return null

func get_player_territories(player_id):
        var player_territories = []
        
        if players.has(player_id):
                for territory_id in players[player_id].territories:
                        if territories.has(territory_id):
                                player_territories.append(territories[territory_id])
        
        return player_territories

func _on_client_connected(id, protocol):
        print("Client connected: %d" % id)
        # Store client info for tracking
        connected_clients[id] = {
                "id": id,
                "player_id": null,
                "authenticated": false,
                "game_id": null
        }
        emit_signal("player_connected", id)

func _on_client_disconnected(id, was_clean_close):
        print("Client disconnected: %d (clean: %s)" % [id, str(was_clean_close)])
        
        # Handle player leaving games if they were in one
        if connected_clients.has(id) and connected_clients[id].player_id:
                var player_id = connected_clients[id].player_id
                var game_id = connected_clients[id].game_id
                
                if game_id and active_games.has(game_id):
                        # Remove player from the game
                        var game = active_games[game_id]
                        for i in range(game.players.size()):
                                if game.players[i].id == player_id:
                                        game.players.remove_at(i)
                                        break
                        
                        # If game is empty, remove it
                        if game.players.size() == 0:
                                active_games.erase(game_id)
                        else:
                                emit_signal("game_updated", game)
                                
                                # Broadcast to all players in the game
                                for player in game.players:
                                        for client_id in connected_clients:
                                                if connected_clients[client_id].player_id == player.id:
                                                        send_message_to_client(client_id, "player_left", {"player_id": player_id})
        
        # Remove client from tracking
        connected_clients.erase(id)
        emit_signal("player_disconnected", id)

func _on_client_close_request(id, code, reason):
        print("Client %d close request (code: %d, reason: %s)" % [id, code, reason])
        # We'll handle the actual disconnect in _on_client_disconnected

func _on_data_received(id):
        if server.get_peer(id).get_available_packet_count() > 0:
                var packet = server.get_peer(id).get_packet()
                var message_text = packet.get_string_from_utf8()
                
                # Parse the JSON message
                var message = JSON.parse_string(message_text)
                if message == null:
                        print("Error parsing JSON from client %d" % id)
                        return
                
                process_client_message(id, message)

func process_client_message(client_id, message):
        # Process different message types
        if !message.has("type") or !message.has("data"):
                print("Invalid message format from client %d" % client_id)
                return
        
        var type = message.type
        var data = message.data
        
        match type:
                "authenticate":
                        handle_authenticate(client_id, data)
                "register":
                        handle_register(client_id, data)
                "list_games":
                        handle_list_games(client_id)
                "create_game":
                        handle_create_game(client_id, data)
                "join_game":
                        handle_join_game(client_id, data)
                "start_game":
                        handle_start_game(client_id, data)
                "play_card":
                        handle_play_card(client_id, data)
                "initiate_run":
                        handle_initiate_run(client_id, data)
                "claim_territory":
                        handle_claim_territory(client_id, data)
                "chat":
                        handle_chat_message(client_id, data)
                _:
                        print("Unknown message type from client %d: %s" % [client_id, type])

func handle_authenticate(client_id, data):
        # In a real game, you'd validate tokens
        # For now, just accept any authentication
        if data.has("token"):
                var token = data.token
                var player_id = "player_" + str(randi()) # Generate a player ID
                
                # If the player doesn't exist yet, create them
                if !players.has(player_id):
                        players[player_id] = {
                                "id": player_id,
                                "name": "Player " + str(player_id),
                                "experience": 0,
                                "level": 1,
                                "territories": [],
                                "decks": []
                        }
                
                # Mark the client as authenticated
                connected_clients[client_id].authenticated = true
                connected_clients[client_id].player_id = player_id
                
                # Send success response
                send_message_to_client(client_id, "auth_response", {
                        "success": true,
                        "player_id": player_id,
                        "player_data": players[player_id]
                })
                
                print("Client %d authenticated as player %s" % [client_id, player_id])
        else:
                # Authentication failed
                send_message_to_client(client_id, "auth_response", {
                        "success": false,
                        "message": "Invalid authentication"
                })

func handle_register(client_id, data):
        var player = register_player(data)
        
        if player:
                # Associate the client with this player
                connected_clients[client_id].player_id = player.id
                
                # Send response
                send_message_to_client(client_id, "register_response", {
                        "success": true,
                        "player": player
                })
        else:
                send_message_to_client(client_id, "register_response", {
                        "success": false,
                        "message": "Failed to register"
                })

func handle_list_games(client_id):
        var games = get_active_games()
        send_message_to_client(client_id, "games_list", { "games": games })

func handle_create_game(client_id, data):
        # Ensure player is authenticated
        if !is_client_authenticated(client_id):
                send_auth_required_error(client_id)
                return
                
        # Add creator info
        data.creator = {
                "id": connected_clients[client_id].player_id,
                "name": players[connected_clients[client_id].player_id].name
        }
        
        var game = create_game(data)
        
        if game:
                # Associate the client with this game
                connected_clients[client_id].game_id = game.id
                
                # Send response
                send_message_to_client(client_id, "game_created", { "game": game })
                
                # Broadcast to all clients
                broadcast_message("game_added", { "game": game })
        else:
                send_message_to_client(client_id, "error", {
                        "message": "Failed to create game"
                })

func handle_join_game(client_id, data):
        # Ensure player is authenticated
        if !is_client_authenticated(client_id):
                send_auth_required_error(client_id)
                return
                
        var player_id = connected_clients[client_id].player_id
        
        # Check if game exists
        if !data.has("game_id") or !active_games.has(data.game_id):
                send_message_to_client(client_id, "error", {
                        "message": "Game not found"
                })
                return
                
        # Add player to the game
        var player_data = {
                "id": player_id,
                "name": players[player_id].name
        }
        
        var game = join_game(data.game_id, player_data)
        
        if game:
                # Associate the client with this game
                connected_clients[client_id].game_id = game.id
                
                # Send response
                send_message_to_client(client_id, "game_joined", { "game": game })
                
                # Notify all clients in the game
                broadcast_game_update(game)
        else:
                send_message_to_client(client_id, "error", {
                        "message": "Failed to join game"
                })

func handle_start_game(client_id, data):
        # Ensure player is authenticated
        if !is_client_authenticated(client_id):
                send_auth_required_error(client_id)
                return
                
        # Check if game exists and client is in it
        if !data.has("game_id") or !active_games.has(data.game_id):
                send_message_to_client(client_id, "error", {
                        "message": "Game not found"
                })
                return
                
        var game_id = data.game_id
        if connected_clients[client_id].game_id != game_id:
                send_message_to_client(client_id, "error", {
                        "message": "You are not in this game"
                })
                return
                
        var game = start_game(game_id)
        
        if game:
                # Send response
                send_message_to_client(client_id, "game_started", { "game": game })
                
                # Notify all clients in the game
                broadcast_game_update(game)
        else:
                send_message_to_client(client_id, "error", {
                        "message": "Failed to start game"
                })

func handle_play_card(client_id, data):
        # Implement card playing logic
        pass

func handle_initiate_run(client_id, data):
        # Implement run initiation logic
        pass

func handle_claim_territory(client_id, data):
        # Ensure player is authenticated
        if !is_client_authenticated(client_id):
                send_auth_required_error(client_id)
                return
                
        var player_id = connected_clients[client_id].player_id
        
        if !data.has("territory_id") or !territories.has(data.territory_id):
                send_message_to_client(client_id, "error", {
                        "message": "Territory not found"
                })
                return
                
        var territory = claim_territory(player_id, data.territory_id)
        
        if territory:
                # Send response
                send_message_to_client(client_id, "territory_claimed", { "territory": territory })
                
                # Broadcast territory update to all clients
                broadcast_message("territory_updated", { "territory": territory })
        else:
                send_message_to_client(client_id, "error", {
                        "message": "Failed to claim territory"
                })

func handle_chat_message(client_id, data):
        # Ensure player is authenticated
        if !is_client_authenticated(client_id):
                send_auth_required_error(client_id)
                return
                
        var player_id = connected_clients[client_id].player_id
        
        if !data.has("message") or data.message.strip_edges() == "":
                return
                
        var message_data = {
                "player_id": player_id,
                "player_name": players[player_id].name,
                "message": data.message,
                "timestamp": Time.get_unix_time_from_system()
        }
        
        # If in a game, send to all players in the game
        var game_id = connected_clients[client_id].game_id
        if game_id and active_games.has(game_id):
                var game = active_games[game_id]
                
                for player in game.players:
                        for peer_id in connected_clients:
                                if connected_clients[peer_id].player_id == player.id:
                                        send_message_to_client(peer_id, "chat", message_data)
        else:
                # Global chat, send to all connected clients
                broadcast_message("chat", message_data)
        
        emit_signal("chat_message_received", message_data)

func send_message_to_client(client_id, type, data):
        var message = {
                "type": type,
                "data": data
        }
        
        var json_str = JSON.stringify(message)
        server.get_peer(client_id).send_text(json_str)

func broadcast_message(type, data):
        var message = {
                "type": type,
                "data": data
        }
        
        var json_str = JSON.stringify(message)
        
        for client_id in connected_clients:
                if connected_clients[client_id].authenticated:
                        server.get_peer(client_id).send_text(json_str)

func broadcast_game_update(game):
        for player in game.players:
                for client_id in connected_clients:
                        if connected_clients[client_id].player_id == player.id:
                                send_message_to_client(client_id, "game_updated", { "game": game })

func is_client_authenticated(client_id):
        return connected_clients.has(client_id) and connected_clients[client_id].authenticated

func send_auth_required_error(client_id):
        send_message_to_client(client_id, "error", {
                "message": "Authentication required"
        })

func handle_request(route, data):
        # Legacy function for local development
        # This is now superseded by the WebSocket message handlers
        match route:
                "register":
                        return register_player(data)
                "games/list":
                        return get_active_games()
                "games/create":
                        return create_game(data)
                "games/join":
                        return join_game(data.game_id, data.player)
                "games/get":
                        return get_game(data.game_id)
                "games/start":
                        return start_game(data.game_id)
                "territories/list":
                        return get_territories()
                "territories/get":
                        return get_territory(data.territory_id)
                "territories/claim":
                        return claim_territory(data.player_id, data.territory_id)
                "territories/player":
                        return get_player_territories(data.player_id)
                _:
                        emit_signal("error_occurred", "Unknown route: " + route)
                        return null
