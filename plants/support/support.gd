extends StaticBody2D

var projectile_class = preload('res://weapons/projectile.tscn')
var targets = {}
var WEAPON_RADIUS = 57
onready var attack_timer = get_node('attack_timer')
enum STATE {
	attacking,
	idle
}
var current_state = STATE.idle
var travel_time = 1.0

func attack():
	var target = targets[targets.keys()[randi() % targets.size()]]
	var projectile = projectile_class.instance()
	var direction = (target.position - position).normalized()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction
	projectile.travel_time = travel_time

	get_node('/root/main/').add_child(projectile)

func _on_Area2D_body_entered(body):
	if body.get('TYPE') == 'enemy':
		targets[body.get_instance_id()] = body
		if current_state != STATE.attacking:
			attack_timer.start()
			current_state = STATE.attacking

func _on_Area2D_body_exited(body):
	if body.get('TYPE') == 'enemy':
		targets.erase(body.get_instance_id())
		if targets.empty():
			attack_timer.stop()
			current_state = STATE.idle


func _on_attack_timer_timeout():
	attack()
	attack_timer.start()
