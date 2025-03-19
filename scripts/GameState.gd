extends Node

# GameState stores and manages the current state of the game
# This includes card states, player resources, servers, runs, etc.

signal game_started
signal turn_changed(player_id)
signal credits_changed(player_id, new_amount)
signal card_played(player_id, card_data)
signal card_drawn(player_id, card_data)
signal run_started(runner_id, server_id)
signal run_ended(result)
signal game_over(result_data)

enum PlayerType { CORP, RUNNER }
enum GamePhase { 
        SETUP, 
        CORP_TURN, 
        RUNNER_TURN, 
        RUN, 
        GAME_OVER 
}

# Game state variables
var game_id = ""
var current_player_id = ""
var current_phase = GamePhase.SETUP
var players = {}
var current_turn = 0
var location_data = null

# Corp-specific state
var installed_ice = {}
var servers = {}
var agendas_scored = {}

# Runner-specific state
var installed_programs = {}
var installed_hardware = {}
var installed_resources = {}
var tags = 0
var brain_damage = 0

func initialize_game(game_data):
        # Reset game state
        reset_state()
        
        # Set up new game with provided data
        game_id = game_data.game_id
        
        # Initialize players
        for player in game_data.players:
                players[player.id] = {
                        "id": player.id,
                        "name": player.name,
                        "type": player.type,
                        "deck": player.deck,
                        "hand": [],
                        "discard": [],
                        "credits": 5 if player.type == PlayerType.CORP else 5, # Starting credits
                        "clicks": 0,
                        "scored": []
                }
        
        # Set initial game phase
        current_phase = GamePhase.SETUP
        
        # Begin setup phase (draw starting hands, etc.)
        start_setup_phase()
        
        # Emit game started signal
        emit_signal("game_started")

func reset_state():
        game_id = ""
        current_player_id = ""
        current_phase = GamePhase.SETUP
        players = {}
        current_turn = 0
        location_data = null
        
        installed_ice = {}
        servers = {}
        agendas_scored = {}
        
        installed_programs = {}
        installed_hardware = {}
        installed_resources = {}
        tags = 0
        brain_damage = 0

func start_setup_phase():
        # Draw starting hands for both players
        for player_id in players:
                var player = players[player_id]
                
                # Shuffle player deck
                player.deck = shuffle_array(player.deck)
                
                # Draw starting hand (5 cards for corp, 5 for runner)
                var draw_count = 5
                for i in range(draw_count):
                        if player.deck.size() > 0:
                                var card = player.deck.pop_front()
                                player.hand.append(card)
                                emit_signal("card_drawn", player_id, card)
        
        # After setup, start with Corp turn
        start_corp_turn()

func start_corp_turn():
        current_phase = GamePhase.CORP_TURN
        
        # Find the corp player
        for player_id in players:
                if players[player_id].type == PlayerType.CORP:
                        current_player_id = player_id
                        break
        
        # Reset clicks and draw a card
        var corp = players[current_player_id]
        corp.clicks = 3
        
        # Corp draws a card at the start of their turn (except on first turn)
        if current_turn > 0:
                draw_card(current_player_id)
        
        current_turn += 1
        emit_signal("turn_changed", current_player_id)

func start_runner_turn():
        current_phase = GamePhase.RUNNER_TURN
        
        # Find the runner player
        for player_id in players:
                if players[player_id].type == PlayerType.RUNNER:
                        current_player_id = player_id
                        break
        
        # Reset clicks and add credits
        var runner = players[current_player_id]
        runner.clicks = 4
        
        # Runner doesn't automatically draw a card
        emit_signal("turn_changed", current_player_id)

func draw_card(player_id):
        var player = players[player_id]
        
        if player.deck.size() > 0:
                var card = player.deck.pop_front()
                player.hand.append(card)
                emit_signal("card_drawn", player_id, card)
                return card
        else:
                # If Corp is out of cards, runner wins
                # If Runner is out of cards, they lose if they try to draw
                if player.type == PlayerType.CORP:
                        end_game(get_runner_id())
                else:
                        end_game(get_corp_id())
                return null

func discard_card(player_id, card_index):
        var player = players[player_id]
        
        if card_index >= 0 and card_index < player.hand.size():
                var card = player.hand[card_index]
                player.hand.remove_at(card_index)
                player.discard.append(card)
                return true
        
        return false

