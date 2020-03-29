extends KinematicBody2D

var SPEED = 300
var HALF_PI = PI/2.0

onready var main = get_node('/root/main/')

var mana_class = preload('res://items/mana/mana.tscn')
var spider_class = preload('res://enemies/spider/spider.tscn')

var direction_timer = Timer.new()

var current_chaser = null

var motion_dir = Vector2(-1, 0)
var facing_dir = Vector2(0, 1)
var rotation_speed = 90 # in degrees
var rotation_dir = 1

enum STATE {
	WANDER,
	ESCAPE,
}
var current_state = STATE.WANDER

var health = 20.0

var default_font = DynamicFont.new()
var DIRECTION_CHANGE_INTERVAL = 3.0
var MAX_SPIDERS = 25


onready var player = get_node('/root/main/player')

func _ready():
	randomize()
	direction_timer.connect('timeout', self, 'changeDirection')
	direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
	direction_timer.start()
	add_child(direction_timer)

	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22

func handleWeaponCollision(weapon):
	health -= weapon.damage

	weapon.queue_free()


func escapeLoop(delta):
	if not main.GAME_OVER and current_chaser and not current_chaser.is_queued_for_deletion():
		motion_dir = (position - current_chaser.position).normalized()

	wanderLoop(delta)


func _on_detectionArea_area_entered(area):
	if area.is_in_group('detected_by_spawner'):
		current_chaser = area
		current_state = STATE.ESCAPE


func _on_detectionArea_area_exited(area):
	if area.is_in_group('detected_by_spawner'):
		current_chaser = null
		current_state = STATE.WANDER


func _on_spawn_timer_timeout():
	if len(get_tree().get_nodes_in_group('enemies')) >= MAX_SPIDERS:
		return
	var spider = spider_class.instance()
	spider.position = position
	main.add_child(spider)


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
			return 'ESCAPE'
		_:
				return ''

func _draw():
	# draw_line(Vector2(0, 0), Vector2(0, 0) + motion_dir*200, Color(0, 1, 0.5))
	# draw_line(Vector2(0, 0), Vector2(0, 0) + facing_dir*200, Color(1, 1, 0))
	# var left_side = facing_dir.rotated(-HALF_PI)
	# draw_line(Vector2(0, 0), Vector2(0, 0) + left_side*200, Color(1, 1, 1))
	var message = 'state: ' + getStateName(current_state) + 'health: ' + str(health)
	draw_string(default_font, Vector2(0, -80),  message, Color(1, 1, 1))


func _process(delta):
	update()


func changeDirection():
	direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
	direction_timer.start()

	var angle = randf() * HALF_PI/2.0 * rotation_dir

	motion_dir = motion_dir.rotated(angle)


func updateFacingDirLoop(delta):
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
	$sprite.rotation = angle


func wanderLoop(delta):
	if direction_timer.is_stopped():
		direction_timer.set_wait_time(DIRECTION_CHANGE_INTERVAL)
		direction_timer.start()

	var motion = motion_dir.normalized() * SPEED * delta
	updateFacingDirLoop(delta)

	# how can we handle collisions properly?
	var collision = move_and_collide(motion)
	if collision:
		print('collision ', self, ' collided with ', collision.collider)
		motion_dir *= -1


func behaviorLoop(delta):
	match current_state:
		STATE.WANDER:
			wanderLoop(delta)
		STATE.ESCAPE:
			escapeLoop(delta)
		_:
			return


func _physics_process(delta):
	healthLoop()
	behaviorLoop(delta)
