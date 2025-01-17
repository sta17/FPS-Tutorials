@icon("res://assets/Icons/pixel-boy/node_3D/icon_money_bag.png")
extends StaticBody3D
class_name PickUpItem

@export var item : InventoryItem
@export var is_pickable := true
@export var autoCollect := false
@export var amount : int
@export var addMeshModelOnStart : bool = true
var toBeDeleted:bool = false
var radius:
	get: 
		return 0.6
var global_position_yless:
	get:
		return global_position * Vector3(1, 0, 1)

#var color = Constants.Match.Items.Minimap.COLOR:
#	set(_value):
#		pass


func _ready():
	if addMeshModelOnStart and item:
		if item.properties.has("dropped_item_model"):
			var path = item.properties["dropped_item_model"]
			var dropped_item = load(path)
			var obj:Node = dropped_item.instantiate()
			self.AddMeshModel(obj)
			var animator: AnimationPlayer = obj.get_node(NodePath("AnimationPlayer"))
			if animator:
				if animator.has_animation("defaultItem"):
					animator.play("defaultItem")

func AddMeshModel(model):
	$Geometry.add_child(model)
	
	#start spin

func Collect(player):
	if toBeDeleted:
		return
	toBeDeleted = true
	$Particles.emitting = false
	$AnimationPlayer.stop()
	Audio.play("res://assets/audio/coin.ogg") # Play sound
	var local_inventory_handler = player.inventoryHandler
	if local_inventory_handler:
		local_inventory_handler.pick_to_inventory(self)
	is_pickable = false
	queue_free()
