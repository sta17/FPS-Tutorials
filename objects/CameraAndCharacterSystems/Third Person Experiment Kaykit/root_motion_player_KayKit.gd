extends Player
class_name PlayerThirdPersonKayKit

#region Variables
@export_subgroup("Properties")
@export var SPEED = 15.0
@export var JUMP_VELOCITY = 4.5

## Main [InventoryHandler] node.
@export_subgroup("Inventory")
@export_node_path("InventoryHandler") var InventoryHandler_path := NodePath("InventoryHandler")
@onready var inventoryHandler := get_node(InventoryHandler_path)
@export_node_path("InventorySystemUI") var InventorySystemUI_path := NodePath("InventorySystemUI")
@onready var inventorySystemUI := get_node(InventorySystemUI_path)
var interactableInv
var interactableInvBody:BoxInventory

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0
var is_weapons_disabled:bool = false

var mouse_sensitivity = 700
var mouse_captured := true
var is_mouse_free:bool = false
var display_interact:bool = true
var allowMovement:bool = true

var movement_velocity: Vector3
var rotation_target: Vector3

var input: Vector3
var input_mouse: Vector2

var health:float = 100

var container_offset = Vector3(1.2, -1.1, -2.75)

@onready var particles_trail = $ParticlesTrail
var coins = 0

var previously_floored
var jump_single
var jump_double

var tween:Tween

signal health_updated

@onready var rightHand: BoneAttachment3D = $Knight/Rig/Skeleton3D/RightHand
@onready var leftHand: BoneAttachment3D = $Knight/Rig/Skeleton3D/LeftHand
@onready var raycast = $LookAt/RayCast
@onready var muzzle = $Armature/Muzzle
@onready var container = $Armature/Container
@onready var sound_footsteps = $SoundFootsteps
@onready var blaster_cooldown = $Cooldown
@onready var interact_message_position : Control = $"../HUD/InteractMessagePosition"
@onready var interact_message : Label = $"../HUD/InteractMessagePosition/InteractMessage"

@export var crosshair:TextureRect

var lastLookAtDirection: Vector3 = Vector3.ZERO
var lastInputDirection:Vector2 = Vector2.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

enum INPUT_STATE {
	IDLE,
	UI_OPEN_MAINMENU,
	UI_OPEN_INVENTORY
}
var _INTERFACE_INPUT_STATE:INPUT_STATE = INPUT_STATE.IDLE
#endregion

#region Ready and Process
func _ready():
	initiate_change_weapon(weapon_index)

func _physics_process(delta):
	if allowMovement:
		var Velocity = velocity
	
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
	
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
		# Add the gravity.
		var cameraController = get_tree().get_nodes_in_group("CameraController")[0]
		var lookat:Vector3 = cameraController.get_node("LookAt").global_position
		lookat = Vector3(lookat.x,global_position.y,lookat.z)
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		#var inputDir: Vector2 = Input.get_vector("move_left","move_right","move_forward","move_back")
		var inputDir: Vector2 = Input.get_vector("move_right","move_left","move_back","move_forward")
		#var inputDir: Vector2 = Input.get_vector("move_left","move_right","move_back","move_forward")
		var direction = Vector3(transform.basis * Vector3(inputDir.x,0,inputDir.y)).normalized()
		if direction != Vector3.ZERO:
			var lerp0 = lerp(lastLookAtDirection.x, lookat.x, 0.05)
			var lerp1 = lerp(lastLookAtDirection.y, lookat.y, 0.05)
			var lerp2 = lerp(lastLookAtDirection.z, lookat.z, 0.05)
			var lerpDirection: Vector3 = Vector3(lerp0, lerp1, lerp2)
			look_at(lerpDirection)
			lastLookAtDirection = lerpDirection
			Velocity.x = direction.x * SPEED
			Velocity.z = direction.z * SPEED
		else:
			Velocity.x = move_toward(velocity.x,0,SPEED)
			Velocity.z = move_toward(velocity.z,0,SPEED)
		velocity = Velocity
	
		#var h_rot = cameraController.global_transform.basis.get_euler().y
	
		#if !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#	direction = direction.rotated(Vector3.UP, h_rot).normalized()
	
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
	
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
		$AnimationTree.set("parameters/conditions/idle", direction == Vector3.ZERO)
		$AnimationTree.set("parameters/conditions/moving", direction != Vector3.ZERO)
		$AnimationTree.set("parameters/conditions/falling",!is_on_floor())
		$AnimationTree.set("parameters/conditions/landed",is_on_floor())
		$AnimationTree.set("parameters/BlendSpace2D/blend_position", Vector2(lerp(lastInputDirection.x,inputDir.x,0.15),lerp(lastInputDirection.y,inputDir.y,0.15)))
		lastInputDirection = inputDir
	
		#if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#	$AnimationTree.set("parameters/BlendSpace2D/blend_position", Vector2(-direction.x, -direction.z))
	
		#if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#	look_at(Vector3(lookat.x, global_position.y, lookat.z))
		#elif direction != Vector3.ZERO:
		#	rotation = Vector3(rotation.x, atan2(-direction.x, -direction.z), rotation.z)
	
		#var h_rot = cameraController.global_transform.basis.get_euler().y
		#var currentRotation = transform.basis.get_rotation_quaternion()
		var cameraRotation = cameraController.global_transform.basis.get_euler()
		#velocity = (currentRotation.normalized() * $AnimationTree.get_root_motion_position()) / delta
		rotation.y = cameraRotation.y+deg_to_rad(180)

		move_and_slide()
		interact()
	
