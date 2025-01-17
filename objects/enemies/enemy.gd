extends Node3D

@export var player:Node3D
@export var dontboob:bool

@export var RotSpeedX:float = 0.5
@export var RotSpeedY:float = 0
@export var RotSpeedZ:float = 0
@export var BaseDamage:float = 5


@export var raycast:RayCast3D
@export var muzzle_a:AnimatedSprite3D
@export var muzzle_b:AnimatedSprite3D

var health := 100
var time := 0.0
var target_position:Vector3
var destroyed := false

@export var model:Node3D

# When ready, save the initial position

func _ready():
	if !model:
		model = self
	
	target_position = position

func _process(delta):
	if visible:
		var playerPos: Vector3 = Vector3(0, 0, 0)
		if player:
			playerPos = player.position
		if RotSpeedX == 0:
			model.look_at(playerPos + Vector3(0, RotSpeedX, 0), Vector3.UP, true) # Look at player
		else:
			model.look_at(playerPos, Vector3.UP, true) # Look at player
		
		if !dontboob:
			target_position.y += (cos(time * 5) * 1) * delta # Sine movement (up and down)
			position = target_position
	
	time += delta

# Take damage from player

func damage(amount):
	
	Audio.play("assets/audio/enemy_hurt.ogg")
	
	health -= amount
	
	if health <= 0 and !destroyed:
		destroy()

# Destroy the enemy when out of health

func destroy():
	
	Audio.play("assets/audio/enemy_destroy.ogg")
	
	destroyed = true
	queue_free()

# Shoot when timer hits 0

func _on_timer_timeout():
	
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		
		var collider = raycast.get_collider()
		
		if collider.has_method("damage"): # Raycast collides with player
		
			# Play muzzle flash animation(s)
		
			muzzle_a.frame = 0
			muzzle_a.play("default")
			muzzle_a.rotation_degrees.z = randf_range(-45, 45)
			
			muzzle_b.frame = 0
			muzzle_b.play("default")
			muzzle_b.rotation_degrees.z = randf_range(-45, 45)
			
			Audio.play("assets/audio/enemy_attack.ogg")
			
			collider.damage(BaseDamage) # Apply damage to player
