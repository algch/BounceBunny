extends KinematicBody2D

var TYPE='enemy'

var SPEED = 100
var HALF_PI = PI/2.0

var red_texture = preload('res://enemies/spider/sprites/red_spider.png')
var green_texture = preload('res://enemies/spider/sprites/green_spider.png')
var blue_texture = preload('res://enemies/spider/sprites/blue_spider.png')

var teleport_class = preload('res://plants/teleport/teleport.tscn')


var direction_timer = Timer.new()

var reachable_targets = {}
var visible_targets = {}
var current_target = null

var motion_dir = Vector2(-1, 0)
var facing_dir = Vector2(0, 1)
var rotation_speed = 90 # in degrees
var rotation_dir = 1

var colors = ['red', 'green', 'blue']
var COLOR = null
enum STATE {
	WANDER,
	CHASE,
	ATTACK,
}
var current_state = STATE.WANDER

var ATTACK_WAIT_TIME = 2
var attack_timer = Timer.new()

var damage = 1.0
var health = 3.0

var default_font = DynamicFont.new()
var DIRECTION_CHANGE_INTERVAL = 3.0


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
	direction_timer.connect('timeout', self, 'changeDirection')
	var wait_time = randi() % 2 + 1
	direction_timer.set_wait_time(wait_time)
	direction_timer.start()
	add_child(direction_timer)

	attack_timer.connect('timeout', self, 'attack')
	add_child(attack_timer)

	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22



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


func chaseLoop(delta):
	# Handle this in a better way
	if not direction_timer.is_stopped():
		direction_timer.stop()

	if current_target and not current_target.is_queued_for_deletion():

		motion_dir = (current_target.position - position).normalized()
		var motion = motion_dir.normalized() * SPEED * delta

		updateFacingDir(delta)

		var collision = move_and_collide(motion)

		var target_id = current_target.get_instance_id()
		if reachable_targets.has(target_id):
			current_state = STATE.ATTACK
			return
		if not visible_targets.has(target_id):
			current_target = null

	if visible_targets.empty():
		current_state = STATE.WANDER
		return

	while not visible_targets.empty():
		var target = visible_targets[visible_targets.keys()[0]]
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			current_target = target
			break
		else:
			visible_targets.erase(target.get_instance_id())



func attack():
	current_target.receiveDamage(damage)
	attack_timer.set_wait_time(ATTACK_WAIT_TIME)
	attack_timer.start()

func attackLoop(delta):
	# Handle this in a better way
	if not direction_timer.is_stopped():
		direction_timer.stop()

	if current_target and not current_target.is_queued_for_deletion():
		if attack_timer.is_stopped():
			attack_timer.set_wait_time(ATTACK_WAIT_TIME)
			attack_timer.start()
		updateFacingDir(delta)
	else:
		attack_timer.stop()
		current_target = null

	if reachable_targets.empty():
		current_state = STATE.CHASE
		return

	while not reachable_targets.empty():
		var target = reachable_targets[reachable_targets.keys()[0]]
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			current_target = target
			break
		else:
			reachable_targets.erase(target.get_instance_id())


func on_attackArea_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		var body_id = body.get_instance_id()
		reachable_targets[body_id] = body

		if not current_target:
			current_state = STATE.ATTACK


func on_attackArea_body_exited(body):
	var body_id = body.get_instance_id()
	if current_target and current_target.get_instance_id() == body_id:
		current_target = null
	if body.is_in_group('attacked_by_enemies') and reachable_targets.has(body_id):
		reachable_targets.erase(body_id)


func on_visionArea_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		var body_id = body.get_instance_id()
		visible_targets[body_id] = body

		if not current_target:
			current_state = STATE.CHASE


func on_visionArea_body_exited(body):
	var body_id = body.get_instance_id()
	if current_target and current_target.get_instance_id() == body_id:
		current_target = null
	if visible_targets.has(body_id):
		visible_targets.erase(body_id)


func healthLoop():
	if health <= 0:
		# TODO leave loot
		queue_free()

func getStateName(state):
	match state:
		0:
			return 'WANDER'
		1:
			return 'CHASE'
		2:
			return 'ATTACK'
		_:
				return ''

func _draw():
	draw_line(Vector2(0, 0), Vector2(0, 0) + motion_dir*200, Color(0, 1, 0.5))
	draw_line(Vector2(0, 0), Vector2(0, 0) + facing_dir*200, Color(1, 1, 0))
	var message = 'state: ' + getStateName(current_state) + ' rotation: ' + str(rad2deg($sprite.rotation))
	draw_string(default_font, Vector2(-200, -80),  message, Color(1, 1, 1))


func _process(delta):
	update()

func changeDirection():
	direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
	direction_timer.start()

	var angle = randf() * HALF_PI/2.0 * rotation_dir

	motion_dir = motion_dir.rotated(angle)

func updateFacingDir(delta):
	# this function has a bug
	var angle_diff = rad2deg(motion_dir.angle() - facing_dir.angle())
	rotation_dir = -1 if angle_diff <= 0 else 1
	if abs(angle_diff) > 2:
		facing_dir = facing_dir.rotated(deg2rad(rotation_speed * rotation_dir * delta))

	var angle = facing_dir.angle() - HALF_PI
	
	$sprite.rotation = angle
	$visionArea.rotation = angle


func wanderLoop(delta):
		if direction_timer.is_stopped():
			direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
			direction_timer.start()

		var motion = motion_dir.normalized() * SPEED * delta
		updateFacingDir(delta)

		# how can we handle collisions properly?
		var collision = move_and_collide(motion)
		# if collision:
		# 	motion_dir *= -1


func behaviorLoop(delta):
	match current_state:
		STATE.WANDER:
			wanderLoop(delta)
		STATE.CHASE:
			chaseLoop(delta)
		STATE.ATTACK:
			attackLoop(delta)
		_:
			return


func _physics_process(delta):
	healthLoop()
	behaviorLoop(delta)
