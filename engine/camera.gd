extends Camera2D

var target = null

func _ready():
	get_parent().connect('local_player_initialized', self, 'setTarget')

func _physics_process(delta):
	if not target:
		position = Vector2(0, 0)
		return
	position = target.position

func setTarget(new_target):
	target = new_target
