extends Control
class_name TestRunner

# Main test runner for End of Line
# This runs all tests in the appropriate sequence

signal tests_completed(success: bool)
signal test_progress(current: int, total: int)

var unit_tests = []
var integration_tests = []
var system_tests = []

var total_tests_passed = 0
var total_tests_failed = 0
var total_tests = 0
var current_test = 0

@onready var log_display = $VBoxContainer/ProgressDisplay/ScrollContainer/LogDisplay
@onready var progress_bar = $VBoxContainer/ProgressDisplay/ProgressBar
@onready var run_button = $VBoxContainer/Controls/RunButton
@onready var reset_button = $VBoxContainer/Controls/ResetButton

func _ready():
	# Register all test classes
	register_tests()
	
	# Calculate total tests
	total_tests = unit_tests.size() + integration_tests.size() + system_tests.size()
	
	# Set up progress bar
	progress_bar.max_value = total_tests
	progress_bar.value = 0

func register_tests():
	# Unit Tests
	if ResourceLoader.exists("res://tests/unit/test_card.gd"):
		unit_tests.append(load("res://tests/unit/test_card.gd").new())
	
	if ResourceLoader.exists("res://tests/unit/test_player.gd"):
		unit_tests.append(load("res://tests/unit/test_player.gd").new())
	
	if ResourceLoader.exists("res://tests/unit/test_deck.gd"):
		unit_tests.append(load("res://tests/unit/test_deck.gd").new())
	
	# Integration Tests
	if ResourceLoader.exists("res://tests/integration/test_card_player_interaction.gd"):
		integration_tests.append(load("res://tests/integration/test_card_player_interaction.gd").new())
	
	if ResourceLoader.exists("res://tests/integration/test_run_mechanics.gd"):
		integration_tests.append(load("res://tests/integration/test_run_mechanics.gd").new())
	
	# System Tests
	if ResourceLoader.exists("res://tests/system/test_game_flow.gd"):
		system_tests.append(load("res://tests/system/test_game_flow.gd").new())

func reset():
	# Reset test run data
	total_tests_passed = 0
	total_tests_failed = 0
	current_test = 0
	progress_bar.value = 0
	log_display.text = "Press \"Run All Tests\" to begin testing..."
	run_button.disabled = false

func run_all_tests():
	# Disable run button while tests are running
	run_button.disabled = true
	
	# Reset test data
	total_tests_passed = 0
	total_tests_failed = 0
	current_test = 0
	progress_bar.value = 0
	
	# Start logging
	log_display.clear()
	log_display.append_text("[color=cyan]Starting test run...[/color]\n")
	log_display.append_text("[color=cyan]=======================[/color]\n\n")
	
	var all_passed = true
	
	# Run unit tests
	log_display.append_text("[color=yellow]Running Unit Tests:[/color]\n")
	log_display.append_text("[color=yellow]------------------[/color]\n")
	for test in unit_tests:
		current_test += 1
		emit_signal("test_progress", current_test, total_tests)
		
		if test.has_method("setup"):
			test.setup()
		
		var test_name = test.test_name if test.has("test_name") else test.get_class()
		log_display.append_text("[b]" + test_name + "[/b]\n")
		
		var test_result = test.run_tests()
		
		if test.has_method("teardown"):
			test.teardown()
		
		# Update statistics
		total_tests_passed += test.tests_passed
		total_tests_failed += test.tests_failed
		
		if not test_result:
			all_passed = false
		
		log_display.append_text("\n")
	
	# Only run integration tests if unit tests pass
	if all_passed:
		log_display.append_text("[color=yellow]Running Integration Tests:[/color]\n")
		log_display.append_text("[color=yellow]-------------------------[/color]\n")
		for test in integration_tests:
			current_test += 1
			emit_signal("test_progress", current_test, total_tests)
			
			if test.has_method("setup"):
				test.setup()
			
			var test_name = test.test_name if test.has("test_name") else test.get_class()
			log_display.append_text("[b]" + test_name + "[/b]\n")
			
			var test_result = test.run_tests()
			
			if test.has_method("teardown"):
				test.teardown()
			
			# Update statistics
			total_tests_passed += test.tests_passed
			total_tests_failed += test.tests_failed
			
			if not test_result:
				all_passed = false
			
			log_display.append_text("\n")
		
		# Only run system tests if integration tests pass
		if all_passed:
			log_display.append_text("[color=yellow]Running System Tests:[/color]\n")
			log_display.append_text("[color=yellow]--------------------[/color]\n")
			for test in system_tests:
				current_test += 1
				emit_signal("test_progress", current_test, total_tests)
				
				if test.has_method("setup"):
					test.setup()
				
				var test_name = test.test_name if test.has("test_name") else test.get_class()
				log_display.append_text("[b]" + test_name + "[/b]\n")
				
				var test_result = test.run_tests()
				
				if test.has_method("teardown"):
					test.teardown()
				
				# Update statistics
				total_tests_passed += test.tests_passed
				total_tests_failed += test.tests_failed
				
				if not test_result:
					all_passed = false
				
				log_display.append_text("\n")
	
	# Output summary
	log_display.append_text("[color=cyan]=======================[/color]\n")
	log_display.append_text("[color=cyan]Test run complete.[/color]\n")
	log_display.append_text("Tests passed: [color=green]" + str(total_tests_passed) + "[/color]\n")
	log_display.append_text("Tests failed: [color=red]" + str(total_tests_failed) + "[/color]\n")
	log_display.append_text("Result: " + ("[color=green]PASSED[/color]" if all_passed else "[color=red]FAILED[/color]") + "\n")
	
	# Re-enable run button
	run_button.disabled = false
	
	emit_signal("tests_completed", all_passed)
	return all_passed

func _on_test_progress(current, total):
	# Update progress bar
	progress_bar.value = current

func _on_tests_completed(success):
	# Scroll to bottom of log
	log_display.scroll_to_line(log_display.get_line_count() - 1)