func _process(delta):
	
	# Handle functions
	handle_controls(delta)
	
	# Movement
	var applied_velocity: Vector3
	
	movement_velocity = transform.basis * movement_velocity # Move forward
	
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	
	# Rotation
	#container.position = lerp(container.position, container_offset - (applied_velocity / 30), delta * 10)
	
	# Movement sound
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true
	
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			particles_trail.emitting = true
			sound_footsteps.stream_paused = false
	
	# Landing after jump or falling
	if is_on_floor() and gravity > 1 and !previously_floored: # Landed
		Audio.play("assets/audio/land.ogg")
	
	previously_floored = is_on_floor()
	
	# Falling/respawning
	if position.y < -10:
		get_tree().reload_current_scene()

func handle_controls(delta):
	if Input.is_action_just_pressed("negative_interact"):
		if _INTERFACE_INPUT_STATE == INPUT_STATE.UI_OPEN_INVENTORY:
			open_inventory()
			_INTERFACE_INPUT_STATE = INPUT_STATE.IDLE
	
	if Input.is_action_just_pressed("toggle_inventory"):
		open_inventory()
			
	if Input.is_action_just_pressed("interact"):
		if interactableInv != null:
			open_inventory(interactableInv)
	
	if Input.is_action_just_pressed("toggle_hotbar_next"):
		inventoryHandler.hotbar.next_item()
	if Input.is_action_just_pressed("toggle_hotbar_previous"):
		inventoryHandler.hotbar.previous_item()
	
	# Mouse capture
	if Input.is_action_just_pressed("mouse_capture") and !is_mouse_free:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit") and !is_mouse_free:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		
		input_mouse = Vector2.ZERO
	# Shooting
	
	action_shoot()
	
	# Jumping
	
	if Input.is_action_just_pressed("jump"):
		
		if jump_single or jump_double:
			Audio.play("assets/audio/jump_a.ogg, assets/audio/jump_b.ogg, assets/audio/jump_c.ogg")
		
	# Weapon switching
	
	action_weapon_toggle()
#endregion

#region Weapon Attack
func action_shoot():
	if Input.is_action_pressed("shoot") and !is_weapons_disabled:
		if weapon.is_melee:
			weapon_melee()
		else:
			weapon_ranged()

func weapon_melee():
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
	
	Audio.play(weapon.sound_shoot)
	
	if !weapon.do_hide_muzzle:	
		
		container.position.z += 0.25 # Knockback of weapon visual
		movement_velocity += Vector3(0, 0, weapon.knockback) # Knockback
		
		# Set muzzle flash position, play animation
		
		muzzle.play("default")
		
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = container.position - weapon.muzzle_position
		
	blaster_cooldown.start(weapon.cooldown)
		
	# Shoot the weapon, amount based on shot count
	for n in weapon.shot_count:
		
		raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
		raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)
			
		raycast.force_raycast_update()
			
		if !raycast.is_colliding(): return # Don't create impact when raycast didn't hit
			
		var collider = raycast.get_collider()
			
		# Hitting an enemy
		if collider.has_method("damage"):
			collider.damage(weapon.damage)
			
			# Creating an impact animation
			var impact = preload("res://objects/impact.tscn")
			var impact_instance = impact.instantiate()
			
			impact_instance.play("shot")
			
			get_tree().root.add_child(impact_instance)
			
			impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)

