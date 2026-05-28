extends Area2D
class_name ItemPickup

@export var item_id: String = ""
@export var quantity: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var bob_offset: float = 0.0
var bob_speed: float = 3.0
var bob_height: float = 3.0
var player_in_range: Player = null
var is_picked_up: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_placeholder_marker()
	
	# Start bobbing animation using the configured variables
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - bob_height, 0.5 / bob_speed)
	tween.tween_property(self, "position:y", position.y + bob_height, 0.5 / bob_speed)

func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = body as Player
		_pick_up(player_in_range)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_pick_up(player_in_range)

func _pick_up(player: Player) -> void:
	if is_picked_up or player == null:
		return
	var item = _load_item_data(item_id)
	if item and player.inventory:
		if not player.inventory.add_item(item, quantity):
			return
		GameManager.item_picked_up.emit(item_id, quantity)
		_show_pickup_text(item.item_name)
	else:
		GameManager.item_picked_up.emit(item_id, quantity)
		_show_pickup_text(item_id)
	is_picked_up = true
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
	elif item_type == 1 or data.has("armor_type"):
		var armor = ArmorData.new()
		armor.armor_type = data.get("armor_type", 0)
		armor.defense = data.get("defense", 5)
		armor.vitality_bonus = data.get("vitality_bonus", 0)
		armor.hp_bonus = data.get("hp_bonus", 0)
		item = armor
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
	item.attack_bonus = data.get("attack_bonus", 0)
	item.heal_amount = data.get("heal_amount", 0)
	item.mana_amount = data.get("mana_amount", 0)
	
	# Try to load sprite
	var sprite_path = "res://assets/sprites/weapons/" + load_id + ".png"
	if ResourceLoader.exists(sprite_path):
		item.sprite = load(sprite_path)
	
	return item

func _show_pickup_text(item_name: String):
	var label = Label.new()
	label.text = "+ %s" % item_name
	label.position = global_position
	_get_pickup_text_parent().add_child(label)
	
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

func _get_pickup_text_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene != null else get_tree().root

func _create_placeholder_marker() -> void:
	if sprite and sprite.texture:
		return
	for x in [-5.0, 0.0, 5.0]:
		var dot := Polygon2D.new()
		dot.color = Color.WHITE
		dot.polygon = PackedVector2Array([
			Vector2(-1.5, -1.5),
			Vector2(1.5, -1.5),
			Vector2(1.5, 1.5),
			Vector2(-1.5, 1.5)
		])
		dot.position = Vector2(x, 0.0)
		dot.z_index = 5
		add_child(dot)