func play_card(player_id, card_index, target_data=null):
        var player = players[player_id]
        
        if card_index >= 0 and card_index < player.hand.size():
                var card = player.hand[card_index]
                
                # Check if player can afford the card
                if player.credits >= card.cost:
                        # Reduce the player's credits
                        modify_credits(player_id, -card.cost)
                        
                        # Remove the card from hand
                        player.hand.remove_at(card_index)
                        
                        # Process the card based on type
                        process_card_play(player_id, card, target_data)
                        
                        # Emit signal that card was played
                        emit_signal("card_played", player_id, card)
                        
                        return true
        
        return false

func process_card_play(player_id, card, target_data):
        # Handle card based on player type and card type
        var player = players[player_id]
        
        if player.type == PlayerType.CORP:
                match card.type:
                        "ice":
                                # Install ice on a server
                                if target_data and target_data.has("server_id"):
                                        installed_ice[card.id] = {
                                                "card": card,
                                                "server_id": target_data.server_id,
                                                "position": target_data.position,
                                                "rezzed": false
                                        }
                        "asset", "upgrade":
                                # Install in a server
                                if target_data and target_data.has("server_id"):
                                        if not servers.has(target_data.server_id):
                                                servers[target_data.server_id] = {
                                                        "installed": []
                                                }
                                        
                                        servers[target_data.server_id].installed.append({
                                                "card": card,
                                                "rezzed": false
                                        })
                        "agenda":
                                # Install in a server
                                if target_data and target_data.has("server_id"):
                                        if not servers.has(target_data.server_id):
                                                servers[target_data.server_id] = {
                                                        "installed": []
                                                }
                                        
                                        servers[target_data.server_id].installed.append({
                                                "card": card,
                                                "advancement_tokens": 0
                                        })
                        "operation":
                                # Operations take effect immediately
                                apply_card_effect(player_id, card, target_data)
        
        elif player.type == PlayerType.RUNNER:
                match card.type:
                        "program":
                                # Install program in rig
                                installed_programs[card.id] = {
                                        "card": card
                                }
                        "hardware":
                                # Install hardware
                                installed_hardware[card.id] = {
                                        "card": card
                                }
                        "resource":
                                # Install resource
                                installed_resources[card.id] = {
                                        "card": card
                                }
                        "event":
                                # Events take effect immediately
                                apply_card_effect(player_id, card, target_data)

func apply_card_effect(player_id, card, target_data):
        # Execute the card's specific effect
        # This would involve specific game mechanics based on the card
        # For now, we'll just handle some basic effects
        
        if card.has("effect"):
                match card.effect.type:
                        "draw":
                                # Draw cards
                                for i in range(card.effect.amount):
                                        draw_card(player_id)
                        "gain_credits":
                                # Gain credits
                                modify_credits(player_id, card.effect.amount)
                        "do_damage":
                                # Deal damage
                                var target_player_id = target_data.player_id if target_data else get_opponent_id(player_id)
                                deal_damage(target_player_id, card.effect.amount, card.effect.damage_type)

func modify_credits(player_id, amount):
        if players.has(player_id):
                players[player_id].credits += amount
                emit_signal("credits_changed", player_id, players[player_id].credits)

func spend_click(player_id):
        if players.has(player_id) and players[player_id].clicks > 0:
                players[player_id].clicks -= 1
                
                # If player has no more clicks, end their turn
                if players[player_id].clicks <= 0:
                        end_turn()
                
                return true
                
        return false

func end_turn():
        if current_phase == GamePhase.CORP_TURN:
                start_runner_turn()
        elif current_phase == GamePhase.RUNNER_TURN:
                start_corp_turn()

func start_run(server_id):
        current_phase = GamePhase.RUN
        
        # Store the current server being run on
        var run_data = {
                "server_id": server_id,
                "runner_id": get_runner_id(),
                "current_ice_index": 0,
                "successful": false
        }
        
        emit_signal("run_started", run_data.runner_id, server_id)
        
        # Begin run sequence
        process_run(run_data)

