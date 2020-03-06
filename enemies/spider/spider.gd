extends KinematicBody2D

var TYPE='enemy'

var SPEED = 100

var red_texture = preload('res://enemies/spider/sprites/red_spider.png')
var green_texture = preload('res://enemies/spider/sprites/green_spider.png')
var blue_texture = preload('res://enemies/spider/sprites/blue_spider.png')

var teleport_class = preload('res://plants/teleport/teleport.tscn')


var movement_timer = Timer.new()

var motion_dir = Vector2(0, 0)
var rotation_speed = 0.5 # in degrees

var colors = ['red', 'green', 'blue']
var COLOR = null
enum STATE {
	walk,
	rotate,
	walk_backwards,
	attack
}
var current_state = STATE.walk

var ATTACK_WAIT_TIME = 2
var attack_timer = Timer.new()

var damage = 1
var health = 3


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
		cos(rotation + PI/2.0),
		sin(rotation + PI/2.0)
	)


func handleWeaponCollision(collider):
	# TODO involve color mechanics here
	health -= collider.damage
	collider.queue_free()


# TODO game logic here, move this to a separated class
func getRandomDir():
	var randX
	match randi() % 2:
		0:
			randX = -1
		1:
			randX = 1
			
	var randY
	match randi() % 4:
		0:
			randY = 0
		1:
			randY = 1
		2:
			randY = 1
		3:
			randY = 1
	return Vector2(randX, randY)


func movementLoop(delta):
	match current_state:
		STATE.walk:
			var motion = motion_dir.normalized() * SPEED * delta

			var collision = move_and_collide(motion)

			if collision:
				print('collided')
				current_state = STATE.rotate
		STATE.rotate:
			rotation += deg2rad(rotation_speed)
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
	if current_state == STATE.attack:
		return

	motion_dir = Vector2(
		cos(rotation + PI/2.0),
		sin(rotation + PI/2.0)
	)
	rotation_speed *= -1 if randi() % 2 == 0 else 1

	current_state = selected_state

func attack():
	if not player:
		return
	player.receiveDamage(damage)
	attack_timer.set_wait_time(ATTACK_WAIT_TIME)
	attack_timer.start()

func attackLoop():
	if not player:
		return

	var direction_to_player = player.position - position
	var dist_to_player = direction_to_player.length()
	var is_facing_player = direction_to_player.normalized().dot(motion_dir.normalized()) > 0

	if current_state == STATE.attack:
		if dist_to_player >= 160:
			current_state = STATE.walk
			attack_timer.stop()
		else:
			return

	if dist_to_player < 160 and is_facing_player:
		print('setting state to attack')
		current_state = STATE.attack
		attack_timer.set_wait_time(ATTACK_WAIT_TIME)
		attack_timer.start()

func healthLoop():
	if health <= 0:
		# TODO leave loot
		queue_free()


func _physics_process(delta):
	healthLoop()
	movementLoop(delta)
	attackLoop()
