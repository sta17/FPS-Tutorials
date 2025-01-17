extends Player
class_name PlayerFirstPerson

#region Variables
@export_subgroup("Properties")
@export var movement_speed = 250
@export var jump_strength = 7

## Main [InventoryHandler] node.
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

var movement_velocity: Vector3
var rotation_target: Vector3

var input: Vector3
var input_mouse: Vector2

var health:int = 100
var gravity := 0.0

var previously_floored := false

var jump_single := true
var jump_double := true

#var container_offset = Vector3(1.2, -1.1, -2.75)

@onready var particles_trail = $ParticlesTrail
#var coins = 0

var tween:Tween

signal health_updated

@export_subgroup("Node Exporting")
@onready var handRight:Node3D = $Body/Rig/Skeleton3D/HandRight/Attachment
@onready var handLeft:BoneAttachment3D = $Body/Rig/Skeleton3D/HandLeft
@onready var animationPlayer:AnimationPlayer = $Body/AnimationPlayer
@onready var camera = $Head/Camera
@onready var raycast = $Head/Camera/RayCast
@export var muzzleRight : AnimatedSprite3D
@export var muzzleLeft : AnimatedSprite3D
@onready var sound_footsteps = $SoundFootsteps
@onready var blaster_cooldown = $Cooldown
@onready var interact_message_position : Control = $"../HUD/InteractMessagePosition"
@onready var interact_message : Label = $"../HUD/InteractMessagePosition/InteractMessage"

@export var crosshair:TextureRect

enum INPUT_STATE {
	IDLE,
	UI_OPEN_MAINMENU,
	UI_OPEN_INVENTORY
}
var _INTERFACE_INPUT_STATE:INPUT_STATE = INPUT_STATE.IDLE
#endregion

#region Ready and Process
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	initiate_change_weapon(weapon_index)
	animationPlayer.play("Idle")

func _physics_process(delta):
	interact()

func _process(delta):
	# Handle functions
	handle_controls(delta)
	handle_gravity(delta)
	
	# Movement
	var applied_velocity: Vector3
	
	movement_velocity = transform.basis * movement_velocity # Move forward
	
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
	move_and_slide()
	
	# Rotation
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 1.25, delta * 5)	
	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	
	#container.position = lerp(container.position, container_offset - (applied_velocity / 30), delta * 10)
	
	# Movement sound
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true
	
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			particles_trail.emitting = true
			sound_footsteps.stream_paused = false
	
	# Landing after jump or falling
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	
	if is_on_floor() and gravity > 1 and !previously_floored: # Landed
		Audio.play("assets/audio/land.ogg")
		camera.position.y = -0.1
	
	previously_floored = is_on_floor()
	
	# Falling/respawning
	if position.y < -10:
		get_tree().reload_current_scene()
#endregion

#region Controls and Gravity
# Mouse movement
func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		
		input_mouse = event.relative / mouse_sensitivity
		
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

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
	
	# Movement
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	movement_velocity = input.normalized() * movement_speed * delta
	
	# Rotation
	var rotation_input := Vector3.ZERO
	
	rotation_input.y = Input.get_axis("camera_left", "camera_right")
	rotation_input.x = Input.get_axis("camera_up", "camera_down") / 2
	
	rotation_target -= rotation_input.limit_length(1.0) * 5 * delta
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Shooting
	action_shoot()
	
	# Jumping
	if Input.is_action_just_pressed("jump"):
		
		if jump_single or jump_double:
			Audio.play("assets/audio/jump_a.ogg, assets/audio/jump_b.ogg, assets/audio/jump_c.ogg")
		
		if jump_double:
			
			gravity = -jump_strength
			jump_double = false
			
		if(jump_single): action_jump()
		
	# Weapon switching
	
	action_weapon_toggle()

# Handle gravity
func handle_gravity(delta):
	
	gravity += 20 * delta
	
	if gravity > 0 and is_on_floor():
		
		jump_single = true
		gravity = 0

# Jumping
func action_jump():
	gravity = -jump_strength
	
	jump_single = false;
	jump_double = true;
#endregion

