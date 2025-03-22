extends TestBase
class_name TestCard

var test_name = "Card Tests"

func run_tests():
	print("Running Card tests...")
	
	test_card_creation()
	test_card_data_conversion()
	test_card_type_identification()
	test_strength_modification()
	test_counters()
	test_card_hosting()
	test_location_tracking()
	test_icebreaker_interaction()
	
	print("Card tests completed: ", tests_passed, " passed, ", tests_failed, " failed")
	return tests_failed == 0

func test_card_creation():
	print("  Testing card creation...")
	
	# Test creating an empty card
	var card = Card.new()
	if assert_not_null(card, "Card should be instantiated"):
		_log_success("Card instantiation")
	
	# Test creating a card with initial data
	var card_data = {
		"id": "test_ice",
		"title": "Test Ice",
		"type": "ice",
		"subtype": ["barrier"],
		"cost": 2,
		"strength": 3,
		"rez_cost": 3,
		"text": "End the run."
	}
	
	var ice_card = Card.new(card_data)
	
	if assert_eq(ice_card.id, "test_ice", "Card ID should be set from data"):
		_log_success("Card ID initialization")
	
	if assert_eq(ice_card.title, "Test Ice", "Card title should be set from data"):
		_log_success("Card title initialization")
	
	if assert_eq(ice_card.card_type, "ice", "Card type should be set from data"):
		_log_success("Card type initialization")
	
	if assert_eq(ice_card.card_subtype.size(), 1, "Card should have one subtype"):
		_log_success("Card subtype array initialization")
	
	if assert_eq(ice_card.card_subtype[0], "barrier", "Card subtype should match data"):
		_log_success("Card subtype content initialization")
	
	if assert_eq(ice_card.cost, 2, "Card cost should be set from data"):
		_log_success("Card cost initialization")
	
	if assert_eq(ice_card.strength, 3, "Card strength should be set from data"):
		_log_success("Card strength initialization")
	
	if assert_eq(ice_card.rez_cost, 3, "Card rez cost should be set from data"):
		_log_success("Card rez cost initialization")

func test_card_data_conversion():
	print("  Testing card data conversion...")
	
	# Create a card with properties
	var card = Card.new()
	card.id = "test_program"
	card.title = "Test Program"
	card.card_type = "program"
	card.card_subtype = ["icebreaker", "fracter"]
	card.cost = 3
	card.memory_cost = 1
	card.strength = 2
	
	# Convert to data
	var data = card.to_data()
	
	# Verify the conversion
	if assert_eq(data.id, "test_program", "Data ID should match card ID"):
		_log_success("Card to data ID conversion")
	
	if assert_eq(data.title, "Test Program", "Data title should match card title"):
		_log_success("Card to data title conversion")
	
	if assert_eq(data.type, "program", "Data type should match card type"):
		_log_success("Card to data type conversion")
	
	if assert_eq(data.subtype, ["icebreaker", "fracter"], "Data subtype should match card subtype"):
		_log_success("Card to data subtype conversion")
	
	if assert_eq(data.cost, 3, "Data cost should match card cost"):
		_log_success("Card to data cost conversion")
	
	if assert_eq(data.memory_cost, 1, "Data memory cost should match card memory cost"):
		_log_success("Card to data memory cost conversion")
	
	if assert_eq(data.strength, 2, "Data strength should match card strength"):
		_log_success("Card to data strength conversion")
	
	# Create a new card from the data
	var new_card = Card.new(data)
	
	# Verify the new card has the same properties
	if assert_eq(new_card.id, card.id, "New card ID should match original"):
		_log_success("Data to card ID conversion")
	
	if assert_eq(new_card.title, card.title, "New card title should match original"):
		_log_success("Data to card title conversion")
	
	if assert_eq(new_card.card_type, card.card_type, "New card type should match original"):
		_log_success("Data to card type conversion")
	
	if assert_eq(new_card.card_subtype, card.card_subtype, "New card subtype should match original"):
		_log_success("Data to card subtype conversion")

