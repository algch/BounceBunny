extends Sprite

var SPEED = 500

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 113
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile/projectile.tscn')
onready var attack_texture = preload('res://player/sprites/tito-shooting-01.png')
onready var summon_texture = preload('res://player/sprites/tito-pixelart-01.png')
onready var summon_class = preload('res://weapons/summon/summon.tscn')
var CHARGE_WAIT_TIME = 1.0
var MAX_SHOOT_LENGTH = 200
onready var items = {
	globals.ITEM_TYPES.SUPPORT: 0,
	globals.ITEM_TYPES.TELEPORT: 0,
	globals.ITEM_TYPES.SCORE: 0,
}

enum STATE {
	idle,
	charging
}
var current_state = STATE.idle
var current_weapon = globals.PROJECTILE_TYPES.ATTACK
var shoot_point_start = null

var MAX_HEALTH = 10.0
var health = MAX_HEALTH

var default_font = DynamicFont.new()

var current_plant_id = null

func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22

func healthLoop():
	if health <= 0 and not is_queued_for_deletion():
		get_node('/root/main/').GAME_OVER = true
		# GAME OVER
		queue_free()

func heal(points):
	if (health + points) <= MAX_HEALTH:
		health += points

func changeWeapon():
	if current_state == STATE.charging:
		return
	match current_weapon:
		globals.PROJECTILE_TYPES.ATTACK:
			current_weapon = globals.PROJECTILE_TYPES.SUMMON
			set_texture(summon_texture)
		globals.PROJECTILE_TYPES.SUMMON:
			current_weapon = globals.PROJECTILE_TYPES.ATTACK
			set_texture(summon_texture)


func summonPlant(power, direction):
	if items[globals.ITEM_TYPES.SUPPORT] <= 0:
		print('NO HAY SEMILLAS')
		return

	var summon = summon_class.instance()
	var offset = direction * WEAPON_RADIUS

	summon.position = position + offset
	summon.direction = direction
	summon.power = power
	summon.type = globals.ITEM_TYPES.SUPPORT

	get_node('/root/main/').add_child(summon)
	items[globals.ITEM_TYPES.SUPPORT] -= 1


func addItem(item):
	items[item.TYPE] += 1
	print(items)

func receiveDamage(damage):
	health -= damage
	print('¡Mi pierna!')


func attack(power, direction):
	var projectile = projectile_class.instance()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction
	projectile.power = power
	projectile.type = globals.PROJECTILE_TYPES.ATTACK

	get_node('/root/main/').add_child(projectile)


func pollInput():
	var RIGHT = int(Input.is_action_pressed('ui_right'))
	var LEFT = int(Input.is_action_pressed('ui_left'))
	var DOWN = int(Input.is_action_pressed('ui_down'))
	var UP = int(Input.is_action_pressed('ui_up'))

	var X = -LEFT + RIGHT
	var Y = -UP + DOWN

	motion_dir =  Vector2(X, Y)

	if Input.is_action_pressed('touch') and current_state != STATE.charging and not $weaponSwitcher.is_pressed():
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
			if current_weapon == globals.PROJECTILE_TYPES.ATTACK:
				attack(power, direction)
			if current_weapon == globals.PROJECTILE_TYPES.SUMMON:
				summonPlant(power, direction)	

func getWeaponString():
	match current_weapon:
		0:
			return 'ATTACK'
		1:
			return 'SUMMON'
		2:
			return 'SCORE'
		3:
			return 'TELEPORT'


func _draw():
	var score = get_node('/root/main/').score
	var weapon_str = getWeaponString()
	var message = 'weapon: ' + weapon_str + ' score: ' + str(score)
	draw_string(default_font, Vector2(-20, -80),  message, Color(1, 1, 1))
	if current_state != STATE.charging:
		return
	draw_circle(
		shoot_point_start - position,
		(get_global_mouse_position() - shoot_point_start).length(),
		Color(1, 1, 1, 0.25)
	)
	var color = Color(1, 1, 1) if (get_global_mouse_position() - shoot_point_start).length() < MAX_SHOOT_LENGTH else Color(1, 0, 0)
	draw_line(Vector2(0, 0), shoot_point_start - get_global_mouse_position(), color)



func _process(delta):
	update()

func _physics_process(delta):
	pollInput()
	healthLoop()
