extends KinematicBody2D

var SPEED = 500

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 113
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile.tscn')
var CHARGE_WAIT_TIME = 1.0
var MAX_SHOOT_LENGTH = 200
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
var shoot_point_start = null

var health = 10.0


func _ready():
	pass

func addItem(item):
	items[item.TYPE] += 1
	print(items)

func receiveDamage(damage):
	health -= damage
	print('¡Mi pierna!')

func movementLoop():
	var motion = motion_dir.normalized() * SPEED
	move_and_slide(motion)


func attack(power, direction):
	var projectile = projectile_class.instance()
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
		current_state = STATE.charging
		shoot_point_start = get_global_mouse_position()
		

	if Input.is_action_just_released('touch') and current_state == STATE.charging:
		var shoot_length = (get_global_mouse_position() - shoot_point_start).length()
		shoot_length = shoot_length if shoot_length <= MAX_SHOOT_LENGTH else MAX_SHOOT_LENGTH
		var partial_power = shoot_length/MAX_SHOOT_LENGTH
		var power = 0.25 + 0.75 * partial_power

		current_state = STATE.idle
		if power >= 0.5:
			var direction = (shoot_point_start - get_global_mouse_position()).normalized()
			attack(power, direction)


func _draw():
	if current_state != STATE.charging:
		return
	draw_circle(
		shoot_point_start - position,
		(get_global_mouse_position() - shoot_point_start).length(),
		Color(1, 1, 1, 0.5)
	)
	var color = Color(1, 1, 1) if (get_global_mouse_position() - shoot_point_start).length() < MAX_SHOOT_LENGTH else Color(1, 0, 0)
	draw_line(Vector2(0, 0), shoot_point_start - get_global_mouse_position(), color)



func _process(delta):
	update()

func _physics_process(delta):
	pollInput()

	movementLoop()
