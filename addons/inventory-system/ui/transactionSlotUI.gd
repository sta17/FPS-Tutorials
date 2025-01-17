extends SlotUI
class_name TransactionSlotUI

var inventory_handler : InventoryHandler

## Special [SlotUI] that only represents slot information in transaction

func _ready():
	clear_info()
	
func update_info_with_item(item : InventoryItem, amount := 1):
	super.update_info_with_item(item, amount)
	visible = amount > 0
	self.global_position = get_global_mouse_position() - size/2
	$DropIcon.visible = false
	
func clear_info():
	super.clear_info()
	self.visible = false
	$DropIcon.visible = false
	
func _process(delta):
	if self.visible:
		if get_viewport().gui_get_focus_owner():
			self.global_position = get_viewport().gui_get_focus_owner().global_position
		else:
			self.global_position = get_global_mouse_position() - size/2
			
func _on_drop_area_mouse_exited():
	$DropIcon.visible = false


func _on_drop_area_mouse_entered():
	$DropIcon.visible = true


func _on_drop_area_gui_input(event: InputEvent) -> void:
	_drop_area_input(event)
	pass # Replace with function body.


func _on_control_gui_input(event: InputEvent) -> void:
	_drop_area_input(event)
	pass # Replace with function body.


func _on_control_mouse_entered() -> void:
	pass # Replace with function body.


func _on_control_mouse_exited() -> void:
	pass # Replace with function body.

func _drop_area_input(event : InputEvent):
	if event is InputEventMouseButton and inventory_handler:
		if event.pressed:
			inventory_handler.drop_transaction()
