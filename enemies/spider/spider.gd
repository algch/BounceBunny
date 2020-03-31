extends KinematicBody2D

onready var player = get_node('/root/main/player')
onready var main = get_node('/root/main')

onready var speed = main.MAX_SPIDER_SPEED
onready var damage = main.MAX_SPIDER_DAMAGE
onready var max_health = main.MAX_SPIDER_HEALTH
onready var health = main.MAX_SPIDER_HEALTH

var HALF_PI = PI/2.0

var mana_class = preload('res://items/mana/mana.tscn')

var direction_timer = Timer.new()

var reachable_targets = {}
var visible_targets = {}
var current_target = null

var motion_dir = Vector2(-1, 0)
var facing_dir = Vector2(0, 1)
var rotation_speed = 90 # in degrees
var rotation_dir = 1

enum STATE {
	WANDER,
	CHASE,
	ATTACK,
}
var current_state = STATE.WANDER
var is_attacking = false



var default_font = DynamicFont.new()
var DIRECTION_CHANGE_INTERVAL = 3.0



func _ready():
	randomize()
	direction_timer.connect('timeout', self, 'changeDirection')
	var wait_time = randi() % 2 + 1
	direction_timer.set_wait_time(wait_time)
	direction_timer.start()
	add_child(direction_timer)

	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22
	$animation.play('walk')

func handleWeaponCollision(weapon):
	health -= weapon.damage

func updateGui():
	var message = str(health) + '/' + str(max_health)
	$gui/container/label.set_text(message)
	var percentage = 100 * (health/max_health)
	$gui/container/bar.set_value(percentage)

func chaseLoop(delta):
	# Handle this in a better way
	if not direction_timer.is_stopped():
		direction_timer.stop()

	if current_target and not current_target.is_queued_for_deletion():

		motion_dir = (current_target.position - position).normalized()
		var motion = motion_dir.normalized() * speed * delta

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
		$animation.play('walk')
		return

	while not visible_targets.empty():
		var target = visible_targets[visible_targets.keys()[0]]
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			current_target = target
			break
		else:
			visible_targets.erase(target.get_instance_id())

func _on_animation_animation_finished():
	var current_animation = $animation.get_animation()
	match current_animation:
		'attack':
			if is_instance_valid(current_target) and not current_target.is_queued_for_deletion():
				current_target.receiveDamage(damage)
				$animation.play('walk')
				is_attacking = false

func attack():
	$animation.play('attack')

func attackLoop(delta):
	if not direction_timer.is_stopped():
		direction_timer.stop()

	if current_target and not current_target.is_queued_for_deletion():
		if not is_attacking:
			is_attacking = true
			attack()
		motion_dir = (current_target.position - position).normalized()
		updateFacingDir(delta)
	else:
		is_attacking = false
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


func _on_attackArea_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		var body_id = body.get_instance_id()
		reachable_targets[body_id] = body

		if not current_target:
			motion_dir = (body.position - position).normalized()
			current_state = STATE.ATTACK


func _on_attackArea_body_exited(body):
	var body_id = body.get_instance_id()
	if current_target and current_target.get_instance_id() == body_id:
		current_target = null
	if body.is_in_group('attacked_by_enemies') and reachable_targets.has(body_id):
		reachable_targets.erase(body_id)


func _on_visionArea_body_entered(body):
	if body.is_in_group('attacked_by_enemies'):
		var body_id = body.get_instance_id()
		visible_targets[body_id] = body

		if not current_target:
			motion_dir = (body.position - position).normalized()
			current_state = STATE.CHASE


func _on_visionArea_body_exited(body):
	var body_id = body.get_instance_id()
	if current_target and current_target.get_instance_id() == body_id:
		current_target = null
	if visible_targets.has(body_id):
		visible_targets.erase(body_id)


func leaveLoot():
	if globals.calculateChance(0.50):
		var mana = mana_class.instance()
		mana.position = position
		get_parent().add_child(mana)


func healthLoop():
	if health <= 0:
		queue_free()
		leaveLoot()


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


func _process(delta):
	updateGui()


func changeDirection():
	direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
	direction_timer.start()

	var angle = randf() * HALF_PI/2.0 * rotation_dir

	motion_dir = motion_dir.rotated(angle)


func updateFacingDir(delta):
	var left_side = facing_dir.rotated(-HALF_PI)
	var is_on_left = left_side.normalized().dot(motion_dir.normalized()) >= 0
	if is_on_left:
		rotation_dir = -1
	else:
		rotation_dir = 1

	var angle_diff = rad2deg(motion_dir.angle() - facing_dir.angle())
	if abs(angle_diff) > 2:
		facing_dir = facing_dir.rotated(deg2rad(rotation_speed * rotation_dir * delta))

	var angle = facing_dir.angle() - HALF_PI
	
	$animation.rotation = angle
	$visionArea.rotation = angle


func wanderLoop(delta):
	if direction_timer.is_stopped():
		direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
		direction_timer.start()

	var motion = motion_dir.normalized() * speed * delta
	updateFacingDir(delta)

	# how can we handle collisions properly?
	var collision = move_and_collide(motion)
	if collision:
		motion_dir = motion_dir.rotated(HALF_PI*rotation_dir)


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
