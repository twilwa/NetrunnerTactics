extends Node

# ProgressionSystem handles player progression, experience, levels,
# unlocks, and territory control

signal experience_gained(player_id, amount)
signal level_up(player_id, new_level)
signal territory_gained(player_id, territory)
signal territory_lost(player_id, territory)

# Experience required for each level
const XP_REQUIREMENTS = {
        1: 0,
        2: 100,
        3: 250,
        4: 500,
        5: 1000,
        6: 2000,
        7: 4000,
        8: 8000,
        9: 16000,
        10: 32000
}

# Unlocks at each level
const LEVEL_UNLOCKS = {
        1: {
                "cards": ["sure_gamble", "hedge_fund", "ice_wall", "corroder"],
                "territories": 1
        },
        2: {
                "cards": ["enigma", "pad_campaign", "kati_jones"],
                "territories": 2
        },
        3: {
                "cards": ["project_atlas", "astrolabe"],
                "territories": 3
        },
        # Add more levels and unlocks
}

# Player progression data
var player_progression = {}

func initialize_player(player_id, player_type):
        if not player_progression.has(player_id):
                player_progression[player_id] = {
                        "experience": 0,
                        "level": 1,
                        "territories": [],
                        "unlocked_cards": get_starter_unlocks(player_type),
                        "decks": []
                }
                
                # Add a starter deck
                var starter_deck = CardDatabase.get_starter_deck(player_type)
                player_progression[player_id].decks.append({
                        "name": "Starter Deck",
                        "cards": starter_deck
                })

func get_starter_unlocks(player_type):
        # Basic cards that a new player starts with
        var unlock_list = []
        
        # Add level 1 unlocks
        for card_id in LEVEL_UNLOCKS[1].cards:
                var card = CardDatabase.get_card(card_id)
                if card and ((player_type == "corp" and CardDatabase.corp_cards.has(card_id)) or
                        (player_type == "runner" and CardDatabase.runner_cards.has(card_id))):
                        unlock_list.append(card_id)
        
        return unlock_list

func add_experience(player_data, amount):
        var player_id = player_data.id
        
        if not player_progression.has(player_id):
                initialize_player(player_id, player_data.type)
        
        var prog = player_progression[player_id]
        var old_level = prog.level
        
        # Add experience
        prog.experience += amount
        emit_signal("experience_gained", player_id, amount)
        
        # Check for level up
        var new_level = calculate_level(prog.experience)
        if new_level > old_level:
                prog.level = new_level
                apply_level_unlocks(player_id, old_level, new_level)
                emit_signal("level_up", player_id, new_level)

func calculate_level(experience):
        var level = 1
        
        for lvl in range(10, 0, -1):
                if experience >= XP_REQUIREMENTS[lvl]:
                        level = lvl
                        break
        
        return level

func apply_level_unlocks(player_id, old_level, new_level):
        var prog = player_progression[player_id]
        
        # Apply unlocks for each level gained
        for level in range(old_level + 1, new_level + 1):
                if LEVEL_UNLOCKS.has(level):
                        var unlocks = LEVEL_UNLOCKS[level]
                        
                        # Unlock cards
                        if unlocks.has("cards"):
                                for card_id in unlocks.cards:
                                        if not prog.unlocked_cards.has(card_id):
                                                prog.unlocked_cards.append(card_id)
                        
                        # Increase territory limit
                        # (This is handled dynamically based on level)
                
                # Display notification to the player about new unlocks
                # This would be handled by the UI

func get_territory_limit(player_id):
        if player_progression.has(player_id):
                var level = player_progression[player_id].level
                
                # Calculate total territory limit based on level
                var total_limit = 0
                for l in range(1, level + 1):
                        if LEVEL_UNLOCKS.has(l) and LEVEL_UNLOCKS[l].has("territories"):
                                total_limit += LEVEL_UNLOCKS[l].territories
                
                return total_limit
        
        return 0

func can_claim_territory(player_id, territory_count=1):
        if player_progression.has(player_id):
                var prog = player_progression[player_id]
                var current_territory_count = prog.territories.size()
                var limit = get_territory_limit(player_id)
                
                return current_territory_count + territory_count <= limit
        
        return false

func add_territory(player_id, territory_data):
        if not player_progression.has(player_id):
                return false
        
        if can_claim_territory(player_id):
                player_progression[player_id].territories.append(territory_data)
                emit_signal("territory_gained", player_id, territory_data)
                return true
        
        return false

func remove_territory(player_id, territory_id):
        if not player_progression.has(player_id):
                return false
        
        var prog = player_progression[player_id]
        
        for i in range(prog.territories.size()):
                if prog.territories[i].id == territory_id:
                        var removed_territory = prog.territories[i]
                        prog.territories.remove(i)
                        emit_signal("territory_lost", player_id, removed_territory)
                        return true
        
        return false

func get_player_territories(player_id):
        if player_progression.has(player_id):
                return player_progression[player_id].territories
        
        return []

func get_unlocked_cards(player_id):
        if player_progression.has(player_id):
                return player_progression[player_id].unlocked_cards
        
        return []

func get_player_decks(player_id):
        if player_progression.has(player_id):
                return player_progression[player_id].decks
        
        return []

func add_deck(player_id, deck_name, deck_cards):
        if player_progression.has(player_id):
                player_progression[player_id].decks.append({
                        "name": deck_name,
                        "cards": deck_cards
                })
                return true
        
        return false

func process_game_rewards(player_id, game_result):
        # Calculate rewards based on game result
        var rewards = {
                "experience": 0,
                "territory_chance": 0
        }
        
        if game_result.victory:
                # Base rewards for winning
                rewards.experience = 100
                rewards.territory_chance = 1.0
        else:
                # Consolation rewards for losing
                rewards.experience = 25
                rewards.territory_chance = 0.25
        
        # Apply rewards
        var player_data = { "id": player_id, "type": "unknown" }  # Type will be determined from saved data
        add_experience(player_data, rewards.experience)
        
        # Territory rewards
        if game_result.territory_gained and randf() <= rewards.territory_chance:
                add_territory(player_id, game_result.territory_gained)
        
        return rewards