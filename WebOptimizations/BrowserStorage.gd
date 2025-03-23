extends Node
class_name BrowserStorage

signal storage_initialized
signal error_occurred(error_message)

# Storage types
enum StorageType {
	LOCAL_STORAGE,
	INDEXED_DB,
	MEMORY_FALLBACK
}

# Current data version for migration handling
const CURRENT_DATA_VERSION = 2

# Internal state
var _is_initialized = false
var _is_offline_mode = false
var _storage_available = {
	"local_storage": false,
	"indexed_db": false
}
var _last_error = ""
var _data_version = 1
var _memory_storage = {} # Fallback when web storage isn't available

# Pending actions for offline mode
var _pending_offline_actions = []

func _ready():
	# Initialize storage availability detection
	_detect_storage_availability()
	
	# Load data version
	_load_data_version()

# PUBLIC API

# Save data to local storage
func save_local(key: String, data) -> bool:
	if not _storage_available.local_storage:
		_handle_storage_error("Local storage is not available")
		return _fallback_to_memory_storage(key, data)
	
	# Attempt to save to local storage
	try:
		var json_data = JSON.stringify(data)
		JavaScript.eval("localStorage.setItem('" + key + "', arguments[0])", [json_data])
		return true
	except e:
		_handle_storage_error("Failed to save to local storage: " + str(e))
		return _fallback_to_memory_storage(key, data)

# Load data from local storage
func load_local(key: String):
	if not _storage_available.local_storage:
		_handle_storage_error("Local storage is not available")
		return _load_from_memory_storage(key)
	
	# Attempt to load from local storage
	try:
		var json_data = JavaScript.eval("localStorage.getItem('" + key + "')")
		if json_data == null:
			return null
		
		return JSON.parse_string(json_data)
	except e:
		_handle_storage_error("Failed to load from local storage: " + str(e))
		return _load_from_memory_storage(key)

# Save data to IndexedDB
func save_indexed_db(key: String, data) -> bool:
	if not _storage_available.indexed_db:
		_handle_storage_error("IndexedDB is not available")
		return _fallback_to_memory_storage(key, data)
	
	# In a real implementation, this would use IndexedDB APIs
	# For this example, we'll simulate it with local storage
	return save_local("idb_" + key, data)

# Load data from IndexedDB
func load_indexed_db(key: String):
	if not _storage_available.indexed_db:
		_handle_storage_error("IndexedDB is not available")
		return _load_from_memory_storage(key)
	
	# In a real implementation, this would use IndexedDB APIs
	# For this example, we'll simulate it with local storage
	return load_local("idb_" + key)

# Get storage availability
func get_storage_availability() -> Dictionary:
	return _storage_available

# Get storage quota information
func get_storage_quota_info() -> Dictionary:
	if not _storage_available.local_storage:
		return {
			"usage": 0,
			"quota": 0,
			"percentage": 0
		}
	
	# In a real implementation, this would use the Storage API
	# For this example, we'll return simulated values
	return {
		"usage": 2 * 1024 * 1024, # 2MB
		"quota": 10 * 1024 * 1024, # 10MB
		"percentage": 20 # 20%
	}

# Save deck
func save_deck(deck_data: Dictionary) -> bool:
	if not deck_data.has("id"):
		_handle_storage_error("Deck data must have an ID")
		return false
	
	# Add timestamp if missing
	if not deck_data.has("last_modified"):
		deck_data.last_modified = Time.get_datetime_string_from_system()
	
	# Save to storage
	var result
	if _storage_available.indexed_db:
		# Use IndexedDB for larger data
		result = save_indexed_db("deck_" + deck_data.id, deck_data)
	else:
		# Fall back to local storage
		result = save_local("deck_" + deck_data.id, deck_data)
	
	# Update deck list
	if result:
		_update_deck_list(deck_data)
	
	return result

# Load deck
func load_deck(deck_id: String):
	var deck_data
	
	if _storage_available.indexed_db:
		# Try IndexedDB first
		deck_data = load_indexed_db("deck_" + deck_id)
	
	if deck_data == null:
		# Fall back to local storage
		deck_data = load_local("deck_" + deck_id)
	
	return deck_data

# Get all decks
func get_all_decks() -> Array:
	var deck_list = load_local("deck_list")
	if deck_list == null:
		return []
	return deck_list

# Get decks by identity
func get_decks_by_identity(identity_id: String) -> Array:
	var all_decks = get_all_decks()
	var matching_decks = []
	
	for deck in all_decks:
		if deck.identity == identity_id:
			matching_decks.append(deck)
	
	return matching_decks

# Save player progression
func save_progression(progression_data: Dictionary) -> bool:
	# Add version info
	progression_data.version = CURRENT_DATA_VERSION
	
	# Save to storage
	return save_local("player_progression", progression_data)

