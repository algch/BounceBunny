extends KinematicBody2D


var direction = Vector2(0,0)
var distance_to_tip

var power # power factor, range: [0, 1]

var MAX_SPEED = 1000.0
var speed
var MAX_DAMAGE = 3.0
var damage
var MAX_TRAVEL_TIME = 2.0
var travel_time

var type = null

var travel_timer = Timer.new()


func _ready():
	rotation = direction.angle() + PI/2.0
	distance_to_tip = Vector2(0, 0).distance_to($tip.position)

	speed = MAX_SPEED * power
	damage = MAX_DAMAGE * power
	travel_time = MAX_TRAVEL_TIME * power

	travel_timer.set_wait_time(travel_time)
	travel_timer.connect('timeout', self, 'travelEnded')
	travel_timer.start()
	add_child(travel_timer)
	print('damage ', damage)


func travelEnded():
    print('NOT IMPLEMENTED')


func getTipPosition():
	var tip_pos = direction * distance_to_tip
	return position + tip_pos
