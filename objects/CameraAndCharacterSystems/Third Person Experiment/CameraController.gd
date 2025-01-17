extends Node3D

@export var sensitivity : int = 5
var character: CharacterBody3D
var allowCameraMovement: bool = true
@onready var camera := get_node(NodePath("SpringArm3D/Camera3D"))
@onready var raycast := get_node(NodePath("SpringArm3D/Camera3D/RayCast"))

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if allowCameraMovement:
		character = get_tree().get_nodes_in_group("Player")[0]
		global_position = character.global_position
		var camera: Camera3D = get_node("SpringArm3D/Camera3D")
		var lookat:Node3D = character.get_node("LookAt")
		#camera.look_at(Vector3(lookat.global_position.x, global_position.y, lookat.global_position.z))
		camera.look_at(Vector3(lookat.global_position.x, lookat.global_position.y, lookat.global_position.z))


func _input(event):
	if event is InputEventMouseMotion and allowCameraMovement:
		rotation = Vector3(clamp(rotation.x - event.relative.y / 1000 * sensitivity,-1, .25), rotation.y - event.relative.x / 1000 * sensitivity, 0)


func allowUI(status:bool):
	if status:
		allowCameraMovement = false
	else:
		allowCameraMovement = true


func _on_inventory_system_ui_opened_inventory_ui(opened) -> void:
	allowUI(opened)
