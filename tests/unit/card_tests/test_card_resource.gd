extends GutTest

# This test fixture focuses on the CardResource class which represents 
# the definition/template of a card (not an instance in play)

# Path to the implementation file we're testing
const CardResourcePath = "res://CardSystem/Models/CardResource.gd"

func before_all():
	gut.p("Starting CardResource tests")

func after_all():
	gut.p("Completed CardResource tests")

func before_each():
	# Setup runs before each test
	pass
	
func after_each():
	# Teardown runs after each test
	pass

func test_card_resource_exists():
	var script = load(CardResourcePath)
	assert_not_null(script, "CardResource script should exist")
	
	var resource = script.new()
	assert_not_null(resource, "Should be able to instantiate CardResource")

func test_create_card_resource_with_properties():
	var script = load(CardResourcePath)
	var card_resource = script.new()
	
	# Set basic properties
	card_resource.id = "test_ice"
	card_resource.title = "Test Ice"
	card_resource.card_type = "ice"
	card_resource.subtypes = ["barrier"]
	card_resource.cost = 2
	card_resource.faction = "corp"
	
	# Test that properties were set correctly
	assert_eq(card_resource.id, "test_ice", "Card ID should be set correctly")
	assert_eq(card_resource.title, "Test Ice", "Card title should be set correctly")
	assert_eq(card_resource.card_type, "ice", "Card type should be set correctly")
	assert_eq(card_resource.subtypes, ["barrier"], "Card subtypes should be set correctly")
	assert_eq(card_resource.cost, 2, "Card cost should be set correctly")
	assert_eq(card_resource.faction, "corp", "Card faction should be set correctly")

func test_create_from_dictionary():
	var script = load(CardResourcePath)
	var card_resource = script.new()
	
	var card_data = {
		"id": "corroder",
		"title": "Corroder",
		"type": "program",
		"subtype": ["icebreaker", "fracter"],
		"cost": 2,
		"memory_cost": 1,
		"strength": 2,
		"faction": "anarch",
		"text": "1[credit]: Break barrier subroutine.\n1[credit]: +1 strength until end of run."
	}
	
	card_resource.from_dictionary(card_data)
	
	assert_eq(card_resource.id, "corroder", "Card ID should be loaded from dictionary")
	assert_eq(card_resource.title, "Corroder", "Card title should be loaded from dictionary")
	assert_eq(card_resource.card_type, "program", "Card type should be loaded from dictionary")
	assert_eq(card_resource.subtypes.size(), 2, "Card should have 2 subtypes")
	assert_eq(card_resource.subtypes[0], "icebreaker", "First subtype should be icebreaker")
	assert_eq(card_resource.memory_cost, 1, "Memory cost should be loaded from dictionary")

func test_to_dictionary_conversion():
	var script = load(CardResourcePath)
	var card_resource = script.new()
	
	# Set properties
	card_resource.id = "test_program"
	card_resource.title = "Test Program"
	card_resource.card_type = "program"
	card_resource.subtypes = ["icebreaker", "killer"]
	card_resource.cost = 3
	card_resource.memory_cost = 2
	card_resource.strength = 1
	card_resource.faction = "criminal"
	card_resource.text = "This is a test program."
	
	var dict = card_resource.to_dictionary()
	
	assert_eq(dict.id, card_resource.id, "Dictionary ID should match resource ID")
	assert_eq(dict.title, card_resource.title, "Dictionary title should match resource title")
	assert_eq(dict.type, card_resource.card_type, "Dictionary type should match resource card_type")
	assert_eq(dict.subtype, card_resource.subtypes, "Dictionary subtype should match resource subtypes")
	assert_eq(dict.cost, card_resource.cost, "Dictionary cost should match resource cost")
	assert_eq(dict.memory_cost, card_resource.memory_cost, "Dictionary memory_cost should match resource memory_cost")

func test_validate_card_resource():
	var script = load(CardResourcePath)
	var card_resource = script.new()
	
	# Create an invalid card with no ID
	card_resource.title = "Invalid Card"
	
	assert_false(card_resource.is_valid(), "Card without ID should be invalid")
	
	# Set an ID and test again
	card_resource.id = "valid_card"
	assert_true(card_resource.is_valid(), "Card with ID should be valid")
	
	# Test other required fields
	card_resource.id = ""
	assert_false(card_resource.is_valid(), "Card with empty ID should be invalid")
	
	card_resource.id = "valid_card"
	card_resource.card_type = ""
	assert_false(card_resource.is_valid(), "Card with empty type should be invalid")
