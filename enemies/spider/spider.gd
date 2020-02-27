extends KinematicBody2D

var TYPE='enemy'

var SPEED = 100

var red_texture = preload('res://enemies/spider/sprites/red_spider.png')
var green_texture = preload('res://enemies/spider/sprites/green_spider.png')
var blue_texture = preload('res://enemies/spider/sprites/blue_spider.png')

var teleport_class = preload('res://plants/teleport/teleport.tscn')


var movement_timer = Timer.new()

var motion_dir = Vector2(0, 0)

var colors = ['red', 'green', 'blue']
var COLOR = null

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
	movement_timer.connect('timeout', self, 'resetMovementTimer')
	resetMovementTimer()
	add_child(movement_timer)

func handleWeaponCollision(collider):
	if collider.COLOR == COLOR:
		var teleport = teleport_class.instance()
		teleport.position = position
		get_parent().add_child(teleport)
		queue_free()
	else:
		SPEED += 50

	collider.queue_free()

func resetMovementTimer():
	movement_timer.set_wait_time(5)
	movement_timer.start()
	motion_dir = getRandomDir()

# HEY game logic here, abstract this to a separated class or something
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
	if is_on_wall():
		motion_dir = getRandomDir()

	if movement_timer.get_time_left() <= 4:
		var motion = motion_dir.normalized() * SPEED * delta
		var collision = move_and_collide(motion)

		if collision:
			var collider = collision.collider
			var collider_type = collider.get('TYPE')
			if collider_type == 'player':
				collider.queue_free()
				print('game over')




func _physics_process(delta):
	movementLoop(delta)
