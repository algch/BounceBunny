extends KinematicBody2D

var SPEED = 500
var direction = Vector2(0, 0) setget set_direction, get_direction
var health = 5.0
var should_move = false

var TYPE = 'player'

# how far from the player will the projectile be placed
var WEAPON_RADIUS = 125
var motion_dir = Vector2(0, 0)
onready var projectile_class = preload('res://weapons/projectile/projectile.tscn')
onready var summon_class = preload('res://weapons/summon/summon.tscn')
onready var main = get_node('/root/main/')
var CHARGE_WAIT_TIME = 1.0
var MAX_SHOOT_LENGTH = 200
var ANIMATION_FRAME_COUNT = 14

enum STATE {
	idle,
	charging
}
var current_state = STATE.idle
var current_weapon = globals.PROJECTILE_TYPES.ATTACK
var selected_action = globals.ACTIONS.MOVE
var shoot_point_start = null

var default_font = DynamicFont.new()

var current_plant = null
var mana = 100.0

signal damage_received(current_health)

func set_direction(dir : Vector2):
	direction = dir
	$animation.rotation = dir.angle() + PI/2

func get_direction():
	return direction

func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22
	current_plant = get_node('/root/main/plant/')

	$pauseScreen.visible = false
	$resumeRestart.visible = false
	$resumeRestart.set_process(false)
	$quit.visible = false
	$quit.set_process(false)


func summonPlant(power, dir):
	var summon = summon_class.instance()

	if mana < summon.mana_cost:
		return

	var offset = dir * WEAPON_RADIUS

	summon.position = position + offset
	summon.direction = dir
	summon.power = power
	summon.first_neighbor = current_plant

	get_node('/root/main/').add_child(summon)
	mana -= summon.mana_cost

func addMana(increment):
	mana += increment

func attack(power, direction):
	var projectile = projectile_class.instance()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction
	projectile.power = power
	projectile.type = globals.PROJECTILE_TYPES.ATTACK

	get_node('/root/main/').add_child(projectile)
	$animation.play('attack')

func _on_bow_released():
	current_weapon = globals.PROJECTILE_TYPES.ATTACK
	$animation.set_animation('bow_0')
	$animation.set_frame(0)
	$animation.stop()

func _on_seed_released():
	current_weapon = globals.PROJECTILE_TYPES.SUMMON
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
	if main.GAME_OVER:
		get_tree().reload_current_scene()

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

func _physics_process(_delta):
	if not should_move:
		return

	var motion = direction * SPEED
	var _res = move_and_slide(motion)

func receiveDamage(damage):
	health -= damage
	emit_signal("damage_received", health)
