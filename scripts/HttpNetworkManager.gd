extends Node

# HttpNetworkManager handles HTTP communication with the server

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
signal request_completed(result, response_code, headers, body)

var base_url = "http://localhost:5000"
var player_id = ""
var auth_token = ""

# HTTP request object
var http_request = null

func _ready():
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func initialize():
	# Nothing to do for HTTP, since it's stateless
	pass

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json == null:
		print("Failed to parse response as JSON")
		return
	
	emit_signal("request_completed", result, response_code, headers, json)

func register_player(player_data):
	var json_data = JSON.stringify(player_data)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(base_url + "/api/register", headers, HTTPClient.METHOD_POST, json_data)
	await request_completed
	
	if response_code == 200:
		player_id = body.id
		emit_signal("auth_response_received", body)
		return body
	else:
		emit_signal("error_received", {"message": "Failed to register"})
		return null

func get_active_games():
	http_request.request(base_url + "/api/games", [], HTTPClient.METHOD_GET)
	var result = await request_completed
	if result[1] == 200:
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to get games"})
		return []

func create_game(game_data):
	var json_data = JSON.stringify(game_data)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(base_url + "/api/games/create", headers, HTTPClient.METHOD_POST, json_data)
	var result = await request_completed
	
	if result[1] == 200:
		emit_signal("game_created", result[3])
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to create game"})
		return null

func join_game(game_id):
	var data = {
		"game_id": game_id,
		"player": {
			"id": player_id,
			"name": "Player " + player_id
		}
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(base_url + "/api/games/join", headers, HTTPClient.METHOD_POST, json_data)
	var result = await request_completed
	
	if result[1] == 200:
		emit_signal("game_joined", result[3])
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to join game"})
		return null

func start_game(game_id):
	var data = {
		"game_id": game_id
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(base_url + "/api/games/start", headers, HTTPClient.METHOD_POST, json_data)
	var result = await request_completed
	
	if result[1] == 200:
		emit_signal("game_state_updated", result[3])
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to start game"})
		return null

func get_game(game_id):
	http_request.request(base_url + "/api/game?id=" + game_id, [], HTTPClient.METHOD_GET)
	var result = await request_completed
	
	if result[1] == 200:
		emit_signal("game_state_updated", result[3])
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to get game"})
		return null

func get_territories():
	http_request.request(base_url + "/api/territories", [], HTTPClient.METHOD_GET)
	var result = await request_completed
	
	if result[1] == 200:
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to get territories"})
		return []

func claim_territory(territory_id):
	var data = {
		"player_id": player_id,
		"territory_id": territory_id
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(base_url + "/api/territories/claim", headers, HTTPClient.METHOD_POST, json_data)
	var result = await request_completed
	
	if result[1] == 200:
		emit_signal("territory_updated", result[3])
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to claim territory"})
		return null

func get_player_territories():
	http_request.request(base_url + "/api/player/territories?player_id=" + player_id, [], HTTPClient.METHOD_GET)
	var result = await request_completed
	
	if result[1] == 200:
		return result[3]
	else:
		emit_signal("error_received", {"message": "Failed to get player territories"})
		return []