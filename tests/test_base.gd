extends Node
class_name TestBase

# Base class for all test classes
# Provides common test functionality and utilities

var test_name = "Base Test"
var tests_passed = 0
var tests_failed = 0
var tests_skipped = 0

# Lifecycle methods
func setup():
	# Called before running tests
	tests_passed = 0
	tests_failed = 0
	tests_skipped = 0

func teardown():
	# Called after running tests
	pass

func run_tests():
	# This should be overridden by subclasses
	push_error("TestBase.run_tests: Subclasses must override this method")
	return false

# Assertion utilities
func assert_eq(a, b, message=""):
	"""
	Assert that two values are equal
	"""
	if a != b:
		if message:
			_log_failure(message + ": " + str(a) + " != " + str(b))
		else:
			_log_failure("Assertion failed: " + str(a) + " != " + str(b))
		return false
	return true

func assert_ne(a, b, message=""):
	"""
	Assert that two values are not equal
	"""
	if a == b:
		if message:
			_log_failure(message + ": " + str(a) + " == " + str(b))
		else:
			_log_failure("Assertion failed: " + str(a) + " == " + str(b))
		return false
	return true

func assert_true(condition, message=""):
	"""
	Assert that a condition is true
	"""
	if not condition:
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: Expected true but got false")
		return false
	return true

func assert_false(condition, message=""):
	"""
	Assert that a condition is false
	"""
	if condition:
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: Expected false but got true")
		return false
	return true

func assert_null(value, message=""):
	"""
	Assert that a value is null
	"""
	if value != null:
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: Expected null but got " + str(value))
		return false
	return true

func assert_not_null(value, message=""):
	"""
	Assert that a value is not null
	"""
	if value == null:
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: Expected non-null value but got null")
		return false
	return true

func assert_has(collection, value, message=""):
	"""
	Assert that a collection contains a value
	"""
	if value not in collection:
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: " + str(collection) + " does not contain " + str(value))
		return false
	return true

func assert_does_not_have(collection, value, message=""):
	"""
	Assert that a collection does not contain a value
	"""
	if value in collection:
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: " + str(collection) + " contains " + str(value))
		return false
	return true

func assert_is_type(value, type_name, message=""):
	"""
	Assert that a value is of a specific type
	"""
	if not is_instance_of(value, type_name):
		if message:
			_log_failure(message)
		else:
			_log_failure("Assertion failed: Expected instance of " + str(type_name) + " but got " + str(typeof(value)))
		return false
	return true

# Test utilities
func _log_success(message):
	"""
	Log a test success
	"""
	tests_passed += 1
	print("    [PASS] " + message)

func _log_failure(message):
	"""
	Log a test failure
	"""
	tests_failed += 1
	print("    [FAIL] " + message)
	print("           at " + get_stack()[1]["source"] + ":" + str(get_stack()[1]["line"]))

func _log_skip(message):
	"""
	Log a skipped test
	"""
	tests_skipped += 1
	print("    [SKIP] " + message)

# Mock utilities for testing
func create_mock_card(id, title, type, cost=0):
	"""
	Creates a mock card for testing
	"""
	var card = Card.new()
	card.id = id
	card.title = title
	card.card_type = type
	card.cost = cost
	return card

func create_mock_player(player_type, id="test_player", name="Test Player"):
	"""
	Creates a mock player for testing
	"""
	var player
	if player_type == Player.PlayerType.CORP:
		player = CorpPlayer.new()
	else:
		player = RunnerPlayer.new()
	
	player.player_id = id
	player.player_name = name
	return player

func create_test_deck(player_type, count=3):
	"""
	Creates a test deck for testing
	"""
	var deck = []
	
	if player_type == Player.PlayerType.CORP:
		# Add some corp cards
		for i in range(count):
			deck.append(create_mock_card("test_ice_" + str(i), "Test Ice " + str(i), "ice", 1))
			deck.append(create_mock_card("test_asset_" + str(i), "Test Asset " + str(i), "asset", 2))
			deck.append(create_mock_card("test_agenda_" + str(i), "Test Agenda " + str(i), "agenda", 3))
			deck.append(create_mock_card("test_operation_" + str(i), "Test Operation " + str(i), "operation", 1))
	else:
		# Add some runner cards
		for i in range(count):
			deck.append(create_mock_card("test_program_" + str(i), "Test Program " + str(i), "program", 2))
			deck.append(create_mock_card("test_hardware_" + str(i), "Test Hardware " + str(i), "hardware", 3))
			deck.append(create_mock_card("test_resource_" + str(i), "Test Resource " + str(i), "resource", 1))
			deck.append(create_mock_card("test_event_" + str(i), "Test Event " + str(i), "event", 2))
	
	return deck
