extends Node

# Unit tests for the Card class

class_name TestCard

var card_tests_passed = 0
var card_tests_failed = 0

func run_tests():
    print("Running Card tests...")
    
    test_card_creation()
    test_card_data_conversion()
    test_strength_modifiers()
    test_hosted_counters()
    test_hosting_cards()
    test_location_tracking()
    test_ice_interaction()
    
    print("Card tests complete: ", card_tests_passed, " passed, ", card_tests_failed, " failed")
    return card_tests_failed == 0

func test_card_creation():
    print("  Testing card creation...")
    
    # Test basic card creation
    var card = Card.new()
    TestConfig.assert_true(card != null, "Card should be created")
    
    # Test card creation with data
    var data = {
        "id": "test_card",
        "title": "Test Card",
        "type": "ice",
        "subtype": ["barrier"],
        "cost": 3,
        "strength": 2,
        "rez_cost": 3
    }
    
    var card_from_data = Card.new(data)
    TestConfig.assert_eq(card_from_data.id, "test_card", "Card ID should match data")
    TestConfig.assert_eq(card_from_data.title, "Test Card", "Card title should match data")
    TestConfig.assert_eq(card_from_data.card_type, "ice", "Card type should match data")
    TestConfig.assert_eq(card_from_data.card_subtype.size(), 1, "Card should have 1 subtype")
    TestConfig.assert_eq(card_from_data.card_subtype[0], "barrier", "Card subtype should be 'barrier'")
    TestConfig.assert_eq(card_from_data.cost, 3, "Card cost should match data")
    TestConfig.assert_eq(card_from_data.strength, 2, "Card strength should match data")
    TestConfig.assert_eq(card_from_data.rez_cost, 3, "Card rez cost should match data")
    
    # Test subtype handling for string input (non-array)
    var data_with_string_subtype = {
        "id": "test_card2",
        "title": "Test Card 2",
        "type": "ice",
        "subtype": "barrier",
        "cost": 2
    }
    
    var card_with_string_subtype = Card.new(data_with_string_subtype)
    TestConfig.assert_eq(card_with_string_subtype.card_subtype.size(), 1, "Card should convert string subtype to array")
    TestConfig.assert_eq(card_with_string_subtype.card_subtype[0], "barrier", "Card subtype should be 'barrier'")
    
    card_tests_passed += 1

func test_card_data_conversion():
    print("  Testing card data conversion...")
    
    # Create a card
    var card = Card.new()
    card.id = "test_card"
    card.title = "Test Card"
    card.card_type = "ice"
    card.card_subtype = ["barrier"]
    card.cost = 3
    card.strength = 2
    card.rez_cost = 3
    
    # Convert to data
    var data = card.to_data()
    
    # Test data fields
    TestConfig.assert_eq(data.id, "test_card", "Data ID should match card")
    TestConfig.assert_eq(data.title, "Test Card", "Data title should match card")
    TestConfig.assert