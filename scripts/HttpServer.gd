extends Node

# HTTP server implementation for CyberRunner card game
# This script handles HTTP requests/responses to facilitate
# multiplayer game functionality over the web using Godot's built-in
# HTTP server classes

const PORT = 5000

var http_server
var games = []
var next_game_id = 1
var players = []
var next_player_id = 1
var territories = []
var next_territory_id = 1

signal request_processed(endpoint, data, response)

func _ready():
        print("Starting HTTP Server on port ", PORT)
        
        # Initialize HTTP server using a TCP server
        http_server = TCPServer.new()
        var err = http_server.listen(PORT, "0.0.0.0")
        if err != OK:
                push_error("Failed to start HTTP server: " + str(err))
                return
        
        print("HTTP Server started successfully")
        
        # Create some initial territories for testing
        _generate_initial_territories()

func _generate_initial_territories():
        # Create some test territories
        for i in range(10):
                var territory = {
                        "id": next_territory_id,
                        "name": "Territory " + str(next_territory_id),
                        "type": _random_territory_type(),
                        "strength": randi_range(1, 5),  # 1-5 strength
                        "resources": randi_range(1, 3),  # 1-3 resources
                        "owner": null,  # No initial owner
                        "coords": Vector2(randi_range(0, 10), randi_range(0, 10))  # Random coordinates
                }
                territories.append(territory)
                next_territory_id += 1

func _random_territory_type():
        var types = ["Datacenter", "Corporate", "Industrial", "Residential", "Financial"]
        return types[randi() % types.size()]

func _process(_delta):
        # Check for new connections
        if http_server and http_server.is_connection_available():
                var peer = http_server.take_connection()
                if peer:
                        print("New connection from: ", peer.get_connected_host())
                        # Handle the connection in a separate thread or process
                        _handle_connection(peer)

func _handle_connection(peer):
        # Buffer for receiving data
        var request_data = ""
        
        # Read the request
        while peer.get_available_bytes() > 0 or request_data.length() == 0:
                var chunk = peer.get_utf8_string(peer.get_available_bytes())
                if chunk.length() == 0:
                        # Wait a bit for more data
                        OS.delay_msec(100)
                        continue
                
                request_data += chunk
                
                # Check if we have a complete HTTP request
                if request_data.find("\r\n\r\n") != -1:
                        break
        
        # Parse the HTTP request
        var request = _parse_http_request(request_data)
        
        # Generate a response
        var response_data = _generate_http_response(request)
        
        # Send the response
        peer.put_data(response_data.to_utf8_buffer())
        
        # Close the connection (HTTP 1.0 style)
        peer.disconnect_from_host()

func _parse_http_request(request_data):
        var request = {
                "method": "",
                "url": "",
                "headers": {},
                "body": ""
        }
        
        # Split headers and body
        var parts = request_data.split("\r\n\r\n", true, 1)
        var header_section = parts[0]
        if parts.size() > 1:
                request.body = parts[1]
        
        # Parse the request line and headers
        var lines = header_section.split("\r\n")
        if lines.size() > 0:
                var request_line_parts = lines[0].split(" ")
                if request_line_parts.size() >= 2:
                        request.method = request_line_parts[0]
                        request.url = request_line_parts[1]
                
                # Parse headers
                for i in range(1, lines.size()):
                        var header_line = lines[i]
                        var header_parts = header_line.split(":", true, 1)
                        if header_parts.size() == 2:
                                var key = header_parts[0].strip_edges()
                                var value = header_parts[1].strip_edges()
                                request.headers[key] = value
        
        return request

func _generate_http_response(request):
        var response = ""
        var status_code = 200
        var status_text = "OK"
        var headers = {
                "Content-Type": "text/plain",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
        }
        var body = ""
        
        # Handle OPTIONS request for CORS
        if request.method == "OPTIONS":
                body = ""
        else:
                # Parse URL to determine endpoint
                var url = request.url.split("?")[0]
                var url_parts = url.split("/")
                url_parts = url_parts.filter(func(part): return part != "")
                
                # Check if this is an API request
                if url_parts.size() > 0 and url_parts[0] == "api":
                        # Remove "api" from url parts
                        url_parts.remove_at(0)
                        
                        # Get the endpoint
                        var endpoint = url_parts.join("/")
                        
                        # Parse request data if it's a POST
                        var request_data = {}
                        if request.method == "POST" and request.body.length() > 0:
                                var json = JSON.new()
                                var error = json.parse(request.body)
                                if error == OK:
                                        request_data = json.data
                                else:
                                        push_error("JSON Parse Error: " + json.get_error_message())
                        
                        # Process the request
                        var result = handle_request(endpoint, request_data)
                        
                        # Set response headers and body
                        headers["Content-Type"] = "application/json"
                        body = JSON.stringify(result)
                        
                        # Emit signal for debugging/monitoring
                        emit_signal("request_processed", endpoint, request_data, result)
                else:
                        # Serve static files from web directory
                        var file_path = ""
                        
                        if url_parts.size() == 0 or (url_parts.size() == 1 and url_parts[0] == ""):
                                # Request for root, serve index.html
                                file_path = "web/index.html"
                        else:
                                # Try to serve the requested file
                                file_path = "web/" + url.substr(1)
                        
                        # Check if file exists
                        if FileAccess.file_exists(file_path):
                                # Determine content type
                                if file_path.ends_with(".html"):
                                        headers["Content-Type"] = "text/html"
                                elif file_path.ends_with(".css"):
                                        headers["Content-Type"] = "text/css"
                                elif file_path.ends_with(".js"):
                                        headers["Content-Type"] = "application/javascript"
                                elif file_path.ends_with(".json"):
                                        headers["Content-Type"] = "application/json"
                                elif file_path.ends_with(".png"):
                                        headers["Content-Type"] = "image/png"
                                elif file_path.ends_with(".jpg") or file_path.ends_with(".jpeg"):
                                        headers["Content-Type"] = "image/jpeg"
                                
                                # Read and serve the file
                                var file = FileAccess.open(file_path, FileAccess.READ)
                                body = file.get_as_text()
                                file.close()
                        else:
                                # File not found, serve 404
                                status_code = 404
                                status_text = "Not Found"
                                body = "404 Not Found"
        
        # Build the response string
        response = "HTTP/1.1 " + str(status_code) + " " + status_text + "\r\n"
        
        # Add headers
        for key in headers:
                response += key + ": " + headers[key] + "\r\n"
        
        # Add body
        response += "Content-Length: " + str(body.length()) + "\r\n"
        response += "\r\n"
        response += body
        
        return response

