extends Node
class_name AssetStreamer

signal loading_started
signal loading_progress(progress)
signal loading_completed
signal asset_loaded(asset_id, asset_data)
signal memory_pressure_detected

# Asset categories and their loading priority
enum PriorityLevel {
	CRITICAL = 10,   # Must load immediately (UI elements, essential textures)
	HIGH = 7,        # Load soon (visible cards, nearby world chunks)
	MEDIUM = 5,      # Load when possible (audio, effects, animations)
	LOW = 3,         # Load in background (distant world chunks, card backs)
	DEFERRED = 1     # Load only when specifically requested
}

# Constants for memory and performance management
const MAX_MEMORY_USAGE_MB = 150 # Target memory usage for mobile web
const PRELOAD_RADIUS = 2 # Chunk radius to preload
const UNLOAD_BEYOND_RADIUS = 4 # Chunk radius beyond which to unload

# Cached assets
var _asset_cache = {}
var _memory_usage = 0 # Approximate memory usage in bytes

# Asset loading queue
var _asset_queue = []
var _is_loading = false
var _current_batch = []

# World chunking
var _viewer_position = Vector2(0, 0)
var _loaded_chunks = {}
var _preloaded_chunks = []

# Critical assets for initial loading
var _critical_asset_definitions = {
	"ui_elements": {
		"files": [
			"res://assets/ui/main_buttons.png",
			"res://assets/ui/icons.png",
			"res://assets/ui/frames.png"
		],
		"size": 512 * 1024 # 512KB
	},
	"card_templates": {
		"files": [
			"res://assets/cards/runner_card_template.png",
			"res://assets/cards/corp_card_template.png"
		],
		"size": 256 * 1024 # 256KB
	},
	"fonts": {
		"files": [
			"res://assets/fonts/main_font.ttf",
			"res://assets/fonts/card_title_font.ttf"
		],
		"size": 128 * 1024 # 128KB
	}
}

func _ready():
	# Connect to low memory warning if on mobile platforms
	if OS.has_feature("mobile"):
		get_tree().connect("low_memory", _on_low_memory)

# PUBLIC API

# Get the list of critical assets that must be loaded immediately
func get_critical_assets() -> Dictionary:
	return _critical_asset_definitions

# Calculate the total size of assets in a bundle
func calculate_bundle_size(assets: Dictionary) -> int:
	var total_size = 0
	for category in assets:
		total_size += assets[category].size
	return total_size

# Request an asset to be loaded with specified priority
func request_asset(asset_id: String, priority: int) -> void:
	# Skip if already cached
	if is_asset_cached(asset_id):
		return
	
	# Skip if already in queue
	for item in _asset_queue:
		if item.asset_id == asset_id:
			# Update priority if higher
			if priority > item.priority:
				item.priority = priority
			return
	
	# Add to queue
	_asset_queue.append({
		"asset_id": asset_id,
		"priority": priority,
		"requested_time": Time.get_ticks_msec()
	})
	
	# Sort queue by priority (highest first)
	_sort_queue()
	
	# Start loading if not already in progress
	if not _is_loading:
		_process_next_batch()

# Check if an asset is currently cached
func is_asset_cached(asset_id: String) -> bool:
	return _asset_cache.has(asset_id)

# Get number of cached assets
func get_cached_asset_count() -> int:
	return _asset_cache.size()

# Get sorted loading queue
func get_priority_queue() -> Array:
	return _asset_queue.duplicate()

# Start loading assets in background
func start_background_loading() -> void:
	# Sort queue by priority
	_sort_queue()
	
	# Start processing queue in background
	_is_loading = true
	_process_next_batch()

# Get appropriate texture compression options for web
func get_web_texture_options() -> Dictionary:
	return {
		"etc2": true,    # For WebGL 2 on Android
		"s3tc": true,    # For WebGL on desktop/iOS
		"basis": true,   # Universal texture compression
		"max_size": 1024 # Max texture size
	}

# Get mobile-specific texture settings
func get_mobile_texture_settings() -> Dictionary:
	return {
		"max_size": 512,         # Max texture size for mobile
		"format": Image.FORMAT_COMPRESSED_ETC2_RGBA8, # Preferred format
		"mipmap": true,          # Enable mipmaps for LOD
		"filter": true           # Enable filtering
	}

# Request loading of world chunk at specified coordinates
func request_world_chunk(chunk_id: String, coordinates: Vector2) -> void:
	# Add to loaded chunks
	_loaded_chunks[chunk_id] = {
		"coordinates": coordinates,
		"loaded_time": Time.get_ticks_msec()
	}
	
	# Request asset with appropriate priority
	var distance = coordinates.distance_to(_viewer_position)
	var priority = PriorityLevel.HIGH if distance < 1 else \
					PriorityLevel.MEDIUM if distance < 2 else \
					PriorityLevel.LOW
	
	request_asset(chunk_id, priority)
	
	# Calculate which neighboring chunks to preload
	_preload_neighboring_chunks(coordinates)

# Update viewer position (player position in world)
func update_viewer_position(position: Vector2) -> void:
	_viewer_position = position
	
	# Update priorities based on new position
	_update_chunk_priorities()

# Unload distant chunks to free memory
func unload_distant_chunks(radius: int = UNLOAD_BEYOND_RADIUS) -> void:
	var chunks_to_unload = []
	
	# Find chunks beyond the specified radius
	for chunk_id in _loaded_chunks:
		var coords = _loaded_chunks[chunk_id].coordinates
		var distance = coords.distance_to(_viewer_position)
		
		if distance > radius:
			chunks_to_unload.append(chunk_id)
	
	# Unload the chunks
	for chunk_id in chunks_to_unload:
		_unload_asset(chunk_id)
		_loaded_chunks.erase(chunk_id)

