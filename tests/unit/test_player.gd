extends TestBase
class_name TestPlayer

var test_name = "Player Tests"

func run_tests():
	print("Running Player tests...")
	
	test_base_player_functionality()
	test_runner_player_functionality()
	test_corp_player_functionality()
	test_player_resource_management()
	test_deck_management()
	
	print("Player tests completed: ", tests_passed, " passed, ", tests_failed, " failed")
	return tests_failed == 0

func test_base_player_functionality():
	print("  Testing base player functionality...")
	
	# Create a player instance
	var player = Player.new()
	
	# Initialize player
	player.player_id = "test_player"
	player.player_name = "Test Player"
	
	# Test initialization
	if assert_eq(player.player_id, "test_player", "Player ID should be set"):
		_log_success("Player ID initialization")
	
	if assert_eq(player.player_name, "Test Player", "Player name should be set"):
		_log_success("Player name initialization")
	
	# Test resource management
	player.credits = 0
	player.modify_credits(5)
	
	if assert_eq(player.credits, 5, "Player should have 5 credits after modification"):
		_log_success("Credit modification")
	
	# Test click management
	player.clicks = 0
	player.add_clicks(4)
	
	if assert_eq(player.clicks, 4, "Player should have 4 clicks after addition"):
		_log_success("Click addition")
	
	var result = player.spend_click()
	
	if assert_true(result, "Spending a click should succeed"):
		_log_success("Click spending success")
	
	if assert_eq(player.clicks, 3, "Player should have 3 clicks after spending"):
		_log_success("Click spending amount")
	
	player.spend_all_clicks()
	
	if assert_eq(player.clicks, 0, "Player should have 0 clicks after spending all"):
		_log_success("Spend all clicks")
	
	# Test card drawing
	var card1 = Card.new()
	card1.id = "card1"
	var card2 = Card.new()
	card2.id = "card2"
	
	player.deck = [card1, card2]
	
	var drawn_card = player.draw_card()
	
	if assert_eq(drawn_card.id, "card1", "Drawn card should be first card"):
		_log_success("Draw card identification")
	
	if assert_eq(player.hand.size(), 1, "Hand should have 1 card after drawing"):
		_log_success("Hand size after draw")
	
	if assert_eq(player.deck.size(), 1, "Deck should have 1 card after drawing"):
		_log_success("Deck size after draw")
	
	# Test card discarding
	var discard_result = player.discard_card(0)
	
	if assert_true(discard_result, "Discarding should succeed"):
		_log_success("Discard success")
	
	if assert_eq(player.hand.size(), 0, "Hand should be empty after discard"):
		_log_success("Hand size after discard")
	
	if assert_eq(player.discard_pile.size(), 1, "Discard pile should have 1 card"):
		_log_success("Discard pile size")
	
	if assert_eq(player.discard_pile[0].id, "card1", "Discarded card should be in discard pile"):
		_log_success("Discard pile content")

func test_runner_player_functionality():
	print("  Testing runner player functionality...")
	
	# Create a runner player
	var runner = RunnerPlayer.new()
	
	# Test initialization
	if assert_eq(runner.player_type, Player.PlayerType.RUNNER, "Player type should be RUNNER"):
		_log_success("Runner player type")
	
	if assert_eq(runner.faction, "runner", "Runner faction should be 'runner'"):
		_log_success("Runner faction")
	
	# Test memory management
	if assert_eq(runner.memory_limit, 4, "Runner should start with 4 memory"):
		_log_success("Initial memory limit")
	
	if assert_eq(runner.memory_used, 0, "Runner should start with 0 memory used"):
		_log_success("Initial memory usage")
	
	# Test tag management
	if assert_eq(runner.tags, 0, "Runner should start with 0 tags"):
		_log_success("Initial tags")
	
	runner.add_tag(2)
	
	if assert_eq(runner.tags, 2, "Runner should have 2 tags after adding"):
		_log_success("Tag addition")
	
	runner.remove_tag(1)
	
	if assert_eq(runner.tags, 1, "Runner should have 1 tag after removing"):
		_log_success("Tag removal")
	
	# Test program installation
	var program = Card.new()
	program.id = "test_program"
	program.card_type = "program"
	program.cost = 3
	program.memory_cost = 1
	
	runner.credits = 5
	var install_result = runner.install_card(program)
	
	if assert_true(install_result, "Program installation should succeed"):
		_log_success("Program installation success")
	
	if assert_eq(runner.credits, 2, "Runner should have 2 credits after installation"):
		_log_success("Credits after installation")
	
	if assert_eq(runner.installed_programs.size(), 1, "Runner should have 1 installed program"):
		_log_success("Installed programs count")
	
	if assert_eq(runner.memory_used, 1, "Runner should use 1 memory"):
		_log_success("Memory usage after installation")
	
	# Test hardware installation
	var hardware = Card.new()
	hardware.id = "test_hardware"
	hardware.card_type = "hardware"
	hardware.cost = 2
	hardware.card_subtype = ["console"]
	hardware.effect = {"modify_memory": 2}
	
	install_result = runner.install_card(hardware)
	
	if assert_true(install_result, "Hardware installation should succeed"):
		_log_success("Hardware installation success")
	
	if assert_eq(runner.installed_hardware.size(), 1, "Runner should have 1 installed hardware"):
		_log_success("Installed hardware count")
	
	# Test memory modification from hardware
	runner.calculate_memory_used()
	
	if assert_eq(runner.memory_used, 1, "Memory usage should still be 1 after console installation"):
		_log_success("Memory usage after hardware installation")
	
	if assert_eq(runner.memory_limit, 4, "Memory limit should still be base limit"):
		_log_success("Memory limit after hardware installation")
	
	# Test run initiation
	runner.clicks = 3
	var run_result = runner.initiate_run("hq")
	
	if assert_true(run_result, "Run initiation should succeed"):
		_log_success("Run initiation success")
	
	if assert_eq(runner.clicks, 2, "Runner should have 2 clicks after initiating run"):
		_log_success("Clicks after run initiation")
	
	if assert_not_null(runner.current_run, "Runner should have a current run"):
		_log_success("Current run after initiation")
	
	if assert_eq(runner.current_run.server_id, "hq", "Run target should be HQ"):
		_log_success("Run target identification")

