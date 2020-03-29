extends Position2D

var SPEED = 500

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 113
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile/projectile.tscn')
onready var summon_class = preload('res://weapons/summon/summon.tscn')
onready var main = get_node('/root/main/')
var CHARGE_WAIT_TIME = 1.0
var MAX_SHOOT_LENGTH = 200

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

var current_plant = null
var mana = 1000.0

func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22
	current_plant = get_node('/root/main/plant/')

func _on_weaponSwitcher_pressed():
	if current_state == STATE.charging:
		return
	var animation_name
	var part = 0 if current_state == STATE.idle else 1 
	match current_weapon:
		globals.PROJECTILE_TYPES.ATTACK:
			current_weapon = globals.PROJECTILE_TYPES.SUMMON
			animation_name = 'summon_' + str(part)
		globals.PROJECTILE_TYPES.SUMMON:
			current_weapon = globals.PROJECTILE_TYPES.ATTACK
			animation_name = 'bow_' + str(part)

	$animation.set_animation(animation_name)
	$animation.set_frame(0)
	$animation.stop()


func summonPlant(power, direction):
	var summon = summon_class.instance()

	if mana < summon.mana_cost:
		return

	var offset = direction * WEAPON_RADIUS

	summon.position = position + offset
	summon.direction = direction
	summon.power = power
	summon.first_neighbor = current_plant

	get_node('/root/main/').add_child(summon)
	mana -= summon.mana_cost


func addMana(increment):
	mana += increment

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
	$animation.play('attack')


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
		pressAnimation()
		

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
		releaseAnimation()

func pressAnimation():
	match current_weapon:
		globals.PROJECTILE_TYPES.ATTACK:
			$animation.play('bow_0')
		globals.PROJECTILE_TYPES.SUMMON:
			$animation.play('summon_0')

func releaseAnimation():
	match current_weapon:
		globals.PROJECTILE_TYPES.ATTACK:
			$animation.play('bow_1')
		globals.PROJECTILE_TYPES.SUMMON:
			$animation.play('summon_1')

func setCurrentPlant(plant):
	if plant.is_queued_for_deletion() or not is_instance_valid(plant):
		main.gameOver()
	position = plant.position
	current_plant = plant

func getWeaponString():
	match current_weapon:
		0:
			return 'attack'
		1:
			return 'summon'

func _draw():
	var score = get_node('/root/main/').score
	var weapon_str = getWeaponString()
	var message = 'weapon: ' + weapon_str + ' score: ' + str(score) + ' mana: ' + str(mana)
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

func _on_animation_finished():
	var animation_name
	var part = 0 if current_state == STATE.idle else 1 
	match current_weapon:
		globals.PROJECTILE_TYPES.ATTACK:
			animation_name = 'bow_' + str(part)
			$animation.set_animation(animation_name)
		globals.PROJECTILE_TYPES.SUMMON:
			animation_name= 'summon_' + str(part)
			$animation.set_animation(animation_name)

	$animation.set_frame(0)
	$animation.stop()

func aimingLoop():
	if current_state != STATE.charging:
		return

	var reference = (shoot_point_start - get_global_mouse_position()).normalized()
	if reference.length() <= 0.5:
		return
	var angle = reference.angle() + PI/2.0
	$animation.rotation = angle
	$weaponSwitcher.rotation = angle



func _process(delta):
	update()

func _physics_process(delta):
	aimingLoop()
	pollInput()