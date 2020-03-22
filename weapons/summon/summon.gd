extends 'res://weapons/weapon.gd'

var plant_class = preload('res://plants/plant.tscn')

func _ready():
	MAX_TRAVEL_TIME = 0.25
	MAX_SPEED = 600.0
	._ready()

func travelEnded():
	var summon = plant_class.instance()
	summon.position = position
	get_node('/root/main/').add_child(summon)
	queue_free()

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		travelEnded()
