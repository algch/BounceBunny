extends StaticBody2D

onready var main = get_node('/root/main/')
onready var projectile_class = preload('res://weapons/projectile/projectile.tscn')
onready var player = get_node('/root/main/player')
onready var WEAPON_RADIUS = sqrt(pow($collisionShape.shape.extents.x, 2) + pow($collisionShape.shape.extents.y, 2)) + 24
var targets = {}
onready var attack_timer = get_node('attack_timer')
enum STATE {
	attacking,
	idle,
}
var current_state = STATE.idle
var DEFAULT_POWER = 0.5
var max_health = 3.0
var health = max_health
var health_recovery = 0.2
var default_font = DynamicFont.new()
var current_level = 1
var line_color = Color(0, 0, 1)
var projectile_damage = 0.5
var ready_for_development = false
var type = null

signal display_menu(plant)

func _on_score_timer_timeout():
	main.increaseScore()
	$score_timer.start()

func receiveDamage(damage):
	health -= damage

func destroy():
	if is_queued_for_deletion():
		return

	queue_free()

func healthLoop():
	if health <= 0:
		destroy()

func handleWeaponCollision(weapon):
	health -= weapon.damage
	
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
	projectile.MAX_DAMAGE = projectile_damage

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

func _on_attack_timer_timeout():
	attack(0.5)
	attack_timer.start()

func _on_health_timer_timeout():
	health += health_recovery
	if health > max_health:
		health = max_health
	$health_timer.start()

func setAnimation():
	var current_animation = $animation.get_animation()
	match current_level:
		1:
			if 'level_1' != current_animation:
				$animation.play('level_1')
		2:
			if 'level_2' != current_animation:
				$animation.play('level_2')
		3:
			if 'level_3' != current_animation:
				$animation.play('level_3')

func updateGui():
	var message = str(health) + '/' + str(max_health)
	$gui/container/label.set_text(message)
	var percentage = 100 * (health/max_health)
	$gui/container/bar.set_value(percentage)

func _process(_delta):
	updateGui()
	setAnimation()
	update()

func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22
	var gui = get_node("/root/main/CanvasLayer/gui")
	var _result = connect("display_menu", gui, "display_plant_menu")

func _physics_process(_delta):
	healthLoop()
	state_loop()

func state_loop():
	if not type:
		return

	
	# DEVELOP STATE MACHINE

func _on_development_timer_timeout():
	ready_for_development = true
	print("lista")
	$development_timer.stop()

func _on_plantMenu_released():
	if not ready_for_development:
		return

	emit_signal("display_menu", self)

func develop(selected_type):
	ready_for_development = false
	type = selected_type
	update_animation()

func update_animation():
	match type:
		globals.PLANT_TYPES.SPIKES:
			print("updated animation to spike")
		globals.PLANT_TYPES.POISON:
			print("updated animation to posion")