func test_corp_player_functionality():
	print("  Testing corp player functionality...")
	
	# Create a corp player
	var corp = CorpPlayer.new()
	
	# Test initialization
	if assert_eq(corp.player_type, Player.PlayerType.CORP, "Player type should be CORP"):
		_log_success("Corp player type")
	
	if assert_eq(corp.faction, "corp", "Corp faction should be 'corp'"):
		_log_success("Corp faction")
	
	# Test bad publicity
	if assert_eq(corp.bad_publicity, 0, "Corp should start with 0 bad publicity"):
		_log_success("Initial bad publicity")
	
	corp.add_bad_publicity(1)
	
	if assert_eq(corp.bad_publicity, 1, "Corp should have 1 bad publicity after adding"):
		_log_success("Bad publicity addition")
	
	corp.remove_bad_publicity(1)
	
	if assert_eq(corp.bad_publicity, 0, "Corp should have 0 bad publicity after removing"):
		_log_success("Bad publicity removal")
	
	# Test central servers
	if assert_eq(corp.hq.server_id, "hq", "HQ server ID should be 'hq'"):
		_log_success("HQ server creation")
	
	if assert_eq(corp.rd.server_id, "rd", "R&D server ID should be 'rd'"):
		_log_success("R&D server creation")
	
	if assert_eq(corp.archives.server_id, "archives", "Archives server ID should be 'archives'"):
		_log_success("Archives server creation")
	
	# Test remote server creation
	var remote_server = corp.create_remote_server()
	
	if assert_eq(corp.remote_servers.size(), 1, "Corp should have 1 remote server"):
		_log_success("Remote server creation count")
	
	if assert_eq(remote_server.server_id, "remote_1", "Remote server ID should be 'remote_1'"):
		_log_success("Remote server ID")
	
	# Test ice installation
	var ice = Card.new()
	ice.id = "test_ice"
	ice.card_type = "ice"
	
	var install_result = corp.install_card(ice, remote_server)
	
	if assert_true(install_result, "Ice installation should succeed"):
		_log_success("Ice installation success")
	
	if assert_eq(remote_server.ice.size(), 1, "Remote server should have 1 ice"):
		_log_success("Installed ice count")
	
	# Test agenda installation
	var agenda = Card.new()
	agenda.id = "test_agenda"
	agenda.card_type = "agenda"
	agenda.cost = 2
	agenda.advancement_requirement = 3
	agenda.agenda_points = 2
	
	corp.credits = 5
	install_result = corp.install_card(agenda, remote_server)
	
	if assert_true(install_result, "Agenda installation should succeed"):
		_log_success("Agenda installation success")
	
	if assert_eq(corp.credits, 3, "Corp should have 3 credits after installation"):
		_log_success("Credits after installation")
	
	if assert_eq(remote_server.content.size(), 1, "Remote server should have 1 content card"):
		_log_success("Server content count")
	
	# Test agenda advancement
	corp.credits = 5
	corp.clicks = 3
	var advance_result = corp.advance_card(agenda)
	
	if assert_true(advance_result, "Agenda advancement should succeed"):
		_log_success("Agenda advancement success")
	
	if assert_eq(corp.credits, 4, "Corp should have 4 credits after advancement"):
		_log_success("Credits after advancement")
	
	if assert_eq(corp.clicks, 2, "Corp should have 2 clicks after advancement"):
		_log_success("Clicks after advancement")
	
	if assert_eq(agenda.advancement_tokens, 1, "Agenda should have 1 advancement token"):
		_log_success("Advancement token count")
	
	# Advance to scoring threshold
	corp.advance_card(agenda)
	corp.advance_card(agenda)
	
	if assert_eq(agenda.advancement_tokens, 3, "Agenda should have 3 advancement tokens"):
		_log_success("Advancement threshold reached")
	
	# Test agenda scoring
	var score_result = corp.score_agenda(agenda)
	
	if assert_true(score_result, "Agenda scoring should succeed"):
		_log_success("Agenda scoring success")
	
	if assert_eq(corp.scored_agendas.size(), 1, "Corp should have 1 scored agenda"):
		_log_success("Scored agenda count")
	
	if assert_eq(remote_server.content.size(), 0, "Remote server should be empty after scoring"):
		_log_success("Server content after scoring")

