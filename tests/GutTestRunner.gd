extends Node

# This is a simple test runner script for GUT

@onready var gut = $Gut

# Called when the node enters the scene tree for the first time
func _ready():
	# Configure GUT
	gut.set_yield_between_tests(true)
	gut.set_log_level(3) # Verbose log level
	
	# Run all tests
	gut.test_scripts()
