extends Position2D

var SPEED = 500

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 125
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile/projectile.tscn')
onready var summon_class = preload('res://weapons/summon/summon.tscn')
onready var mainArena = get_node('/root/mainArena/')
var CHARGE_WAIT_TIME = 1.0
var MAX_SHOOT_LENGTH = 250
var MIN_SHOOT_LENGTH = 50
var ANIMATION_FRAME_COUNT = 14

enum STATE {
	idle,
	charging
}
var current_state = STATE.idle
var current_weapon = Globals.PROJECTILE_TYPES.ATTACK
var shoot_point_start = null

var default_font = DynamicFont.new()

var current_plant = null
onready var mana = Globals.INITIAL_PLAYER_MANA
onready var damage = Globals.INITIAL_PLAYER_DAMAGE


func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22

func init(nickname, start_position, plant):
	$gui/nickname.text = nickname
	global_position = start_position
	current_plant = plant

func summonPlant(power, direction):
	var summon = summon_class.instance()

	if mana < summon.mana_cost:
		return

	var offset = direction * WEAPON_RADIUS

	summon.position = position + offset
	summon.direction = direction
	summon.power = power
	summon.first_neighbor = current_plant

	# CREATE A BASE CLASS FOR PLAYER, INHERIT TO SOLO AND MULTIPLAYER INSTANCES
	get_node('/root/mainArena/').add_child(summon)


func addMana(increment):
	mana += increment

func attack(power, direction):
	var projectile = projectile_class.instance()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction
	projectile.power = power
	projectile.type = Globals.PROJECTILE_TYPES.ATTACK
	projectile.MAX_DAMAGE = damage

	# CREATE A BASE CLASS FOR PLAYER, INHERIT TO SOLO AND MULTIPLAYER INSTANCES
	get_node('/root/mainArena/').add_child(projectile)
	$animation.play('attack')

func _on_bow_released():
	current_weapon = Globals.PROJECTILE_TYPES.ATTACK
	$animation.set_animation('bow_0')
	$animation.set_frame(0)
	$animation.stop()

func _on_seed_released():
	current_weapon = Globals.PROJECTILE_TYPES.SUMMON
	$animation.set_animation('summon_0')
	$animation.set_frame(0)
	$animation.stop()

func _on_options_released():
	get_tree().paused = true
	$pauseScreen.visible = true
	$resumeRestart.visible = true
	$resumeRestart.set_process(true)
	$quit.visible = true
	$quit.set_process(true)

func _on_quit_released():
	get_tree().quit()

func _on_resumeRestart_released():
	current_state = STATE.idle
	if get_tree().paused:
		get_tree().paused = false
		$pauseScreen.visible = false
		$resumeRestart.visible = false
		$resumeRestart.set_process(false)
		$quit.visible = false
		$quit.set_process(false)
	if Globals.GAME_OVER:
		get_tree().reload_current_scene()

func pollInput():
	if Input.is_action_pressed('touch') and current_state != STATE.charging:
		current_state = STATE.charging
		shoot_point_start = get_global_mouse_position()

	if Input.is_action_just_released('touch') and current_state == STATE.charging:
		var shoot_length = (get_global_mouse_position() - shoot_point_start).length()
		shoot_length = shoot_length if shoot_length <= MAX_SHOOT_LENGTH else MAX_SHOOT_LENGTH
		var power = shoot_length/MAX_SHOOT_LENGTH
		$animation.set_frame(0)

		current_state = STATE.idle
		if power >= 0.2:
			var direction = (shoot_point_start - get_global_mouse_position()).normalized()
			if current_weapon == Globals.PROJECTILE_TYPES.ATTACK:
				attack(power, direction)
			if current_weapon == Globals.PROJECTILE_TYPES.SUMMON:
				summonPlant(power, direction)

			releaseAnimation()

func releaseAnimation():
	match current_weapon:
		Globals.PROJECTILE_TYPES.ATTACK:
			$animation.play('bow_1')
		Globals.PROJECTILE_TYPES.SUMMON:
			$animation.play('summon_1')

func setCurrentPlant(plant):
	if plant.is_queued_for_deletion() or not is_instance_valid(plant):
		Globals.gameOver()
	position = plant.position
	current_plant = plant
	damage = plant.projectile_damage

func getWeaponString():
	match current_weapon:
		0:
			return 'attack'
		1:
			return 'summon'

func _draw():
	if current_state != STATE.charging:
		return
	draw_circle(
		shoot_point_start - position,
		(get_global_mouse_position() - shoot_point_start).length(),
		Color(1, 1, 1, 0.25)
	)
	var color = Color(1, 1, 1) if (get_global_mouse_position() - shoot_point_start).length() < MAX_SHOOT_LENGTH else Color(1, 0, 0)
	draw_line(Vector2(0, 0), shoot_point_start - get_global_mouse_position(), color, 4.0)

func _on_animation_finished():
	var animation_name
	var part = 0 if current_state == STATE.idle else 1 
	match current_weapon:
		Globals.PROJECTILE_TYPES.ATTACK:
			animation_name = 'bow_' + str(part)
			$animation.set_animation(animation_name)
		Globals.PROJECTILE_TYPES.SUMMON:
			animation_name= 'summon_' + str(part)
			$animation.set_animation(animation_name)

	$animation.set_frame(0)
	$animation.stop()

func aimingLoop():
	if current_state != STATE.charging:
		return

	var reference = (shoot_point_start - get_global_mouse_position())
	if reference.length() < MIN_SHOOT_LENGTH:
		return
	var partial_power = (reference.length() - MIN_SHOOT_LENGTH)/MAX_SHOOT_LENGTH
	partial_power = partial_power if partial_power <= 1.0 else 1.0
	reference = reference.normalized()
	var frame = floor(partial_power * ANIMATION_FRAME_COUNT)
	$animation.set_frame(frame)
	if partial_power <= 0.2:
		return
	var angle = reference.angle() + PI/2.0
	$animation.rotation = angle

func updateGui():
	var message = 'MANA: ' + str(mana) + '\nSCORE: ' + str(Globals.score)
	$gui/label.set_text(message)

func _process(delta):
	updateGui()
	update()

master func _physics_process(delta):
	aimingLoop()
	pollInput()
