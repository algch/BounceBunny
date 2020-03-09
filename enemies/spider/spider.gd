extends KinematicBody2D

var TYPE='enemy'

var SPEED = 100
var HALF_PI = PI/2.0

var red_texture = preload('res://enemies/spider/sprites/red_spider.png')
var green_texture = preload('res://enemies/spider/sprites/green_spider.png')
var blue_texture = preload('res://enemies/spider/sprites/blue_spider.png')

var teleport_class = preload('res://plants/teleport/teleport.tscn')


var movement_timer = Timer.new()

var targets = {}
var current_target = null

var motion_dir = Vector2(0, 0)
var rotation_speed = 0.5 # in degrees
var rotation_dir = 1

var colors = ['red', 'green', 'blue']
var COLOR = null
enum STATE {
	walk,
	rotate,
	walk_backwards,
	attack,
	FIND_TARGET,
}
var current_state = STATE.walk

var ATTACK_WAIT_TIME = 2
var attack_timer = Timer.new()

var damage = 1.0
var health = 300.0


onready var player = get_node('/root/main/player')

func _ready():
	randomize()
	var color = colors[randi() % 3]
	COLOR = color
	match color:
		'red':
			$sprite.set_texture(red_texture)
		'green':
			$sprite.set_texture(green_texture)
		'blue':
			$sprite.set_texture(blue_texture)
		_:
			$sprite.set_texture(red_texture)
	movement_timer.connect('timeout', self, 'setRandomMovementAction')
	var wait_time = randi() % 2 + 1
	movement_timer.set_wait_time(wait_time)
	movement_timer.start()
	add_child(movement_timer)

	attack_timer.connect('timeout', self, 'attack')
	add_child(attack_timer)

	motion_dir = Vector2(
		cos(rotation + HALF_PI),
		sin(rotation + HALF_PI)
	)


func handleWeaponCollision(weapon):
	# TODO involve color mechanics here
	health -= weapon.damage

	# LOOK AT WEAPON
	# if current_state != STATE.FIND_TARGET or current_state != STATE.attack:
	# 	var weapon_dir = (weapon.position - position).normalized()
	# 	if motion_dir.dot(weapon_dir) < 0:
	# 		rotation_dir = -1 if motion_dir.rotated(HALF_PI).dot(weapon_dir) < 0 else 1
	# 	current_state = STATE.FIND_TARGET

	weapon.queue_free()


func movementLoop(delta):
	match current_state:
		STATE.FIND_TARGET:
			var target_dir = (current_target.position - position).normalized()
			if motion_dir.dot(target_dir) > 0.75:
				current_state = STATE.attack
				return

			rotation += deg2rad(rotation_speed * rotation_dir)
			motion_dir = Vector2(
				cos(rotation + HALF_PI),
				sin(rotation + HALF_PI)
			)
		STATE.walk:
			var motion = motion_dir.normalized() * SPEED * delta

			var collision = move_and_collide(motion)

			if collision:
				current_state = STATE.rotate
		STATE.rotate:
			rotation += deg2rad(rotation_speed * rotation_dir)
			motion_dir = Vector2(
				cos(rotation + HALF_PI),
				sin(rotation + HALF_PI)
			)
		STATE.walk_backwards:
			print('walking backwards')
			var motion = motion_dir.normalized() * SPEED * -1
			move_and_slide(motion)
		_:
			return


# TODO replace these magic numbers
# and refator this function
func setRandomMovementAction():
	var selected_state = STATE.rotate if current_state == STATE.walk else STATE.walk
	var wait_time = 2
	movement_timer.set_wait_time(wait_time)
	movement_timer.start()
	if current_state == STATE.attack or current_state == STATE.FIND_TARGET:
		return

	rotation_dir = -1 if randi() % 2 == 0 else 1

	current_state = selected_state

func attack():
	current_target.receiveDamage(damage)
	attack_timer.set_wait_time(ATTACK_WAIT_TIME)
	attack_timer.start()

# TODO change this, it must work for the player and the support plants, crete group
func attackLoop():
	if current_target and not current_target.is_queued_for_deletion():
		var direction_to_target = current_target.position - position
		var dist_to_target = direction_to_target.length()
		var is_facing_target = direction_to_target.normalized().dot(motion_dir.normalized()) > 0

		if current_state == STATE.attack and attack_timer.is_stopped():
			attack_timer.set_wait_time(ATTACK_WAIT_TIME)
			attack_timer.start()

	else:
		if targets.empty():
			current_target = null
			attack_timer.stop()
			current_state = STATE.walk
		else:
			print(targets)
			current_target = targets[targets.keys()[0]]
			if current_target.is_queued_for_deletion():
				targets.erase(current_target.get_instance_id())
				current_target = null
				return
			current_state = STATE.FIND_TARGET
			var target_dir = (current_target.position - position).normalized()
			rotation_dir = -1 if motion_dir.rotated(HALF_PI).dot(target_dir.rotated(HALF_PI)) < 0 else 1


func _on_Area2D_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		targets[body.get_instance_id()] = body


func _on_Area2D_body_exited(body):
	targets.erase(body.get_instance_id())



func healthLoop():
	if health <= 0:
		# TODO leave loot
		queue_free()


func _physics_process(delta):
	healthLoop()
	movementLoop(delta)
	attackLoop()
