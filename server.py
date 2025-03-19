#!/usr/bin/env python3
"""
Simple HTTP server for the CyberRunner card game.
This serves static web files and handles API requests.
"""

import http.server
import socketserver
import json
import os
import random
import time
from urllib.parse import urlparse, parse_qs

# Constants
PORT = 5000
HOST = "0.0.0.0"

# Game state
games = []
next_game_id = 1
players = []
next_player_id = 1
territories = []
next_territory_id = 1

# Initialize some sample territories
def generate_territories():
    global territories, next_territory_id
    
    # Territory types
    types = ["Datacenter", "Corporate", "Industrial", "Residential", "Financial"]
    
    # Create 10 sample territories
    for i in range(10):
        territory = {
            "id": next_territory_id,
            "name": f"Territory {next_territory_id}",
            "type": random.choice(types),
            "strength": random.randint(1, 5),
            "resources": random.randint(1, 3),
            "owner": None,
            "coords": {"x": random.randint(0, 10), "y": random.randint(0, 10)}
        }
        territories.append(territory)
        next_territory_id += 1

# API request handlers
def handle_register(data):
    global players, next_player_id
    
    print(f"Registering player: {data}")
    
    # Validate data
    if "name" not in data or not data["name"].strip():
        return {"error": "Invalid player name"}
    
    if "faction" not in data or not data["faction"].strip():
        return {"error": "Invalid faction"}
    
    # Create player data
    player = {
        "id": str(next_player_id),
        "name": data["name"],
        "faction": data["faction"],
        "level": 1,
        "experience": 0,
        "territories": [],
        "decks": []
    }
    
    players.append(player)
    next_player_id += 1
    
    return player

def handle_get_games():
    return games

def handle_create_game(data):
    global games, next_game_id
    
    print(f"Creating game: {data}")
    
    # Validate data
    if "name" not in data or not data["name"].strip():
        return {"error": "Invalid game name"}
    
    if "max_players" not in data or data["max_players"] < 2 or data["max_players"] > 4:
        return {"error": "Invalid max players"}
    
    if "creator" not in data:
        return {"error": "Creator information missing"}
    
    # Create game data
    game = {
        "id": str(next_game_id),
        "name": data["name"],
        "max_players": data["max_players"],
        "state": "waiting",
        "players": [],
        "started_at": None,
        "turn": 0,
        "active_player": None
    }
    
    # Add creator as first player
    game["players"].append({
        "id": data["creator"]["id"],
        "name": data["creator"]["name"],
        "type": data["creator"]["type"]
    })
    
    games.append(game)
    next_game_id += 1
    
    return game

def handle_join_game(data):
    print(f"Joining game: {data}")
    
    # Validate data
    if "game_id" not in data:
        return {"error": "Game ID missing"}
    
    if "player" not in data:
        return {"error": "Player information missing"}
    
    # Find the game
    game = None
    for g in games:
        if g["id"] == data["game_id"]:
            game = g
            break
    
    if not game:
        return {"error": "Game not found"}
    
    # Check if game is joinable
    if game["state"] != "waiting":
        return {"error": "Game already started"}
    
    if len(game["players"]) >= game["max_players"]:
        return {"error": "Game is full"}
    
    # Check if player is already in the game
    for p in game["players"]:
        if p["id"] == data["player"]["id"]:
            return game  # Player already in the game, return game data
    
    # Add player to the game
    game["players"].append({
        "id": data["player"]["id"],
        "name": data["player"]["name"],
        "type": data["player"]["type"]
    })
    
    return game

def handle_start_game(data):
    print(f"Starting game: {data}")
    
    # Validate data
    if "game_id" not in data:
        return {"error": "Game ID missing"}
    
    # Find the game
    game = None
    for g in games:
        if g["id"] == data["game_id"]:
            game = g
            break
    
    if not game:
        return {"error": "Game not found"}
    
    # Check if game can be started
    if game["state"] != "waiting":
        return {"error": "Game already started"}
    
    if len(game["players"]) < 2:
        return {"error": "Not enough players"}
    
    # Update game state
    game["state"] = "in_progress"
    game["started_at"] = time.time()
    game["turn"] = 1
    game["active_player"] = game["players"][0]["id"]
    
    return game