func test_card_type_identification():
	print("  Testing card type identification...")
	
	# Test corp card identification
	var ice_card = Card.new()
	ice_card.card_type = "ice"
	
	if assert_true(ice_card.is_corp_card(), "Ice should be identified as corp card"):
		_log_success("Corp card identification - ice")
	
	if assert_false(ice_card.is_runner_card(), "Ice should not be identified as runner card"):
		_log_success("Corp card non-runner check - ice")
	
	var agenda_card = Card.new()
	agenda_card.card_type = "agenda"
	
	if assert_true(agenda_card.is_corp_card(), "Agenda should be identified as corp card"):
		_log_success("Corp card identification - agenda")
	
	# Test runner card identification
	var program_card = Card.new()
	program_card.card_type = "program"
	
	if assert_true(program_card.is_runner_card(), "Program should be identified as runner card"):
		_log_success("Runner card identification - program")
	
	if assert_false(program_card.is_corp_card(), "Program should not be identified as corp card"):
		_log_success("Runner card non-corp check - program")
	
	var event_card = Card.new()
	event_card.card_type = "event"
	
	if assert_true(event_card.is_runner_card(), "Event should be identified as runner card"):
		_log_success("Runner card identification - event")

func test_strength_modification():
	print("  Testing card strength modification...")
	
	# Create a card with a base strength
	var card = Card.new()
	card.strength = 3
	
	# Test initial strength
	if assert_eq(card.get_total_strength(), 3, "Initial strength should match base strength"):
		_log_success("Initial strength check")
	
	# Add a strength modifier
	card.add_strength_modifier(2)
	
	if assert_eq(card.get_total_strength(), 5, "Strength should include modifier"):
		_log_success("Positive strength modifier")
	
	# Add negative strength modifier (with minimum 0 check)
	card.add_strength_modifier(-6)
	
	if assert_eq(card.current_strength_mod, -4, "Strength modifier should be cumulative"):
		_log_success("Cumulative strength modifier")
	
	# Strength should never go below 0
	if assert_eq(card.get_total_strength(), 0, "Total strength should never go below 0"):
		_log_success("Minimum strength check")

func test_counters():
	print("  Testing card counters...")
	
	# Create a card
	var card = Card.new()
	
	# Add a counter
	card.add_counter("virus")
	
	if assert_eq(card.get_counter("virus"), 1, "Should have 1 virus counter"):
		_log_success("Basic counter addition")
	
	# Add more counters
	card.add_counter("virus", 3)
	
	if assert_eq(card.get_counter("virus"), 4, "Should have 4 virus counters"):
		_log_success("Multiple counter addition")
	
	# Add a different type of counter
	card.add_counter("power", 2)
	
	if assert_eq(card.get_counter("power"), 2, "Should have 2 power counters"):
		_log_success("Multiple counter types")
	
	# Remove counters
	var removed = card.remove_counter("virus", 2)
	
	if assert_true(removed, "Counter removal should succeed"):
		_log_success("Counter removal return value")
	
	if assert_eq(card.get_counter("virus"), 2, "Should have 2 virus counters after removal"):
		_log_success("Counter removal amount")
	
	# Remove all remaining counters
	card.remove_counter("virus", 2)
	
	if assert_eq(card.get_counter("virus"), 0, "Should have 0 virus counters after removal"):
		_log_success("Complete counter removal")
	
	# Try to remove from non-existent counter type
	removed = card.remove_counter("advancement")
	
	if assert_false(removed, "Removing non-existent counter should fail"):
		_log_success("Non-existent counter removal")

func test_card_hosting():
	print("  Testing card hosting...")
	
	# Create host and hosted cards
	var host_card = Card.new()
	host_card.id = "host_card"
	host_card.title = "Host Card"
	
	var hosted_card = Card.new()
	hosted_card.id = "hosted_card"
	hosted_card.title = "Hosted Card"
	
	# Initially, host should have no hosted cards
	if assert_eq(host_card.get_hosted_cards().size(), 0, "Host should start with no hosted cards"):
		_log_success("Initial hosted cards check")
	
	# Host a card
	host_card.host_card(hosted_card)
	
	if assert_eq(host_card.get_hosted_cards().size(), 1, "Host should have one hosted card"):
		_log_success("Host card count after hosting")
	
	if assert_eq(host_card.get_hosted_cards()[0].id, "hosted_card", "Hosted card ID should match"):
		_log_success("Hosted card identification")
	
	# Check the hosted card's location
	if assert_true(hosted_card.location.has("host"), "Hosted card location should reference host"):
		_log_success("Hosted card location type")
	
	if assert_eq(hosted_card.location.host, host_card, "Hosted card location should reference correct host"):
		_log_success("Hosted card location reference")
	
	# Host multiple cards
	var second_hosted_card = Card.new()
	second_hosted_card.id = "second_hosted_card"
	second_hosted_card.title = "Second Hosted Card"
	
	host_card.host_card(second_hosted_card)
	
	if assert_eq(host_card.get_hosted_cards().size(), 2, "Host should have two hosted cards"):
		_log_success("Multiple hosted cards")

