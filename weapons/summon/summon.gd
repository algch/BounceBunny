extends 'res://weapons/weapon.gd'

var support_class = preload('res://plants/support/support.tscn')

func _ready():
	MAX_TRAVEL_TIME = 0.5
	._ready()

func travelEnded():
	var support = support_class.instance()
	support.position = position
	get_node('/root/main/').add_child(support)
	queue_free()

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		travelEnded()