# Load player progression
func load_progression():
	var progression = load_local("player_progression")
	if progression == null:
		# Return default progression
		return {
			"xp": 0,
			"level": 1,
			"unlocked_cards": [],
			"reputation": {
				"criminal": 0,
				"shaper": 0,
				"anarch": 0
			},
			"tutorial_completed": false,
			"achievements": [],
			"version": CURRENT_DATA_VERSION
		}
	
	# Handle data migration
	if not progression.has("version") or progression.version < CURRENT_DATA_VERSION:
		progression = _migrate_progression_data(progression)
	
	return progression

# Set offline mode
func set_offline_mode(is_offline: bool) -> void:
	_is_offline_mode = is_offline

# Check if in offline mode
func is_offline_mode() -> bool:
	return _is_offline_mode

# Queue action for offline mode
func queue_offline_action(action: Dictionary) -> void:
	_pending_offline_actions.append(action)
	save_local("pending_offline_actions", _pending_offline_actions)

# Get pending offline actions
func get_pending_offline_actions() -> Array:
	return _pending_offline_actions.duplicate()

# Process pending offline actions
func process_pending_offline_actions() -> void:
	# In a real implementation, this would sync with the server
	_pending_offline_actions.clear()
	save_local("pending_offline_actions", _pending_offline_actions)

# Check if data is in fallback storage
func has_fallback_storage(key: String) -> bool:
	return _memory_storage.has(key)

# Get last error message
func get_last_error() -> String:
	return _last_error

# Get current data version
func get_data_version() -> int:
	return _data_version

# Clear all storage
func clear_all() -> void:
	if _storage_available.local_storage:
		JavaScript.eval("localStorage.clear()")
	
	_memory_storage.clear()

# Clear in-memory cache
func clear_cache() -> void:
	_memory_storage.clear()

# PRIVATE METHODS

# Detect what storage types are available
func _detect_storage_availability() -> void:
	# Check local storage
	_storage_available.local_storage = JavaScript.eval("""
		try {
			localStorage.setItem('test', 'test');
			localStorage.removeItem('test');
			return true;
		} catch(e) {
			return false;
		}
	""")
	
	# Check IndexedDB
	_storage_available.indexed_db = JavaScript.eval("""
		return typeof indexedDB !== 'undefined';
	""")
	
	_is_initialized = true
	emit_signal("storage_initialized")

# Handle storage errors
func _handle_storage_error(error_message: String) -> void:
	_last_error = error_message
	emit_signal("error_occurred", error_message)

# Fall back to memory storage when web storage is unavailable
func _fallback_to_memory_storage(key: String, data) -> bool:
	_memory_storage[key] = data
	return true

# Load from memory storage fallback
func _load_from_memory_storage(key: String):
	if _memory_storage.has(key):
		return _memory_storage[key]
	return null

# Update the deck list when a deck is saved
func _update_deck_list(deck_data: Dictionary) -> void:
	var deck_list = get_all_decks()
	
	# Check if deck already exists in list
	var existing_index = -1
	for i in range(deck_list.size()):
		if deck_list[i].id == deck_data.id:
			existing_index = i
			break
	
	# Create simplified deck info
	var deck_info = {
		"id": deck_data.id,
		"name": deck_data.name,
		"identity": deck_data.identity,
		"last_modified": deck_data.last_modified
	}
	
	# Update existing or add new
	if existing_index >= 0:
		deck_list[existing_index] = deck_info
	else:
		deck_list.append(deck_info)
	
	# Save updated list
	save_local("deck_list", deck_list)

# Load data version
func _load_data_version() -> void:
	var version_data = load_local("data_version")
	if version_data != null:
		_data_version = version_data.version
	else:
		# Save initial version
		save_local("data_version", {"version": CURRENT_DATA_VERSION})
		_data_version = CURRENT_DATA_VERSION

# Migrate progression data to newer version
func _migrate_progression_data(old_data: Dictionary) -> Dictionary:
	# Clone the data
	var migrated_data = old_data.duplicate(true)
	
	# Add missing fields for version 2
	if not migrated_data.has("version") or migrated_data.version < 2:
		# Add reputation if missing
		if not migrated_data.has("reputation"):
			migrated_data.reputation = {
				"criminal": 0,
				"shaper": 0,
				"anarch": 0
			}
		
		# Add achievements if missing
		if not migrated_data.has("achievements"):
			migrated_data.achievements = []
		
		# Set version to 2
		migrated_data.version = 2
	}
	
	# Save migrated data
	save_local("player_progression", migrated_data)
	
	# Update data version
	_data_version = 2
	save_local("data_version", {"version": 2})
	
	return migrated_data

# TESTING HELPERS
# These methods are only for testing and would not be in a production build

# Save with old schema (for testing migration)
func _save_with_old_schema(key: String, data: Dictionary) -> bool:
	# Ensure no version field
	var old_data = data.duplicate(true)
	old_data.erase("version")
	
	# Save without version field
	return save_local(key, old_data)

# Simulate IndexedDB operation complete (for testing asynchronous operations)
func _simulate_indexed_db_operation_complete() -> void:
	# This would be triggered by a callback in a real implementation
	pass