def handle_get_territories():
    return territories

def handle_claim_territory(data):
    print(f"Claiming territory: {data}")
    
    # Validate data
    if "player_id" not in data:
        return {"error": "Player ID missing"}
    
    if "territory_id" not in data:
        return {"error": "Territory ID missing"}
    
    # Find the territory
    territory = None
    for t in territories:
        if t["id"] == data["territory_id"]:
            territory = t
            break
    
    if not territory:
        return {"error": "Territory not found"}
    
    # Check if territory is already claimed
    if territory["owner"] is not None:
        return {"error": "Territory already claimed"}
    
    # Claim the territory
    territory["owner"] = data["player_id"]
    
    return territory

# Custom HTTP request handler
class CyberRunnerHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        # Parse URL
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        # Check if this is an API request
        if path.startswith('/api/'):
            endpoint = path[5:]  # Remove /api/ prefix
            
            # Handle different API endpoints
            if endpoint == 'games' or endpoint == 'games/list':
                self.send_json_response(handle_get_games())
            elif endpoint == 'territories':
                self.send_json_response(handle_get_territories())
            else:
                self.send_json_response({"error": "Unknown endpoint"}, 404)
        else:
            # Serve static files
            if path == '/':
                path = '/index.html'
            
            # Try to serve from web directory
            try:
                file_path = os.path.join('web', path.lstrip('/'))
                
                # Check if file exists
                if os.path.exists(file_path) and os.path.isfile(file_path):
                    with open(file_path, 'rb') as f:
                        self.send_response(200)
                        
                        # Set content type based on file extension
                        if path.endswith('.html'):
                            self.send_header('Content-Type', 'text/html')
                        elif path.endswith('.css'):
                            self.send_header('Content-Type', 'text/css')
                        elif path.endswith('.js'):
                            self.send_header('Content-Type', 'application/javascript')
                        elif path.endswith('.json'):
                            self.send_header('Content-Type', 'application/json')
                        elif path.endswith('.png'):
                            self.send_header('Content-Type', 'image/png')
                        elif path.endswith('.jpg') or path.endswith('.jpeg'):
                            self.send_header('Content-Type', 'image/jpeg')
                        else:
                            self.send_header('Content-Type', 'text/plain')
                        
                        # Add CORS headers
                        self.send_header('Access-Control-Allow-Origin', '*')
                        
                        # Send the file content
                        content = f.read()
                        self.send_header('Content-Length', str(len(content)))
                        self.end_headers()
                        self.wfile.write(content)
                        return
                
                # File not found
                self.send_error(404, 'File Not Found')
            except Exception as e:
                self.send_error(500, f'Internal Server Error: {str(e)}')
    
    def do_POST(self):
        # Parse URL
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        # Check if this is an API request
        if path.startswith('/api/'):
            endpoint = path[5:]  # Remove /api/ prefix
            
            # Read request body
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Handle different API endpoints
            if endpoint == 'register':
                self.send_json_response(handle_register(data))
            elif endpoint == 'games/create':
                self.send_json_response(handle_create_game(data))
            elif endpoint == 'games/join':
                self.send_json_response(handle_join_game(data))
            elif endpoint == 'games/start':
                self.send_json_response(handle_start_game(data))
            elif endpoint == 'territories/claim':
                self.send_json_response(handle_claim_territory(data))
            else:
                self.send_json_response({"error": "Unknown endpoint"}, 404)
        else:
            self.send_error(404, 'Endpoint Not Found')
    
    def send_json_response(self, data, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        response = json.dumps(data)
        self.wfile.write(response.encode('utf-8'))

def main():
    # Generate initial territories
    generate_territories()
    
    # Create and start the HTTP server
    with socketserver.TCPServer((HOST, PORT), CyberRunnerHandler) as httpd:
        print(f"Server started at http://{HOST}:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    main()