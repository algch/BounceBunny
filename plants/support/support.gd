extends StaticBody2D

var projectile_class = preload('res://weapons/projectile/projectile.tscn')
var targets = {}
var WEAPON_RADIUS = 57
onready var attack_timer = get_node('attack_timer')
enum STATE {
	attacking,
	idle
}
var current_state = STATE.idle
var DEFAULT_POWER = 0.5

var health = 3.0


func receiveDamage(damage):
	health -= damage
	print('sporte atacado')

func attack(power):
	var target = targets[targets.keys()[randi() % targets.size()]]
	if target.is_queued_for_deletion():
		targets.erase(target.get_instance_id())
		return

	var projectile = projectile_class.instance()
	var direction = (target.position - position).normalized()
	var offset = direction * WEAPON_RADIUS

	projectile.position = position + offset
	projectile.direction = direction

	projectile.power = power

	get_node('/root/main/').add_child(projectile)

func _on_Area2D_body_entered(body):
	if body.is_in_group('enemies'):
		targets[body.get_instance_id()] = body
		if current_state != STATE.attacking:
			attack_timer.start()
			current_state = STATE.attacking

func _on_Area2D_body_exited(body):
	if body.is_in_group('enemies'):
		targets.erase(body.get_instance_id())
		if targets.empty():
			attack_timer.stop()
			current_state = STATE.idle

func handleWeaponCollision(weapon):
	health -= weapon.damage
	weapon.queue_free()

func _on_attack_timer_timeout():
	attack(0.5)
	attack_timer.start()

func healthLoop():
	if health <= 0:
		queue_free()

func _physics_process(delta):
	healthLoop()
