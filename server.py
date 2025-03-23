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
import datetime
import psycopg2
import psycopg2.extras
from urllib.parse import urlparse

# Custom JSON encoder to handle datetime objects
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime.datetime):
            return o.isoformat()
        return super().default(o)

# Constants
PORT = 5000
HOST = "0.0.0.0"

# PostgreSQL connection
def get_db_connection():
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    conn.autocommit = True
    return conn

# DB utility functions
def get_player_by_id(player_id):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute("SELECT * FROM players WHERE id = %s", (player_id,))
            return cur.fetchone()

def get_game_by_id(game_id):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute("SELECT * FROM games WHERE id = %s", (game_id,))
            game = cur.fetchone()
            
            if game:
                # Get players in this game
                cur.execute("""
                    SELECT p.* FROM players p
                    JOIN game_players gp ON p.id = gp.player_id
                    WHERE gp.game_id = %s
                """, (game_id,))
                players = cur.fetchall()
                
                # Convert to dictionary with players list
                game_dict = dict(game)
                game_dict['players'] = [dict(p) for p in players]
                return game_dict
            
            return None

def get_territory_by_id(territory_id):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute("SELECT * FROM territories WHERE id = %s", (territory_id,))
            territory = cur.fetchone()
            if territory:
                return dict(territory)
            return None

def get_all_games():
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute("SELECT * FROM games ORDER BY created_at DESC")
            games = cur.fetchall()
            
            # For each game, get its players
            result = []
            for game in games:
                game_dict = dict(game)
                
                cur.execute("""
                    SELECT p.* FROM players p
                    JOIN game_players gp ON p.id = gp.player_id
                    WHERE gp.game_id = %s
                """, (game['id'],))
                players = cur.fetchall()
                
                game_dict['players'] = [dict(p) for p in players]
                result.append(game_dict)
                
            return result

def get_all_territories():
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute("SELECT * FROM territories ORDER BY id")
            territories = cur.fetchall()
            return [dict(t) for t in territories]