# Get list of coordinates of preloaded chunks
func get_preloaded_chunk_coordinates() -> Array:
	return _preloaded_chunks.duplicate()

# INTERNAL METHODS

# Sort the asset queue by priority
func _sort_queue() -> void:
	_asset_queue.sort_custom(func(a, b): return a.priority > b.priority)

# Process next batch of assets
func _process_next_batch() -> void:
	if _asset_queue.empty():
		_is_loading = false
		emit_signal("loading_completed")
		return
	
	# Determine batch size based on priority
	var batch_size = 5
	_current_batch = []
	
	# Add highest priority items to batch
	for i in range(min(batch_size, _asset_queue.size())):
		_current_batch.append(_asset_queue[i])
	
	# Remove items from queue
	for i in range(_current_batch.size()):
		_asset_queue.pop_front()
	
	# Emit signal
	emit_signal("loading_started")
	
	# In a real implementation, we would load the assets asynchronously
	# For this example, we'll simulate it with a timer
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_batch_loaded)
	timer.start()

# Called when a batch is loaded
func _on_batch_loaded() -> void:
	# In a real implementation, this would be called when assets are actually loaded
	for i in range(_current_batch.size()):
		var item = _current_batch[i]
		
		# Simulate loading the asset
		var asset_data = "Simulated asset data for " + item.asset_id
		
		# Add to cache
		_asset_cache[item.asset_id] = {
			"data": asset_data,
			"loaded_time": Time.get_ticks_msec(),
			"priority": item.priority
		}
		
		# Simulate memory usage for tracking
		_memory_usage += 100 * 1024 # Assume 100KB per asset
		
		# Emit signal
		emit_signal("asset_loaded", item.asset_id, asset_data)
		
		# Emit progress signal
		var progress = float(i + 1) / _current_batch.size()
		emit_signal("loading_progress", progress)
	
	# Process next batch
	_process_next_batch()

# Calculate which adjacent chunks to preload
func _preload_neighboring_chunks(center: Vector2) -> void:
	_preloaded_chunks = []
	
	# Add chunks in a square around the center
	for x in range(center.x - PRELOAD_RADIUS, center.x + PRELOAD_RADIUS + 1):
		for y in range(center.y - PRELOAD_RADIUS, center.y + PRELOAD_RADIUS + 1):
			var chunk_pos = Vector2(x, y)
			if chunk_pos != center:  # Skip the center chunk as it's already loaded
				_preloaded_chunks.append(chunk_pos)
				
				# Request the chunk asset
				var chunk_id = "chunk_" + str(int(x)) + "_" + str(int(y))
				var distance = chunk_pos.distance_to(center)
				var priority = PriorityLevel.MEDIUM if distance <= 1 else PriorityLevel.LOW
				
				request_asset(chunk_id, priority)

# Update chunk priorities based on viewer position
func _update_chunk_priorities() -> void:
	# Update priorities in the queue
	for i in range(_asset_queue.size()):
		var item = _asset_queue[i]
		
		# Check if it's a chunk
		if item.asset_id.begins_with("chunk_"):
			# Extract coordinates from id
			var parts = item.asset_id.split("_")
			if parts.size() >= 3:
				var chunk_x = int(parts[1])
				var chunk_y = int(parts[2])
				var coords = Vector2(chunk_x, chunk_y)
				
				var distance = coords.distance_to(_viewer_position)
				var new_priority = PriorityLevel.HIGH if distance < 1 else \
									PriorityLevel.MEDIUM if distance < 2 else \
									PriorityLevel.LOW
				
				# Update priority if changed
				if new_priority != item.priority:
					item.priority = new_priority
	
	# Resort the queue
	_sort_queue()

# Unload an asset to free memory
func _unload_asset(asset_id: String) -> void:
	if _asset_cache.has(asset_id):
		# Reduce memory usage estimate
		_memory_usage -= 100 * 1024 # Assume 100KB per asset
		
		# Remove from cache
		_asset_cache.erase(asset_id)

# Handle low memory warning
func _on_low_memory() -> void:
	emit_signal("memory_pressure_detected")
	_simulate_memory_pressure()

# Reduce memory usage when under pressure
func _simulate_memory_pressure() -> void:
	# Unload low priority assets
	var assets_to_unload = []
	for asset_id in _asset_cache:
		var asset = _asset_cache[asset_id]
		
		# Keep high priority assets
		if asset.priority <= PriorityLevel.LOW:
			assets_to_unload.append(asset_id)
	
	# Unload assets
	for asset_id in assets_to_unload:
		_unload_asset(asset_id)

# TESTING HELPERS
# These methods are only for testing and would not be in a production build

# Simulate asset loaded (for testing)
func _simulate_asset_loaded(asset_id: String, asset_data) -> void:
	_asset_cache[asset_id] = {
		"data": asset_data,
		"loaded_time": Time.get_ticks_msec(),
		"priority": PriorityLevel.MEDIUM
	}
	_memory_usage += 100 * 1024 # Assume 100KB per asset

# Simulate memory pressure (for testing)
func _simulate_memory_pressure() -> void:
	# Reduce memory usage
	var assets_to_unload = []
	for asset_id in _asset_cache:
		var asset = _asset_cache[asset_id]
		
		# Keep high priority assets
		if asset.priority <= PriorityLevel.LOW:
			assets_to_unload.append(asset_id)
	
	# Unload assets
	for asset_id in assets_to_unload:
		_unload_asset(asset_id)

# Simulate background loading complete (for testing)
func _simulate_background_loading_complete() -> void:
	for i in range(10):
		var progress = float(i + 1) / 10
		emit_signal("loading_progress", progress)
	
	emit_signal("loading_completed")
