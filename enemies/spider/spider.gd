extends KinematicBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var SPEED = 50

var red_texture = preload('res://enemies/spider/sprites/red_spider.png')
var green_texture = preload('res://enemies/spider/sprites/green_spider.png')
var blue_texture = preload('res://enemies/spider/sprites/blue_spider.png')


var movement_timer = Timer.new()

var motion_dir = Vector2(0, 0)

var color = 'red'

func _ready():
	randomize()
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


func movementLoop():
	if is_on_wall():
		motion_dir = getRandomDir()

	if movement_timer.get_time_left() <= 4:
		var motion = motion_dir.normalized() * SPEED
		move_and_slide(motion)



func _physics_process(delta):
	movementLoop()