# Initialize sample territories
def generate_territories():
    # Territory types
    types = ["Datacenter", "Corporate", "Industrial", "Residential", "Financial"]
    
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Check if territories already exist
            cur.execute("SELECT COUNT(*) FROM territories")
            count = cur.fetchone()[0]
            
            if count > 0:
                print(f"Territories already exist in database ({count} territories)")
                return
                
            # Create 10 sample territories
            print("Generating sample territories...")
            for i in range(10):
                name = f"Territory {i+1}"
                territory_type = random.choice(types)
                strength = random.randint(1, 5)
                resources = random.randint(1, 3)
                x_coord = random.randint(0, 10)
                y_coord = random.randint(0, 10)
                
                cur.execute("""
                    INSERT INTO territories 
                    (name, type, strength, resources, x_coord, y_coord) 
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (name, territory_type, strength, resources, x_coord, y_coord))
                
            print("Sample territories created successfully")

# API request handlers
def handle_register(data):
    print(f"Registering player: {data}")
    
    # Validate data
    if "name" not in data or not data["name"].strip():
        return {"error": "Invalid player name"}
    
    if "faction" not in data or not data["faction"].strip():
        return {"error": "Invalid faction"}
    
    try:
        # Insert player into database
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                cur.execute("""
                    INSERT INTO players (name, faction, level, experience) 
                    VALUES (%s, %s, %s, %s) 
                    RETURNING *
                """, (data["name"], data["faction"], 1, 0))
                
                player = dict(cur.fetchone())
                # Add empty collections that would be loaded on demand
                player['territories'] = []
                player['decks'] = []
                
                return player
    except Exception as e:
        print(f"Error registering player: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

def handle_get_games():
    try:
        return get_all_games()
    except Exception as e:
        print(f"Error getting games: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

def handle_create_game(data):
    print(f"Creating game: {data}")
    
    # Validate data
    if "name" not in data or not data["name"].strip():
        return {"error": "Invalid game name"}
    
    if "max_players" not in data or data["max_players"] < 2 or data["max_players"] > 4:
        return {"error": "Invalid max players"}
    
    if "creator" not in data:
        return {"error": "Creator information missing"}
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                # Insert the game
                cur.execute("""
                    INSERT INTO games (name, max_players, state, turn)
                    VALUES (%s, %s, %s, %s)
                    RETURNING *
                """, (data["name"], data["max_players"], "waiting", 0))
                
                game = dict(cur.fetchone())
                
                # Add creator as first player in the junction table
                cur.execute("""
                    INSERT INTO game_players (game_id, player_id)
                    VALUES (%s, %s)
                """, (game["id"], data["creator"]["id"]))
                
                # Get player info to add to game data
                cur.execute("SELECT * FROM players WHERE id = %s", (data["creator"]["id"],))
                player = dict(cur.fetchone())
                
                # Add players list for return
                game["players"] = [player]
                
                return game
    except Exception as e:
        print(f"Error creating game: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

def handle_join_game(data):
    print(f"Joining game: {data}")
    
    # Validate data
    if "game_id" not in data:
        return {"error": "Game ID missing"}
    
    if "player" not in data:
        return {"error": "Player information missing"}
    
    try:
        # Get the game
        game = get_game_by_id(data["game_id"])
        
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
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO game_players (game_id, player_id)
                    VALUES (%s, %s)
                """, (game["id"], data["player"]["id"]))
                
                # Return updated game data
                return get_game_by_id(data["game_id"])
                
    except Exception as e:
        print(f"Error joining game: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

def handle_start_game(data):
    print(f"Starting game: {data}")
    
    # Validate data
    if "game_id" not in data:
        return {"error": "Game ID missing"}
    
    try:
        # Get the game
        game = get_game_by_id(data["game_id"])
        
        if not game:
            return {"error": "Game not found"}
        
        # Check if game can be started
        if game["state"] != "waiting":
            return {"error": "Game already started"}
        
        if len(game["players"]) < 2:
            return {"error": "Not enough players"}
        
        # Update game state
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                started_at = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
                active_player = game["players"][0]["id"]
                
                cur.execute("""
                    UPDATE games 
                    SET state = %s, started_at = %s, turn = %s, active_player = %s
                    WHERE id = %s
                """, ("in_progress", started_at, 1, active_player, game["id"]))
                
                # Return updated game data
                return get_game_by_id(data["game_id"])
                
    except Exception as e:
        print(f"Error starting game: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

def handle_get_territories():
    try:
        return get_all_territories()
    except Exception as e:
        print(f"Error getting territories: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

def handle_claim_territory(data):
    print(f"Claiming territory: {data}")
    
    # Validate data
    if "player_id" not in data:
        return {"error": "Player ID missing"}
    
    if "territory_id" not in data:
        return {"error": "Territory ID missing"}
    
    try:
        # Get the territory
        territory = get_territory_by_id(data["territory_id"])
        
        if not territory:
            return {"error": "Territory not found"}
        
        # Check if territory is already claimed
        if territory["owner_id"] is not None:
            return {"error": "Territory already claimed"}
        
        # Claim the territory
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Update territory owner
                cur.execute("""
                    UPDATE territories 
                    SET owner_id = %s
                    WHERE id = %s
                """, (data["player_id"], data["territory_id"]))
                
                # Add to player_territories junction table
                cur.execute("""
                    INSERT INTO player_territories (player_id, territory_id)
                    VALUES (%s, %s)
                """, (data["player_id"], data["territory_id"]))
                
                # Return updated territory data
                return get_territory_by_id(data["territory_id"])
                
    except Exception as e:
        print(f"Error claiming territory: {str(e)}")
        return {"error": f"Database error: {str(e)}"}

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
        
        # Use custom encoder to handle datetime objects
        response = json.dumps(data, cls=CustomJSONEncoder)
        self.wfile.write(response.encode('utf-8'))

def main():
    # Initialize the database with territories if needed
    generate_territories()
    
    try:
        # Create and start the HTTP server
        httpd = socketserver.TCPServer((HOST, PORT), CyberRunnerHandler)
        print(f"Server successfully bound to port {PORT}")
        print(f"Server started at http://{HOST}:{PORT}")
        httpd.serve_forever()
    except Exception as e:
        print(f"Error starting server: {str(e)}")
        import sys
        sys.exit(1)

if __name__ == "__main__":
    main()