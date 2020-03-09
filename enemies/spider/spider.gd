extends KinematicBody2D

var TYPE='enemy'

var SPEED = 100
var HALF_PI = PI/2.0

var red_texture = preload('res://enemies/spider/sprites/red_spider.png')
var green_texture = preload('res://enemies/spider/sprites/green_spider.png')
var blue_texture = preload('res://enemies/spider/sprites/blue_spider.png')

var teleport_class = preload('res://plants/teleport/teleport.tscn')


var movement_timer = Timer.new()

var reachable_targets = {}
var visible_targets = {}
var current_target = null

var motion_dir = Vector2(1, 0)
var facing_dir = Vector2(0, 1)
var rotation_speed = 1 # in degrees
var rotation_dir = 1

var colors = ['red', 'green', 'blue']
var COLOR = null
enum STATE {
	walk,
	rotate,
	walk_backwards,
	attack,
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
	# STATE TRANSITION IS WRONG, THE SPIDER SHOULD FOLLOW ITS CURRENT TARGET
	match current_state:
		STATE.walk:
			var motion = motion_dir.normalized() * SPEED * delta
			if abs(motion_dir.angle() - facing_dir.angle()) > HALF_PI/8.0:
				motion_dir = motion_dir.rotated(deg2rad(rotation_speed * rotation_dir))
			
			print('facing angle = ', facing_dir.angle())

			var collision = move_and_collide(motion)
			rotation = facing_dir.angle() - HALF_PI

			# if collision:
			# 	current_state = STATE.rotate
			# 	print('collided, rotating')
		STATE.rotate:
			facing_dir = facing_dir.rotated(deg2rad(rotation_speed * rotation_dir))
			rotation = facing_dir.angle() - HALF_PI
		STATE.walk_backwards:
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
	if current_state == STATE.attack:
		return

	rotation_dir = -1 if randi() % 2 == 0 else 1

	current_state = selected_state

func attack():
	current_target.receiveDamage(damage)
	attack_timer.set_wait_time(ATTACK_WAIT_TIME)
	attack_timer.start()

func attackLoop():
	if current_target and not current_target.is_queued_for_deletion():
		if current_target.get_instance_id() in reachable_targets:
			if current_state != STATE.attack:
				attack_timer.set_wait_time(ATTACK_WAIT_TIME)
				attack_timer.start()
				current_state = STATE.attack
		else:
			var motion_dir = (current_target.position - position).normalized()
			STATE.walk

		return

	current_target = null
	if not attack_timer.is_stopped():
		attack_timer.stop()

	if reachable_targets.empty():
		if visible_targets.empty():
			current_state = STATE.walk
		while not visible_targets.empty():
			var possible_target = visible_targets[visible_targets.keys()[0]]
			if possible_target.is_queued_for_deletion():
				visible_targets.erase(possible_target.get_instance_id())
			else:
				current_target = possible_target
				break
	else:
		while not reachable_targets.empty():
			var possible_target = reachable_targets[reachable_targets.keys()[0]]
			if possible_target.is_queued_for_deletion():
				reachable_targets.erase(possible_target.get_instance_id())
			else:
				current_target = possible_target
				break


func on_attackArea_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		reachable_targets[body.get_instance_id()] = body


func on_attackArea_body_exited(body):
	if body.is_in_group('attacked_by_enemies'):
		reachable_targets.erase(body.get_instance_id())


func on_visionArea_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		visible_targets[body.get_instance_id()] = body


func on_visionArea_body_exited(body):
	if body.is_in_group('attacked_by_enemies'):
		visible_targets.erase(body.get_instance_id())


func healthLoop():
	if health <= 0:
		# TODO leave loot
		queue_free()

func getStateName(state):
	match state:
		0:
			return 'walk'
		1:
			return 'rotate'
		2:
			return 'walk_backwards'
		3:
			return 'attack'
		_:
				return ''

func _draw():
	draw_line(Vector2(0, 0), Vector2(0, 0) + motion_dir*200, Color(1, 0, 0))
	draw_line(Vector2(0, 0), Vector2(0, 0) + facing_dir*200, Color(0.75, 0, 0.9))
	var label = Label.new()
	var font = label.get_font('')
	draw_string(font, Vector2(0, -80), getStateName(current_state), Color(1, 1, 1))


func _process(delta):
	update()


func _physics_process(delta):
	healthLoop()
	movementLoop(delta)
	attackLoop()
