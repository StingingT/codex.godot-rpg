extends Area2D
class_name ItemPickup

@export var item_id: String = ""
@export var quantity: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var bob_offset: float = 0.0
var bob_speed: float = 3.0
var bob_height: float = 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Start bobbing animation using the configured variables
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - bob_height, 0.5 / bob_speed)
	tween.tween_property(self, "position:y", position.y + bob_height, 0.5 / bob_speed)

func _on_body_entered(body: Node2D):
	if body is Player:
		var player = body as Player
		
		# Load item data and add to inventory
		var item = _load_item_data(item_id)
		if item and player.inventory:
			if player.inventory.add_item(item, quantity):
				# Emit signal for quests and audio
				GameManager.item_picked_up.emit(item_id, quantity)
				
				# Show pickup text
				_show_pickup_text(item.item_name)
			else:
				# Inventory full - don't pick up
				return
		else:
			# Just emit signal for quest items that don't have actual item data
			GameManager.item_picked_up.emit(item_id, quantity)
			_show_pickup_text(item_id)
		
		queue_free()

func _load_item_data(load_id: String) -> ItemData:
	# Use the same loading logic as inventory system
	var file_path = "res://data/items/" + load_id + ".json"
	if not FileAccess.file_exists(file_path):
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		return null
	
	var data = json.data
	var item_type = data.get("item_type", 0)
	
	var item: ItemData
	
	# Check if it's a weapon
	if item_type == 0 or data.has("weapon_type"):
		var weapon = WeaponData.new()
		weapon.weapon_type = data.get("weapon_type", 0)
		weapon.damage = data.get("damage", 10)
		weapon.attack_speed = data.get("attack_speed", 1.0)
		weapon.knockback = data.get("knockback", 100.0)
		item = weapon
	else:
		item = ItemData.new()
	
	# Common properties
	item.item_id = data.get("item_id", load_id)
	item.item_name = data.get("item_name", "Unknown")
	item.description = data.get("description", "")
	item.item_type = item_type
	item.required_level = data.get("required_level", 1)
	item.buy_price = data.get("buy_price", 100)
	item.sell_price = data.get("sell_price", 50)
	item.stackable = data.get("stackable", false)
	item.max_stack = data.get("max_stack", 1)
	
	# Try to load sprite
	var sprite_path = "res://assets/sprites/weapons/" + load_id + ".png"
	if ResourceLoader.exists(sprite_path):
		item.sprite = load(sprite_path)
	
	return item

func _show_pickup_text(item_name: String):
	var label = Label.new()
	label.text = "+ %s" % item_name
	label.position = global_position
	get_tree().current_scene.add_child(label)
	
	# Auto-remove after 1 second
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)
	
	# Animate while visible
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