# Main function to handle API requests
# Parameters:
# - endpoint: String - the API endpoint to call (e.g. "register", "games/list")
# - data: Dictionary - the data to send with the request
# Returns: Variant - usually a Dictionary with the response data
func handle_request(endpoint, data):
        print("API Request: " + endpoint)
        print("Data: " + str(data))
        
        match endpoint:
                "register":
                        return _handle_register(data)
                "games":
                        return _handle_get_games()
                "games/list":
                        return _handle_get_games()
                "games/create":
                        return _handle_create_game(data)
                "games/join":
                        return _handle_join_game(data)
                "games/start":
                        return _handle_start_game(data)
                "territories":
                        return _handle_get_territories()
                "territories/claim":
                        return _handle_claim_territory(data)
                _:
                        push_error("Unknown endpoint: " + endpoint)
                        return {"error": "Unknown endpoint"}

# Handler for player registration
func _handle_register(data):
        print("Registering player: " + str(data))
        
        # Validate data
        if not data.has("name") or data.name.strip_edges() == "":
                return {"error": "Invalid player name"}
        
        if not data.has("faction") or data.faction.strip_edges() == "":
                return {"error": "Invalid faction"}
        
        # Create player data
        var player = {
                "id": str(next_player_id),
                "name": data.name,
                "faction": data.faction,
                "level": 1,
                "experience": 0,
                "territories": [],
                "decks": []
        }
        
        players.append(player)
        next_player_id += 1
        
        return player

# Handler for getting games list
func _handle_get_games():
        return games

# Handler for creating a new game
func _handle_create_game(data):
        print("Creating game: " + str(data))
        
        # Validate data
        if not data.has("name") or data.name.strip_edges() == "":
                return {"error": "Invalid game name"}
        
        if not data.has("max_players") or data.max_players < 2 or data.max_players > 4:
                return {"error": "Invalid max players"}
        
        if not data.has("creator"):
                return {"error": "Creator information missing"}
        
        # Create game data
        var game = {
                "id": str(next_game_id),
                "name": data.name,
                "max_players": data.max_players,
                "state": "waiting",
                "players": [],
                "started_at": null,
                "turn": 0,
                "active_player": null
        }
        
        # Add creator as first player
        game.players.append({
                "id": data.creator.id,
                "name": data.creator.name,
                "type": data.creator.type
        })
        
        games.append(game)
        next_game_id += 1
        
        return game

# Handler for joining a game
func _handle_join_game(data):
        print("Joining game: " + str(data))
        
        # Validate data
        if not data.has("game_id"):
                return {"error": "Game ID missing"}
        
        if not data.has("player"):
                return {"error": "Player information missing"}
        
        # Find the game
        var game = null
        for g in games:
                if g.id == data.game_id:
                        game = g
                        break
        
        if not game:
                return {"error": "Game not found"}
        
        # Check if game is joinable
        if game.state != "waiting":
                return {"error": "Game already started"}
        
        if game.players.size() >= game.max_players:
                return {"error": "Game is full"}
        
        # Check if player is already in the game
        for p in game.players:
                if p.id == data.player.id:
                        return game  # Player already in the game, return game data
        
        # Add player to the game
        game.players.append({
                "id": data.player.id,
                "name": data.player.name,
                "type": data.player.type
        })
        
        return game

# Handler for starting a game
func _handle_start_game(data):
        print("Starting game: " + str(data))
        
        # Validate data
        if not data.has("game_id"):
                return {"error": "Game ID missing"}
        
        # Find the game
        var game = null
        for g in games:
                if g.id == data.game_id:
                        game = g
                        break
        
        if not game:
                return {"error": "Game not found"}
        
        # Check if game can be started
        if game.state != "waiting":
                return {"error": "Game already started"}
        
        if game.players.size() < 2:
                return {"error": "Not enough players"}
        
        # Update game state
        game.state = "in_progress"
        game.started_at = Time.get_unix_time_from_system()
        game.turn = 1
        game.active_player = game.players[0].id
        
        return game

# Handler for getting territories
func _handle_get_territories():
        return territories

# Handler for claiming a territory
func _handle_claim_territory(data):
        print("Claiming territory: " + str(data))
        
        # Validate data
        if not data.has("player_id"):
                return {"error": "Player ID missing"}
        
        if not data.has("territory_id"):
                return {"error": "Territory ID missing"}
        
        # Find the territory
        var territory = null
        for t in territories:
                if t.id == data.territory_id:
                        territory = t
                        break
        
        if not territory:
                return {"error": "Territory not found"}
        
        # Check if territory is already claimed
        if territory.owner != null:
                return {"error": "Territory already claimed"}
        
        # Claim the territory
        territory.owner = data.player_id
        
        return territory