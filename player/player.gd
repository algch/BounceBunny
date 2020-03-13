extends KinematicBody2D

var SPEED = 500

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 113
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile.tscn')
var charge_timer = Timer.new()
var CHARGE_WAIT_TIME = 1.0
onready var items = {
	globals.ITEM_TYPES.SUPPORT: 0,
	globals.ITEM_TYPES.BOOST: 0,
	globals.ITEM_TYPES.HEAL: 0,
}

enum STATE {
	idle,
	charging
}
var current_state = STATE.idle

var health = 10.0


func _ready():
	charge_timer.connect('timeout', self, '_on_charge_timer_timeout')
	add_child(charge_timer)
	print('globals ', globals)

func addItem(item):
	items[item.TYPE] += 1
	print(items)

func receiveDamage(damage):
	health -= damage
	print('¡Mi pierna!')

func movementLoop():
	var motion = motion_dir.normalized() * SPEED
	move_and_slide(motion)


func attack(power):
	var projectile = projectile_class.instance()
	var direction = (get_global_mouse_position() - position).normalized()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction
	projectile.power = power

	get_node('/root/main/').add_child(projectile)


func pollInput():
	var RIGHT = int(Input.is_action_pressed('ui_right'))
	var LEFT = int(Input.is_action_pressed('ui_left'))
	var DOWN = int(Input.is_action_pressed('ui_down'))
	var UP = int(Input.is_action_pressed('ui_up'))

	var X = -LEFT + RIGHT
	var Y = -UP + DOWN

	motion_dir =  Vector2(X, Y)

	if Input.is_action_pressed('touch') and current_state != STATE.charging:
		charge_timer.set_wait_time(CHARGE_WAIT_TIME)
		charge_timer.start()
		current_state = STATE.charging

	if Input.is_action_just_released('touch') and current_state == STATE.charging:
		var partial_power = (CHARGE_WAIT_TIME - charge_timer.get_time_left())/CHARGE_WAIT_TIME
		var power = 0.25 + 0.75 * partial_power

		current_state = STATE.idle
		charge_timer.stop()
		if power >= 0.5:
			attack(power)


func _on_charge_timer_timeout():
	charge_timer.stop()
	print('READY')


func _physics_process(delta):
	pollInput()

	movementLoop()
