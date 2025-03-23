extends GutTest

class TestAssetStreamer:
	extends GutTest
	
	# Path to the implementation file we're testing
	const AssetStreamerPath = "res://WebOptimizations/AssetStreamer.gd"
	
	var asset_streamer = null
	
	func before_each():
		# Create a new instance for each test
		var script = load(AssetStreamerPath)
		asset_streamer = script.new()
		add_child_autofree(asset_streamer)
	
	func test_asset_streamer_exists():
		assert_not_null(asset_streamer, "AssetStreamer should be instantiable")
	
	func test_critical_assets_identification():
		# Critical assets should be identified for initial loading
		var critical_assets = asset_streamer.get_critical_assets()
		
		# Critical assets should include UI, base card templates, and essential textures
		assert_true(critical_assets.has("ui_elements"), "Critical assets should include UI elements")
		assert_true(critical_assets.has("card_templates"), "Critical assets should include card templates")
		assert_true(critical_assets.has("fonts"), "Critical assets should include fonts")
		
		# Check total critical asset size limit (5MB for initial load)
		var total_size = asset_streamer.calculate_bundle_size(critical_assets)
		assert_lt(total_size, 5 * 1024 * 1024, "Initial payload should be under 5MB")
	
	func test_asset_priority_queue():
		# Test priority-based loading system
		asset_streamer.request_asset("card_texture_1", 1) # Low priority
		asset_streamer.request_asset("card_texture_2", 5) # High priority
		asset_streamer.request_asset("card_texture_3", 3) # Medium priority
		
		var queue = asset_streamer.get_priority_queue()
		
		# Queue should be ordered by priority (highest first)
		assert_eq(queue[0].asset_id, "card_texture_2", "Highest priority asset should be first")
		assert_eq(queue[1].asset_id, "card_texture_3", "Medium priority asset should be second")
		assert_eq(queue[2].asset_id, "card_texture_1", "Lowest priority asset should be last")
	
	func test_asset_caching():
		# Assets should be cached once loaded
		asset_streamer.request_asset("test_asset", 3)
		
		# Simulate asset loading
		asset_streamer._simulate_asset_loaded("test_asset", "test_data")
		
		# Asset should now be in the cache
		assert_true(asset_streamer.is_asset_cached("test_asset"), "Asset should be cached after loading")
		
		# Requesting the same asset again should use cache
		asset_streamer.request_asset("test_asset", 3)
		assert_eq(asset_streamer.get_priority_queue().size(), 0, "Cached asset should not be in request queue")
	
	func test_asset_memory_management():
		# Load several assets
		for i in range(10):
			asset_streamer.request_asset("asset_" + str(i), 1)
			asset_streamer._simulate_asset_loaded("asset_" + str(i), "test_data_" + str(i))
		
		# All assets should be cached
		assert_eq(asset_streamer.get_cached_asset_count(), 10, "All assets should be cached")
		
		# Trigger memory limit (simulate low memory)
		asset_streamer._simulate_memory_pressure()
		
		# Low priority assets should be unloaded
		assert_lt(asset_streamer.get_cached_asset_count(), 10, "Some assets should be unloaded under memory pressure")
		
		# Essential assets should still be cached
		assert_true(asset_streamer.is_asset_cached("asset_0"), "Essential assets should remain cached")
	
	func test_background_loading():
		# Request multiple assets
		for i in range(5):
			asset_streamer.request_asset("bg_asset_" + str(i), 1)
		
		# Start background loading
		asset_streamer.start_background_loading()
		
		# Track loading progress
		var progress_updates = []
		asset_streamer.connect("loading_progress", func(progress): progress_updates.append(progress))
		
		# Simulate background loading completion
		asset_streamer._simulate_background_loading_complete()
		
		# Progress should have been reported
		assert_gt(progress_updates.size(), 0, "Loading progress should be reported")
		assert_eq(progress_updates[-1], 1.0, "Final progress should be 100%")
		
		# All assets should be loaded
		for i in range(5):
			assert_true(asset_streamer.is_asset_cached("bg_asset_" + str(i)), "Asset should be loaded in background")
	
	func test_texture_compression_options():
		# WebGL texture compression options
		var compression_options = asset_streamer.get_web_texture_options()
		
		# Should include appropriate compression types for web
		assert_true(compression_options.has("etc2"), "Should support ETC2 compression for WebGL")
		assert_true(compression_options.has("s3tc"), "Should support S3TC compression for WebGL")
		
		# Should include mobile-specific settings
		var mobile_settings = asset_streamer.get_mobile_texture_settings()
		assert_lt(mobile_settings.max_size, 1024, "Mobile textures should be appropriately sized")
	
	func test_streaming_for_world_chunks():
		# Request world chunk assets
		asset_streamer.request_world_chunk("chunk_0_0", Vector2(0, 0))
		
		# Neighboring chunks should be preloaded
		var preloaded_chunks = asset_streamer.get_preloaded_chunk_coordinates()
		assert_true(preloaded_chunks.has(Vector2(1, 0)), "Adjacent chunks should be preloaded")
		assert_true(preloaded_chunks.has(Vector2(0, 1)), "Adjacent chunks should be preloaded")
		
		# Far away chunks should not be preloaded
		assert_false(preloaded_chunks.has(Vector2(5, 5)), "Far chunks should not be preloaded")
	
	func test_asset_unloading_by_distance():
		# Load several chunks
		for x in range(5):
			for y in range(5):
				asset_streamer.request_world_chunk("chunk_" + str(x) + "_" + str(y), Vector2(x, y))
				asset_streamer._simulate_asset_loaded("chunk_" + str(x) + "_" + str(y), "chunk_data")
		
		# Set player position in the center
		asset_streamer.update_viewer_position(Vector2(2, 2))
		
		# Unload distant chunks
		asset_streamer.unload_distant_chunks(2)  # 2 chunk radius
		
		# Close chunks should still be loaded
		assert_true(asset_streamer.is_asset_cached("chunk_2_2"), "Current chunk should be cached")
		assert_true(asset_streamer.is_asset_cached("chunk_3_3"), "Nearby chunk should be cached")
		
		# Far chunks should be unloaded
		assert_false(asset_streamer.is_asset_cached("chunk_0_0"), "Far chunk should be unloaded")
		assert_false(asset_streamer.is_asset_cached("chunk_4_4"), "Far chunk should be unloaded")