func test_location_tracking():
	print("  Testing card location tracking...")
	
	# Create a card
	var card = Card.new()
	
	# Initially location should be empty
	if assert_true(card.location.is_empty(), "Card should start with empty location"):
		_log_success("Initial location check")
	
	# Set location to hand
	card.set_location({"zone": "hand"})
	
	if assert_eq(card.get_location_string(), "Hand", "Location string should be 'Hand'"):
		_log_success("Hand location string")
	
	# Set location to server
	card.set_location({"zone": "server", "server": "hq"})
	
	if assert_true(card.location.has("server"), "Location should have server key"):
		_log_success("Server location data")
	
	if assert_eq(card.location.server, "hq", "Server should be 'hq'"):
		_log_success("Server location value")
	
	# Test various other locations
	card.set_location({"zone": "deck"})
	if assert_eq(card.get_location_string(), "Deck", "Location string should be 'Deck'"):
		_log_success("Deck location string")
	
	card.set_location({"zone": "discard"})
	if assert_eq(card.get_location_string(), "Discard pile", "Location string should be 'Discard pile'"):
		_log_success("Discard location string")
	
	card.set_location({"zone": "play-area"})
	if assert_eq(card.get_location_string(), "Play area", "Location string should be 'Play area'"):
		_log_success("Play area location string")

func test_icebreaker_interaction():
	print("  Testing icebreaker interaction with ice...")
	
	# Create an ice card
	var ice = Card.new()
	ice.id = "test_barrier"
	ice.card_type = "ice"
	ice.card_subtype = ["barrier"]
	ice.strength = 3
	
	# Create an icebreaker card
	var icebreaker = Card.new()
	icebreaker.id = "test_fracter"
	icebreaker.card_type = "program"
	icebreaker.card_subtype = ["icebreaker", "fracter"]
	icebreaker.strength = 2
	icebreaker.effect = {
		"break_subroutine": {"cost": 1, "ice_type": "barrier"},
		"boost_strength": {"cost": 1, "amount": 1}
	}
	
	# Test icebreaker subtype checking
	if assert_true(icebreaker.can_break_subtype(ice.card_subtype), "Fracter should be able to break barrier"):
		_log_success("Icebreaker subtype matching")
	
	# Create a different ice subtype
	var code_gate = Card.new()
	code_gate.card_type = "ice"
	code_gate.card_subtype = ["code gate"]
	
	if assert_false(icebreaker.can_break_subtype(code_gate.card_subtype), "Fracter should not be able to break code gate"):
		_log_success("Icebreaker subtype non-matching")
	
	# Create an AI breaker
	var ai_breaker = Card.new()
	ai_breaker.card_type = "program"
	ai_breaker.card_subtype = ["icebreaker", "ai"]
	ai_breaker.effect = {
		"break_subroutine": {"cost": 2, "ice_type": "all"}
	}
	
	if assert_true(ai_breaker.can_break_subtype(ice.card_subtype), "AI breaker should be able to break barrier"):
		_log_success("AI breaker barrier check")
	
	if assert_true(ai_breaker.can_break_subtype(code_gate.card_subtype), "AI breaker should be able to break code gate"):
		_log_success("AI breaker code gate check")
	
	# Test break costs
	if assert_eq(icebreaker.get_break_cost("barrier"), 1, "Break cost should be 1 credit"):
		_log_success("Break cost check")
	
	# Test boost costs
	if assert_eq(icebreaker.get_boost_strength_cost(), 1, "Boost cost should be 1 credit"):
		_log_success("Boost cost check")