#region Attack
# Shooting
func action_shoot():
	if Input.is_action_pressed("shoot") and !is_weapons_disabled:
		if weapon.is_melee:
			weapon_melee()
		else:
			weapon_ranged()

func weapon_melee():
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
	
	#Audio.play(weapon.sound_shoot)
		
	blaster_cooldown.start(weapon.cooldown)
	animationPlayer.play("1H_Melee_Attack_Slice_Horizontal")
	
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
			
			#impact_instance.play("shot")
			
			get_tree().root.add_child(impact_instance)
			
			impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
			impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true) 

func weapon_ranged():
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
		
	Audio.play(weapon.sound_shoot)
	
	camera.rotation.x += 0.025 # Knockback of camera
	movement_velocity += Vector3(0, 0, weapon.knockback) # Knockback
		
	# Set muzzle flash position, play animation
		
	if !weapon.do_hide_muzzle:	
		muzzleRight.play("default")
		muzzleRight.rotation_degrees.z = randf_range(-45, 45)
		muzzleRight.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzleRight.position = handRight.position - weapon.muzzle_position
		
		muzzleLeft.play("default")
		muzzleLeft.rotation_degrees.z = randf_range(-45, 45)
		muzzleLeft.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzleLeft.position = handLeft.position - weapon.muzzle_position
		
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
			impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true) 
#endregion

#region Weapons Change
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
	#tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon) # Changes the model

# Switches the weapon model (off-screen)
func change_weapon():
	weapon = weapons[weapon_index]

	# Step 1. Remove previous weapon model(s) from container
	for n in handRight.get_children():
		handRight.remove_child(n)
	for n in handLeft.get_children():
		handLeft.remove_child(n)

	# Step 2. Place new weapon model in container
	var weapon_model_right = weapon.model.instantiate()
	handRight.add_child(weapon_model_right)
	weapon_model_right.rotation_degrees = weapon.rotation
	var weapon_model_left = weapon.model.instantiate()
	handLeft.add_child(weapon_model_left)
	weapon_model_left.rotation_degrees = weapon.rotation

	# Step 3. Set model to only render on layer 2 (the weapon camera)
	#for child in weapon_model_right.find_children("*", "MeshInstance3D"):
	#	child.layers = 2
	#for child in weapon_model_left.find_children("*", "MeshInstance3D"):
	#	child.layers = 2

	# Set weapon data
	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair
	#crosshair.position = camera.unproject_position(raycast.target_position)
#endregion

#region Take Damage
func damage(amount):
	
	health -= amount
	health_updated.emit(health) # Update health on HUD
	
	if health < 0:
		get_tree().reload_current_scene() # Reset when out of health
#endregion

#region Item Handling
func allowUI(status:bool):
	if status:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_weapons_disabled = true
		mouse_captured = false
		is_mouse_free = true
		crosshair.visible = false
		display_interact = false
		interact_message.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_weapons_disabled = false
		mouse_captured = true
		is_mouse_free = false
		crosshair.visible = true
		display_interact = true
		
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

func interact():
	if raycast.is_colliding():
		var object = raycast.get_collider()
		var node = object as Node
		var box := node as BoxInventory
		if box != null:
			var inv = box.get_inventory()
			if inv != null:
				if display_interact:
					interact_message.visible = !inventoryHandler.is_open(inv)
				interact_message.text = "E to Open Inventory"
				interact_message_position.position = camera.unproject_position(box.position)
				if interactableInv != inv:
					if Input.is_action_just_pressed("interact"):
						open_inventory(inv)
				return
		var dropped_item := node as PickUpItem
		if dropped_item != null:
			if dropped_item.is_pickable:
				interact_message.visible = true
				interact_message.text = "E to Pickup"
				interact_message_position.position = camera.unproject_position(dropped_item.position)

				if Input.is_action_just_pressed("interact"):
					#InventoryHandler.pick_to_inventory(dropped_item)
					dropped_item.Collect(self)
				return
		interact_message.visible = false
		#interact_message_position.position = default_interact_message_position
	else:
		interact_message.visible = false
#endregion
