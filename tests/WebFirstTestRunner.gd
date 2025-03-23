extends Node
class_name WebFirstTestRunner

# This is a specialized runner for the web-first TDD implementation tests

@onready var gut = $Gut

# Called when the node enters the scene tree for the first time
func _ready():
	# Configure GUT
	gut.set_yield_between_tests(true)
	gut.set_log_level(3) # Verbose log level
	
	# Add our test directories
	gut.add_directory("res://tests/unit/web_tests")
	gut.add_directory("res://tests/unit/card_tests")
	
	# Run tests
	gut.test_scripts()

# Run specific test script
func run_test_script(script_path: String) -> void:
	gut.test_script(script_path)

# Run tests for a specific class
func run_test_class(class_name: String) -> void:
	gut.test_scripts_with_filter(class_name)
