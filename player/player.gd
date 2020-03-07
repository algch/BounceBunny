extends KinematicBody2D

var SPEED = 100

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 113
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile.tscn')
var charge_timer = Timer.new()
var CHARGE_WAIT_TIME = 3.0

enum STATE {
	idle,
	charging
}
var current_state = STATE.idle

var health = 10.0


func _ready():
	charge_timer.connect('timeout', self, '_on_charge_timer_timeout')
	add_child(charge_timer)

func receiveDamage(damage):
	health -= damage
	print('hijos de la verga')

func movementLoop():
	var motion = motion_dir.normalized() * SPEED
	move_and_slide(motion)


func attack(travel_time):
	var projectile = projectile_class.instance()
	var direction = (get_global_mouse_position() - position).normalized()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction
	projectile.travel_time = travel_time

	get_node('/root/main/').add_child(projectile)


func pollInput():
	var RIGHT = int(Input.is_action_pressed('ui_right'))
	var LEFT = int(Input.is_action_pressed('ui_left'))
	var DOWN = int(Input.is_action_pressed('ui_down'))
	var UP = int(Input.is_action_pressed('ui_up'))

	var X = -LEFT + RIGHT
	var Y = -UP + DOWN

	motion_dir =  Vector2(X, Y)

	if Input.is_action_just_pressed('touch') and current_state != STATE.charging:
		current_state = STATE.charging
		charge_timer.set_wait_time(CHARGE_WAIT_TIME)
		charge_timer.start()

	if Input.is_action_just_released('touch'):
		var travel_time = CHARGE_WAIT_TIME - charge_timer.get_time_left()
		current_state = STATE.idle
		charge_timer.stop()
		attack(travel_time)


func _on_charge_timer_timeout():
	charge_timer.stop()
	print('READY ', charge_timer.get_time_left())


func _physics_process(delta):
	pollInput()

	movementLoop()
