@icon("res://assets/Icons/pixel-boy/node_3D/icon_money_bag.png")
extends Node3D
class_name BoxInventory

@export var labelText : String = "Inventory"

func _ready():
	$Inventory.inventory_name = labelText

func get_inventory() -> Inventory:
	return $Inventory

func set_Label_Text(text:String):
	$Inventory.inventory_name = text

func _on_inventory_closed():
	_on_close()


func _on_inventory_opened():
	_on_open()


func _on_open():
	#$box.visible = false
	$box.visible = false
	$boxOpen.visible = true
	#Audio.play("res://assets/audio/coin.ogg") # Play sound
	#$Open.play()


func _on_close():
	#$box.visible = true
	$boxOpen.visible = false
	$box.visible = true
	#Audio.play("res://assets/audio/coin.ogg") # Play sound
	#$Close.play()
