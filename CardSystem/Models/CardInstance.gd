extends RefCounted
class_name CardInstance

# The card resource this instance is based on
var _resource: CardResource

# State information
var _zone: String = "deck"
var _installed: bool = false
var _rezzed: bool = false
var _faceup: bool = false
var _controller_id: String = ""
var _owner_id: String = ""
var _position: Vector2 = Vector2.ZERO
var _host: CardInstance = null
var _hosted_cards: Array[CardInstance] = []
var _counters: Dictionary = {}
var _strength_modifier: int = 0

func _init(card_resource: CardResource):
	_resource = card_resource

# Getters for card resource properties
func get_id() -> String:
	return _resource.id
	
func get_title() -> String:
	return _resource.title
	
func get_card_type() -> String:
	return _resource.card_type
	
func get_subtypes() -> Array:
	return _resource.subtypes
	
func get_faction() -> String:
	return _resource.faction

func get_cost() -> int:
	return _resource.cost

func get_text() -> String:
	return _resource.text
	
func get_strength() -> int:
	var base_strength = _resource.strength if _resource.strength else 0
	return max(0, base_strength + _strength_modifier)

# State management
func set_zone(zone: String) -> void:
	_zone = zone
	
func get_zone() -> String:
	return _zone
	
func set_installed(value: bool) -> void:
	_installed = value
	
func is_installed() -> bool:
	return _installed
	
func set_rezzed(value: bool) -> void:
	_rezzed = value
	
func is_rezzed() -> bool:
	return _rezzed
	
func set_controller(player_id: String) -> void:
	_controller_id = player_id
	
func get_controller() -> String:
	return _controller_id
	
func set_owner(player_id: String) -> void:
	_owner_id = player_id
	
func get_owner() -> String:
	return _owner_id

# Counter management
func add_counter(counter_type: String, amount: int = 1) -> void:
	if not _counters.has(counter_type):
		_counters[counter_type] = 0
	
	_counters[counter_type] += amount
	
func remove_counter(counter_type: String, amount: int = 1) -> bool:
	if not _counters.has(counter_type):
		return false
	
	_counters[counter_type] = max(0, _counters[counter_type] - amount)
	if _counters[counter_type] == 0:
		_counters.erase(counter_type)
	
	return true
	
func get_counter(counter_type: String) -> int:
	return _counters.get(counter_type, 0)

# Strength modification
func add_strength_modifier(amount: int) -> void:
	_strength_modifier += amount
	
func reset_strength_modifiers() -> void:
	_strength_modifier = 0

# Hosting
func host_card(card: CardInstance) -> void:
	_hosted_cards.append(card)
	card._host = self
	
func get_hosted_cards() -> Array[CardInstance]:
	return _hosted_cards
	
func get_host() -> CardInstance:
	return _host
