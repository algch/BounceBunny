extends 'res://weapons/weapon.gd'

var support_class = preload('res://plants/support/support.tscn')
var teleport_class = preload('res://plants/teleport/teleport.tscn')
var score_class = preload('res://plants/score/score.tscn')

var selected_class

func _ready():
	MAX_TRAVEL_TIME = 0.25
	MAX_SPEED = 600.0
	match type:
		globals.ITEM_TYPES.TELEPORT:
			selected_class = teleport_class
		globals.ITEM_TYPES.SCORE:
			selected_class = score_class
		globals.ITEM_TYPES.SUPPORT:
			selected_class = support_class
	._ready()

func travelEnded():
	var summon = selected_class.instance()
	summon.position = position
	get_node('/root/main/').add_child(summon)
	queue_free()

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		travelEnded()
