extends Node

# RevenueCat configuration
const REVENUECAT_API_KEY = "your_revenuecat_api_key"

# Product definitions
var products = {
	"starter_pack": {
		"id": "starter_pack",
		"price": "$2.99",
		"description": "500 gold, 10 health potions, exclusive blue armor skin",
		"rewards": {
			"gold": 500,
			"items": ["health_potion", "health_potion", "health_potion", "health_potion", "health_potion",
					  "health_potion", "health_potion", "health_potion", "health_potion", "health_potion"],
			"skin": "blue_armor"
		}
	},
	"inventory_expansion": {
		"id": "inventory_expansion",
		"price": "$0.99",
		"description": "+10 inventory slots (one-time purchase)",
		"rewards": {
			"inventory_slots": 10
		}
	},
	"map_pack_dark_forest": {
		"id": "map_pack_dark_forest",
		"price": "$1.99",
		"description": "Unlocks 3 new maps with unique monsters",
		"rewards": {
			"maps": ["dark_forest", "haunted_mansion", "cursed_swamp"]
		}
	},
	"gold_pouch": {
		"id": "gold_pouch",
		"price": "$0.99",
		"description": "200 gold (consumable)",
		"rewards": {
			"gold": 200
		}
	},
	"remove_ads": {
		"id": "remove_ads",
		"price": "$3.99",
		"description": "Remove all advertisements",
		"rewards": {
			"remove_ads": true
		}
	}
}

# Purchase state
var purchased_products: Array[String] = []
var entitlements: Dictionary = {}

# Signals
signal products_loaded(products: Array)
signal purchase_started(product_id: String)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal purchase_restored(product_id: String)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func initialize() -> void:
	_debug_log("[IAP] Initializing RevenueCat (placeholder)")
	# In production: Initialize RevenueCat SDK
	# RevenueCat.configure(REVENUECAT_API_KEY)
	
	# Simulate loading products
	await get_tree().create_timer(0.5).timeout
	products_loaded.emit(products.values())

func purchase(product_id: String) -> void:
	if not products.has(product_id):
		purchase_failed.emit(product_id, "Product not found")
		return
	
	_debug_log("[IAP] Starting purchase: " + product_id)
	purchase_started.emit(product_id)
	
	# In production: RevenueCat.purchaseProduct(products[product_id])
	
	# Simulate purchase flow
	await get_tree().create_timer(1.0).timeout
	
	# Simulate success (in production, verify with RevenueCat)
	_complete_purchase(product_id)

func _complete_purchase(product_id: String) -> void:
	var product = products[product_id]
	
	# Grant rewards
	_grant_rewards(product.rewards)
	
	# Mark as purchased
	if product_id != "gold_pouch":  # Gold pouch is repeatable
		purchased_products.append(product_id)
	
	purchase_completed.emit(product_id)
	_debug_log("[IAP] Purchase completed: " + product_id)

func _grant_rewards(rewards: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Grant gold
	if rewards.has("gold"):
		# Add gold to player inventory
		_debug_log("[IAP] Granted gold: " + str(rewards.gold))
	
	# Grant items
	if rewards.has("items"):
		for item_id in rewards.items:
			_debug_log("[IAP] Granted item: " + item_id)
	
	# Grant inventory slots
	if rewards.has("inventory_slots"):
		_debug_log("[IAP] Granted inventory slots: " + str(rewards.inventory_slots))
	
	# Unlock maps
	if rewards.has("maps"):
		for map_id in rewards.maps:
			_debug_log("[IAP] Unlocked map: " + map_id)
	
	# Remove ads
	if rewards.has("remove_ads"):
		_debug_log("[IAP] Ads removed")

func restore_purchases() -> void:
	_debug_log("[IAP] Restoring purchases")
	# In production: RevenueCat.restorePurchases()
	
	# Simulate restoring
	await get_tree().create_timer(0.5).timeout
	
	for product_id in purchased_products:
		purchase_restored.emit(product_id)
		_debug_log("[IAP] Restored: " + product_id)

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print(message)

func has_purchased(product_id: String) -> bool:
	return product_id in purchased_products

func get_product(product_id: String) -> Dictionary:
	if products.has(product_id):
		return products[product_id]
	return {}

func get_all_products() -> Array:
	return products.values()
