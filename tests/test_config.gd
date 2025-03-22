extends Node

# Test configuration and utilities for End of Line test suite

class_name TestConfig

# Constants
const SKIP_LONG_TESTS = false
const TEST_TIMEOUT = 10  # seconds

static func create_mock_card(id, title, type, cost=0):
    """
    Creates a mock card for testing
    """
    var card = Card.new()
    card.id = id
    card.title = title
    card.card_type = type
    card.cost = cost
    return card

static func create_mock_player(player_type, id="test_player", name="Test Player"):
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

static func create_mock_deck(player_type):
    """
    Creates a mock deck for testing
    """
    var cards = []
    
    if player_type == Player.PlayerType.CORP:
        cards.append(create_mock_card("test_agenda", "Test Agenda", "agenda", 3))
        cards.append(create_mock_card("test_ice", "Test Ice", "ice", 2))
        cards.append(create_mock_card("test_asset", "Test Asset", "asset", 1))
        cards.append(create_mock_card("test_operation", "Test Operation", "operation", 1))
    else:
        cards.append(create_mock_card("test_program", "Test Program", "program", 3))
        cards.append(create_mock_card("test_hardware", "Test Hardware", "hardware", 2))
        cards.append(create_mock_card("test_resource", "Test Resource", "resource", 1))
        cards.append(create_mock_card("test_event", "Test Event", "event", 1))
    
    return cards

static func assert_eq(a, b, message=""):
    """
    Assert that two values are equal
    """
    if a != b:
        if message:
            push_error(message + ": " + str(a) + " != " + str(b))
        else:
            push_error("Assertion failed: " + str(a) + " != " + str(b))
        return false
    return true

static func assert_true(condition, message=""):
    """
    Assert that a condition is true
    """
    if not condition:
        if message:
            push_error(message)
        else:
            push_error("Assertion failed: Expected true but got false")
        return false
    return true

static func assert_false(condition, message=""):
    """
    Assert that a condition is false
    """
    if condition:
        if message:
            push_error(message)
        else:
            push_error("Assertion failed: Expected false but got true")
        return false
    return true