func test_player_resource_management():
	print("  Testing player resource management...")
	
	# Create a player
	var player = Player.new()
	
	# Test credit signals
	var credit_change_detected = false
	player.connect("credits_changed", func(amount): credit_change_detected = true)
	
	player.modify_credits(3)
	
	if assert_true(credit_change_detected, "Credits changed signal should be emitted"):
		_log_success("Credits changed signal")
	
	# Test click signals
	var click_change_detected = false
	player.connect("clicks_changed", func(amount): click_change_detected = true)
	
	player.add_clicks(3)
	
	if assert_true(click_change_detected, "Clicks changed signal should be emitted"):
		_log_success("Clicks changed signal")
	
	click_change_detected = false
	player.spend_click()
	
	if assert_true(click_change_detected, "Clicks changed signal should be emitted on spend"):
		_log_success("Clicks changed signal on spend")
	
	# Test edge cases
	player.clicks = 0
	var result = player.spend_click()
	
	if assert_false(result, "Spending a click with 0 clicks should fail"):
		_log_success("Click spending failure")
	
	if assert_eq(player.clicks, 0, "Clicks should remain 0 after failed spend"):
		_log_success("Clicks after failed spend")

func test_deck_management():
	print("  Testing deck management...")
	
	# Create a player
	var player = Player.new()
	
	# Create a deck
	var card1 = Card.new()
	card1.id = "card1"
	var card2 = Card.new()
	card2.id = "card2"
	var card3 = Card.new()
	card3.id = "card3"
	
	player.deck = [card1, card2, card3]
	
	if assert_eq(player.deck.size(), 3, "Deck should have 3 cards"):
		_log_success("Initial deck size")
	
	# Test deck shuffling
	player.shuffle_deck()
	
	if assert_eq(player.deck.size(), 3, "Deck should still have 3 cards after shuffling"):
		_log_success("Deck size after shuffle")
	
	# Test drawing cards
	var card_draw_detected = false
	player.connect("card_drawn", func(card): card_draw_detected = true)
	
	var drawn_card = player.draw_card()
	
	if assert_true(card_draw_detected, "Card drawn signal should be emitted"):
		_log_success("Card drawn signal")
	
	if assert_eq(player.deck.size(), 2, "Deck should have 2 cards after drawing"):
		_log_success("Deck size after draw")
	
	if assert_eq(player.hand.size(), 1, "Hand should have 1 card after drawing"):
		_log_success("Hand size after draw")
	
	# Test drawing the entire deck
	player.draw_card()
	player.draw_card()
	
	if assert_eq(player.deck.size(), 0, "Deck should be empty after drawing all cards"):
		_log_success("Empty deck after drawing all")
	
	if assert_eq(player.hand.size(), 3, "Hand should have 3 cards after drawing all"):
		_log_success("Hand size after drawing all")
	
	# Test drawing from empty deck
	var empty_draw = player.draw_card()
	
	if assert_null(empty_draw, "Drawing from empty deck should return null"):
		_log_success("Draw from empty deck")
	
	# Test discard pile management
	player.discard_card(0)
	player.discard_card(0)
	player.discard_card(0)
	
	if assert_eq(player.hand.size(), 0, "Hand should be empty after discarding all"):
		_log_success("Empty hand after discarding all")
	
	if assert_eq(player.discard_pile.size(), 3, "Discard pile should have 3 cards"):
		_log_success("Discard pile size after discarding all")
	
	# Test initialize method
	var id = "test_player_id"
	var name = "Test Player Name"
	var deck_data = [
		{ "id": "test_card_1", "count": 2 },
		{ "id": "test_identity", "count": 1 }
	]
	
	# Register mock cards in the card database to enable initialization
	CardDatabase.cards = {
		"test_card_1": {
			"id": "test_card_1",
			"title": "Test Card",
			"type": "ice"
		},
		"test_identity": {
			"id": "test_identity",
			"title": "Test Identity",
			"type": "identity"
		}
	}
	
	# Call initialize
	player.initialize(id, name, deck_data)
	
	if assert_eq(player.player_id, id, "Player ID should be set after initialization"):
		_log_success("Player ID after initialization")
	
	if assert_eq(player.player_name, name, "Player name should be set after initialization"):
		_log_success("Player name after initialization")
	
	if assert_not_null(player.identity_card, "Identity card should be set after initialization"):
		_log_success("Identity card after initialization")
	
	if assert_eq(player.deck.size(), 2, "Deck should have 2 cards after initialization"):
		_log_success("Deck size after initialization")
	
	if assert_eq(player.credits, player.starting_credits, "Credits should be set to starting value"):
		_log_success("Credits after initialization")