func weapon_ranged():
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
		
	Audio.play(weapon.sound_shoot)
		
	container.position.z += 0.25 # Knockback of weapon visual
	movement_velocity += Vector3(0, 0, weapon.knockback) # Knockback
		
	# Set muzzle flash position, play animation
	if !weapon.do_hide_muzzle:	
		muzzle.play("default")
		
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = container.position - weapon.muzzle_position
		
	blaster_cooldown.start(weapon.cooldown)
		
	# Shoot the weapon, amount based on shot count

	for n in weapon.shot_count:
		
		raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
		raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)
			
		raycast.force_raycast_update()
			
		if !raycast.is_colliding(): return # Don't create impact when raycast didn't hit
			
		var collider = raycast.get_collider()
			
		# Hitting an enemy
		if collider.has_method("damage"):
			collider.damage(weapon.damage)
			
			# Creating an impact animation
			var impact = preload("res://objects/impact.tscn")
			var impact_instance = impact.instantiate()
			
			impact_instance.play("shot")
			
			get_tree().root.add_child(impact_instance)
			
			impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
#endregion

#region Weapon Change
# Toggle between available weapons (listed in 'weapons')
func action_weapon_toggle():
	
	if Input.is_action_just_pressed("toggle_weapon_next"):
		
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
		initiate_change_weapon(weapon_index)
		
		Audio.play("assets/audio/weapon_change.ogg")
	if Input.is_action_just_pressed("toggle_weapon_previous"):
		
		weapon_index = wrap(weapon_index - 1, 0, weapons.size())
		initiate_change_weapon(weapon_index)
		
		Audio.play("assets/audio/weapon_change.ogg")
		
# Initiates the weapon changing animation (tween)
func initiate_change_weapon(index):
	weapon_index = index
	
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon) # Changes the model

# Switches the weapon model (off-screen)
func change_weapon():
	weapon = weapons[weapon_index]

	# Step 1. Remove previous weapon model(s) from container
	for n in rightHand.get_children():
		rightHand.remove_child(n)
	
	# Step 2. Place new weapon model in container
	var weapon_model = weapon.model.instantiate()
	rightHand.add_child(weapon_model)
	
	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation
	
	# Step 3. Set model to only render on layer 2 (the weapon camera)
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2
		
	# Set weapon data
	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair
#endregion

#region Take Damage
func damage(amount):
	
	health -= amount
	health_updated.emit(health) # Update health on HUD
	
	if health < 0:
		get_tree().reload_current_scene() # Reset when out of health
#endregion

#region Items
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is PickUpItem:
		if body.autoCollect:
			body.Collect(self)
	if body is BoxInventory:
		interactableInv = body.get_inventory()
		interactableInvBody = body

func _on_area_3d_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
	if body is BoxInventory and body == interactableInvBody:
		interactableInvBody = null
		interactableInv = null

func _on_inventory_system_ui_opened_inventory_ui(opened) -> void:
	allowUI(opened)

func open_inventory(inventory : Inventory = null):
	inventorySystemUI.open_inventory(inventory)
	if _INTERFACE_INPUT_STATE == INPUT_STATE.IDLE:
		_INTERFACE_INPUT_STATE = INPUT_STATE.UI_OPEN_INVENTORY

func allowUI(status:bool):
	if status:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_weapons_disabled = true
		mouse_captured = false
		is_mouse_free = true
		crosshair.visible = false
		display_interact = false
		interact_message.visible = false
		allowMovement = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_weapons_disabled = false
		mouse_captured = true
		is_mouse_free = false
		crosshair.visible = true
		display_interact = true
		allowMovement = true
#endregion

func interact():
	var cameraController = get_tree().get_nodes_in_group("CameraController")[0]
	var camraycast = cameraController.raycast
	if camraycast.is_colliding():
		var camera3d: Camera3D = get_tree().get_nodes_in_group("CameraController")[0].camera
		var object = camraycast.get_collider()
		var node = object as Node
		var box := node as BoxInventory
		if box != null:
			var inv = box.get_inventory()
			if inv != null:
				if display_interact:
					interact_message.visible = !inventoryHandler.is_open(inv)
				interact_message.text = "E to Open Inventory"
				interact_message_position.position = camera3d.unproject_position(box.position)
				if interactableInv != inv:
					if Input.is_action_just_pressed("interact"):
						open_inventory(inv)
				return
		var dropped_item := node as PickUpItem
		if dropped_item != null:
			if dropped_item.is_pickable:
				interact_message.visible = true
				interact_message.text = "E to Pickup"
				interact_message_position.position = camera3d.unproject_position(dropped_item.position)

				if Input.is_action_just_pressed("interact"):
					#InventoryHandler.pick_to_inventory(dropped_item)
					dropped_item.Collect(self)
				return
		interact_message.visible = false
		#interact_message_position.position = default_interact_message_position
