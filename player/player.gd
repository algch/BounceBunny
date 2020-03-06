extends KinematicBody2D

var SPEED = 100

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 113
var motion_dir = Vector2(0, 0)
var is_attacking = false
onready var projectile_class = preload('res://weapons/projectile.tscn')
onready var charge_timer = get_node('charge_timer')

enum STATE {
	idle,
	charging
}
var current_state = STATE.idle

var health = 10


func _ready():
	pass

func receiveDamage(damage):
	health -= damage
	print('hijos de la verga')

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

	if Input.is_action_just_pressed('touch') and current_state != STATE.charging:
		# TODO fix bug here, it should only shoot once
		current_state = STATE.charging
		charge_timer.start()

	if Input.is_action_just_released('touch'):
		# instance arrow and make it move and cause a damage proportional
		# to the time it was charged
		current_state = STATE.idle
		charge_timer.stop()

func _on_charge_timer_timeout():
	is_attacking = true
	current_state = STATE.idle


func _physics_process(delta):
	pollInput()

	movementLoop()
	actionLoop()
