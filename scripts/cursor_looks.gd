extends Node

@export var default_cursor: Texture
@export var coin_cursor: Texture
@export var book_cursor: Texture
@export var bottle_cursor: Texture
@export var setting_cursor: Texture
@export var cross_cursor: Texture
@export var compass_cursor: Texture

func _ready():
	# USED FOR SCALING CURSOR
	#var current_window_size_Width = ProjectSettings.get_setting("display/window/size/viewport_width")
	#var current_window_size_Height = ProjectSettings.get_setting("display/window/size/viewport_height")
	#var scale_multiple = current_window_size_Width / current_window_size_Height

	#AVAILABLE CURSORS

	#default_cursor
	#coin_cursor
	#book_cursor
	#bottle_cursor
	#setting_cursor
	#cross_cursor
	#compass_cursor

	#							  CURSOR TO USE		  USE CASE		  ARROW TIP
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW,Vector2(7, 6))
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_CAN_DROP,Vector2(7, 6))
	#								TODO: NO ACTION / CROSS
	Input.set_custom_mouse_cursor(cross_cursor, Input.CURSOR_FORBIDDEN,Vector2(7, 6))
