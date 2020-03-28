extends 'res://weapons/weapon.gd'

var plant_class = preload('res://plants/plant.tscn')
var mana_cost = 20.0
var first_neighbor

func _ready():
	MAX_TRAVEL_TIME = 0.25
	MAX_SPEED = 600.0
	._ready()

func travelEnded():
	var plant = plant_class.instance()
	plant.addNeighbor(first_neighbor)
	plant.position = position
	first_neighbor.addNeighbor(plant)
	get_node('/root/main/').add_child(plant)
	queue_free()

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		travelEnded()