func process_run(run_data):
        # Get all ice protecting the server
        var server_ice = []
        
        for ice_id in installed_ice:
                var ice = installed_ice[ice_id]
                if ice.server_id == run_data.server_id:
                        server_ice.append(ice)
        
        # Sort ice by position (outermost first)
        server_ice.sort_custom(func(a, b): return a.position < b.position)
        
        # Process ice in order
        if run_data.current_ice_index < server_ice.size():
                var current_ice = server_ice[run_data.current_ice_index]
                
                # If ice is not rezzed, corp gets a chance to rez it
                if not current_ice.rezzed:
                        # This would trigger a decision for the corp player
                        # For now, automatically rez if corp can afford it
                        var corp_id = get_corp_id()
                        if players[corp_id].credits >= current_ice.card.rez_cost:
                                modify_credits(corp_id, -current_ice.card.rez_cost)
                                current_ice.rezzed = true
                
                if current_ice.rezzed:
                        # Runner encounters rezzed ice
                        # This would involve several decisions and card effects
                        # For simplicity, just check if runner can break the ice
                        var can_break = check_if_runner_can_break(current_ice.card)
                        
                        if can_break:
                                # Runner broke all subroutines, continue to next ice
                                run_data.current_ice_index += 1
                                process_run(run_data)
                        else:
                                # Runner couldn't break ice, run ends unsuccessfully
                                end_run(run_data, false)
                else:
                        # Ice not rezzed, proceed to next ice
                        run_data.current_ice_index += 1
                        process_run(run_data)
        else:
                # No more ice, runner reaches the server
                access_server(run_data)

func check_if_runner_can_break(ice_card):
        # In a real implementation, this would check installed breakers,
        # their strength vs ice strength, and if they can break all subroutines
        # For simplicity, we'll just return a random result
        return randf() > 0.5

func access_server(run_data):
        # Runner accesses cards in the server
        var server_id = run_data.server_id
        
        if servers.has(server_id):
                var server = servers[server_id]
                
                # Access each card in the server (in a real game, this would
                # involve decisions on which cards to access and in what order)
                for installed in server.installed:
                        if installed.card.type == "agenda":
                                # Steal agenda
                                var runner_id = get_runner_id()
                                players[runner_id].scored.append(installed.card)
                                
                                # Remove agenda from server
                                server.installed.erase(installed)
                                
                                # Check for win condition (7 agenda points)
                                check_win_condition()
                        elif installed.card.type == "asset" or installed.card.type == "upgrade":
                                # If rezzed, trigger on-access effect
                                # If unrezzed, runner can trash for trash cost
                                pass
        
        # End run successfully
        end_run(run_data, true)

func end_run(run_data, successful):
        run_data.successful = successful
        current_phase = GamePhase.RUNNER_TURN
        
        emit_signal("run_ended", run_data)
        
        # After a run, return to the runner's turn
        if successful:
                # If successful, might give the runner a reward or trigger effects
                pass

func deal_damage(player_id, amount, damage_type):
        var player = players[player_id]
        
        if player.type == PlayerType.RUNNER:
                if damage_type == "brain":
                        brain_damage += amount
                        # For brain damage, permanently reduce hand size
                        # and check if the runner has flatlined
                        if brain_damage >= 3:
                                end_game(get_corp_id())
                elif damage_type == "net" or damage_type == "meat":
                        # For net/meat damage, discard random cards
                        # If the runner has to discard more cards than in hand, they flatline
                        if amount >= player.hand.size():
                                end_game(get_corp_id())
                        else:
                                # Discard random cards
                                for i in range(amount):
                                        if player.hand.size() > 0:
                                                var random_index = randi() % player.hand.size()
                                                discard_card(player_id, random_index)

func check_win_condition():
        # Check if either player has met their win condition
        
        # Corp wins if they score 7 agenda points
        var corp_id = get_corp_id()
        var corp_points = calculate_agenda_points(corp_id)
        if corp_points >= 7:
                end_game(corp_id)
        
        # Runner wins if they steal 7 agenda points
        var runner_id = get_runner_id()
        var runner_points = calculate_agenda_points(runner_id)
        if runner_points >= 7:
                end_game(runner_id)

func calculate_agenda_points(player_id):
        var player = players[player_id]
        var total_points = 0
        
        for agenda in player.scored:
                if agenda.has("agenda_points"):
                        total_points += agenda.agenda_points
        
        return total_points

func end_game(winner_id):
        current_phase = GamePhase.GAME_OVER
        
        # Create result data
        var result_data = {
                "winner_id": winner_id,
                "is_victory": winner_id == NetworkManager.player_id,
                "xp_gained": 10,  # Placeholder value
                "territory_gained": location_data if winner_id == NetworkManager.player_id else null
        }
        
        emit_signal("game_over", result_data)

func get_corp_id():
        for player_id in players:
                if players[player_id].type == PlayerType.CORP:
                        return player_id
        return null

func get_runner_id():
        for player_id in players:
                if players[player_id].type == PlayerType.RUNNER:
                        return player_id
        return null

func get_opponent_id(player_id):
        for id in players:
                if id != player_id:
                        return id
        return null

func set_game_location(location):
        location_data = location

func shuffle_array(array):
        var shuffled = array.duplicate()
        shuffled.shuffle()
        return shuffled
