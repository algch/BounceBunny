extends KinematicBody2D

var SPEED = 100

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 74
var motion_dir = Vector2(0, 0)
var is_attacking = false
onready var projectile_class = preload('res://weapons/projectile.tscn')


func _ready():
	pass


func movementLoop():
	var motion = motion_dir.normalized() * SPEED
	move_and_slide(motion)

func actionLoop():
	if is_attacking:
		var projectile = projectile_class.instance()
		var direction = (get_global_mouse_position() - position).normalized()
		var offset = direction * WEAPON_RADIUS

		projectile.position = position + offset
		projectile.direction = direction

		get_node('/root/main/').add_child(projectile)
		is_attacking = false


func pollInput():
	var RIGHT = int(Input.is_action_pressed('ui_right'))
	var LEFT = int(Input.is_action_pressed('ui_left'))
	var DOWN = int(Input.is_action_pressed('ui_down'))
	var UP = int(Input.is_action_pressed('ui_up'))

	var X = -LEFT + RIGHT
	var Y = -UP + DOWN

	motion_dir =  Vector2(X, Y)

	is_attacking = Input.is_action_just_released('touch_release')


func _physics_process(delta):
	pollInput()

	movementLoop()
	actionLoop()
