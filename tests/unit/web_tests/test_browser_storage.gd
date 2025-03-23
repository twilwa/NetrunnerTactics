extends GutTest

class TestBrowserStorage:
	extends GutTest
	
	# Path to the implementation file we're testing
	const BrowserStoragePath = "res://WebOptimizations/BrowserStorage.gd"
	
	var browser_storage = null
	
	func before_each():
		# Create a new instance for each test
		var script = load(BrowserStoragePath)
		browser_storage = script.new()
		add_child_autofree(browser_storage)
		
		# Clear storage before each test
		browser_storage.clear_all()
	
	func test_browser_storage_exists():
		assert_not_null(browser_storage, "BrowserStorage should be instantiable")
	
	func test_local_storage_save_load():
		# Test simple key-value storage
		var test_data = {
			"player_name": "TestPlayer",
			"tutorial_completed": true,
			"last_login": "2025-03-22"
		}
		
		# Save data to local storage
		var save_result = browser_storage.save_local("user_settings", test_data)
		assert_true(save_result, "Saving to local storage should succeed")
		
		# Load data from local storage
		var loaded_data = browser_storage.load_local("user_settings")
		
		# Verify data integrity
		assert_eq(loaded_data.player_name, test_data.player_name, "Player name should be preserved")
		assert_eq(loaded_data.tutorial_completed, test_data.tutorial_completed, "Tutorial flag should be preserved")
		assert_eq(loaded_data.last_login, test_data.last_login, "Last login date should be preserved")
	
	func test_indexed_db_save_load():
		# Test more complex data for IndexedDB
		var card_collection = []
		for i in range(20):
			card_collection.append({
				"id": "card_" + str(i),
				"count": (i % 3) + 1,
				"premium": i % 5 == 0
			})
		
		var collection_data = {
			"cards": card_collection,
			"last_updated": "2025-03-22"
		}
		
		# Save to IndexedDB
		var save_result = browser_storage.save_indexed_db("card_collection", collection_data)
		
		# This should be awaited in a real test, but for our example we'll simulate completion
		browser_storage._simulate_indexed_db_operation_complete()
		
		assert_true(save_result, "Saving to IndexedDB should succeed")
		
		# Load from IndexedDB
		var loaded_collection = browser_storage.load_indexed_db("card_collection")
		browser_storage._simulate_indexed_db_operation_complete()
		
		# Verify data
		assert_eq(loaded_collection.cards.size(), 20, "Should have 20 cards in collection")
		assert_eq(loaded_collection.cards[0].id, "card_0", "First card ID should match")
		assert_eq(loaded_collection.last_updated, "2025-03-22", "Last updated date should match")
	
	func test_storage_availability():
		# Test storage availability detection
		var storage_status = browser_storage.get_storage_availability()
		
		assert_true(storage_status.has("local_storage"), "Storage status should report on local storage")
		assert_true(storage_status.has("indexed_db"), "Storage status should report on IndexedDB")
	
	func test_storage_quota():
		# Test storage quota management
		var quota_info = browser_storage.get_storage_quota_info()
		
		assert_true(quota_info.has("usage"), "Quota info should include current usage")
		assert_true(quota_info.has("quota"), "Quota info should include total quota")
		assert_true(quota_info.has("percentage"), "Quota info should include usage percentage")
	
	func test_deck_storage_and_retrieval():
		# Test deck storage functionality
		var test_deck = {
			"id": "test_deck_1",
			"name": "Test Runner Deck",
			"identity": "gabriel_santiago",
			"cards": [
				{"id": "sure_gamble", "count": 3},
				{"id": "easy_mark", "count": 3},
				{"id": "corroder", "count": 2},
				{"id": "desperado", "count": 1},
				{"id": "special_order", "count": 2}
			],
			"created_at": "2025-03-21",
			"last_modified": "2025-03-22"
		}
		
		# Save deck
		var save_result = browser_storage.save_deck(test_deck)
		assert_true(save_result, "Saving deck should succeed")
		
		# Retrieve deck
		var loaded_deck = browser_storage.load_deck("test_deck_1")
		assert_not_null(loaded_deck, "Loaded deck should not be null")
		assert_eq(loaded_deck.name, "Test Runner Deck", "Deck name should match")
		assert_eq(loaded_deck.cards.size(), 5, "Deck should have 5 cards")
		assert_eq(loaded_deck.cards[0].id, "sure_gamble", "First card should match")
	
	func test_deck_list_retrieval():
		# Create multiple decks
		for i in range(5):
			var deck = {
				"id": "deck_" + str(i),
				"name": "Test Deck " + str(i),
				"identity": "gabriel_santiago" if i % 2 == 0 else "kit_peddler",
				"cards": [{"id": "sure_gamble", "count": 3}],
				"created_at": "2025-03-22"
			}
			browser_storage.save_deck(deck)
		
		# Get deck list
		var deck_list = browser_storage.get_all_decks()
		assert_eq(deck_list.size(), 5, "Should have 5 decks")
		
		# Get decks by identity
		var gabriel_decks = browser_storage.get_decks_by_identity("gabriel_santiago")
		assert_eq(gabriel_decks.size(), 3, "Should have 3 Gabriel decks")
		
		var kit_decks = browser_storage.get_decks_by_identity("kit_peddler")
		assert_eq(kit_decks.size(), 2, "Should have 2 Kit decks")
	
	func test_player_progression_storage():
		# Test player progression data
		var progression = {
			"xp": 1250,
			"level": 15,
			"unlocked_cards": ["corroder", "gordian_blade", "armitage_codebusting"],
			"reputation": {
				"criminal": 75,
				"shaper": 30,
				"anarch": 20
			},
			"tutorial_completed": true,
			"achievements": ["first_run", "first_win", "deck_builder"]
		}
		
		# Save progression
		browser_storage.save_progression(progression)
		
		# Load progression
		var loaded_progression = browser_storage.load_progression()
		
		# Verify data
		assert_eq(loaded_progression.xp, 1250, "XP should match")
		assert_eq(loaded_progression.level, 15, "Level should match")
		assert_eq(loaded_progression.unlocked_cards.size(), 3, "Should have 3 unlocked cards")
		assert_eq(loaded_progression.reputation.criminal, 75, "Criminal reputation should match")
	
	func test_offline_support():
		# Test offline mode flag
		browser_storage.set_offline_mode(true)
		assert_true(browser_storage.is_offline_mode(), "Offline mode should be enabled")
		
		# Save data during offline mode
		var offline_action = {
			"type": "deck_edit",
			"deck_id": "test_deck",
			"timestamp": "2025-03-22T14:30:00",
			"changes": [{"card_id": "sure_gamble", "new_count": 2}]
		}
		
		browser_storage.queue_offline_action(offline_action)
		
		# Check pending actions
		var pending_actions = browser_storage.get_pending_offline_actions()
		assert_eq(pending_actions.size(), 1, "Should have 1 pending action")
		assert_eq(pending_actions[0].type, "deck_edit", "Action type should match")
		
		# Simulate going online
		browser_storage.set_offline_mode(false)
		assert_false(browser_storage.is_offline_mode(), "Offline mode should be disabled")
		
		# Process pending actions
		browser_storage.process_pending_offline_actions()
		
		# Pending actions should be cleared
		pending_actions = browser_storage.get_pending_offline_actions()
		assert_eq(pending_actions.size(), 0, "Pending actions should be processed")
	
	func test_data_migration():
		# Test data migration for schema updates
		# First, save data in old format
		var old_progression = {
			"xp": 1000,
			"level": 10,
			"unlocked_cards": ["corroder", "gordian_blade"],
			# Missing reputation field that exists in new schema
		}
		
		browser_storage._save_with_old_schema("player_progression", old_progression)
		
		# Load with migration
		var migrated_data = browser_storage.load_progression()
		
		# Verify basic fields persisted
		assert_eq(migrated_data.xp, 1000, "XP should be migrated")
		assert_eq(migrated_data.level, 10, "Level should be migrated")
		
		# Verify new fields were added with defaults
		assert_true(migrated_data.has("reputation"), "New reputation field should exist")
		assert_eq(migrated_data.reputation.criminal, 0, "Default Criminal reputation should be 0")
		
		# Test data version tracking
		assert_eq(browser_storage.get_data_version(), 2, "Data should be migrated to version 2")
	
	func test_storage_limits():
		# Test handling of storage limits
		var large_data = {"array": []}
		
		# Create data that exceeds local storage limits
		for i in range(1000):
			large_data.array.append("item_" + str(i) + "_" + "x".repeat(100))
		
		# Should gracefully handle storage limit
		var result = browser_storage.save_local("large_data", large_data)
		
		if result == false:
			# If save failed due to quota, should report error
			assert_true(browser_storage.get_last_error().contains("quota"), "Error should mention quota")
			
			# Should automatically fall back to IndexedDB
			var fallback_result = browser_storage.has_fallback_storage("large_data")
			assert_true(fallback_result, "Data should be stored in fallback storage")
		else:
			# If save succeeded, it should be retrievable
			var loaded_data = browser_storage.load_local("large_data")
			assert_eq(loaded_data.array.size(), 1000, "All items should be stored and retrieved")
