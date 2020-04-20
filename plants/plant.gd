extends StaticBody2D

onready var main = get_node('/root/mainArena/')
onready var projectile_class = preload('res://weapons/projectile/projectile.tscn')
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
var neighbor_ids = []
var projectile_damage = 0.5
var network_id
var server_instance_id


# DOES NOT APPLY TO MULTIPLAYER, CREATE A BASE CLASS PER PLANT WITH NETWORKING FUNCTIONS
func _on_score_timer_timeout():
	return # D:
	main.increaseScore()
	$score_timer.start()

func getLocalPlayer():
	print('network_id ', network_id)
	return get_node('/root/mainArena/' + str(network_id))

func receiveDamage(damage):
	health -= damage

remotesync func destroy():
	var player = getLocalPlayer()
	if is_queued_for_deletion():
		return

	var neighbor_ids = main.getNeighborIds(network_id, get_instance_id())

	if get_instance_id() == player.current_plant:
		if neighbor_ids:
			var plant = instance_from_id(neighbor_ids[0])
			player.rpc('setCurrentPlant', server_instance_id, plant.position, plant.projectile_damage)
		else:
			main.gameOver()

	main.removeNode(network_id, get_instance_id())
	for neighbor_id in neighbor_ids:
		main.removeIfDetached(network_id, neighbor_id)

	queue_free()

func healthLoop():
	# TODO if this happens in the server instance, then do destroy, don't do it otherwise
	if not get_tree().is_network_server():
		return
	if health <= 0:
		rpc('destroy')

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

func _on_teleport_released():
	var player = getLocalPlayer()
	if player.current_plant == get_instance_id():
		return
	player.rpc('setCurrentPlant', server_instance_id, position, projectile_damage)

func _draw():
	draw_string(default_font, Vector2(0, -200), str(get_instance_id()), Color(1, 0, 0.8))
	for neighbor_id in neighbor_ids:
		var neighbor = instance_from_id(neighbor_id)
		if neighbor and is_instance_valid(neighbor) and not neighbor.is_queued_for_deletion():
			draw_line(Vector2(0, 0), neighbor.position - position, line_color, 2)

func heal():
	health += health_recovery
	if health > max_health:
		health = max_health

func _on_health_timer_timeout():
	heal()
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

func updateCurrentLevel():
	var neighbor_ids_count = len(neighbor_ids)
	if neighbor_ids_count <= 1:
		current_level = 1
		max_health = 3.0
		line_color = Color(0, 0, 1)
		projectile_damage = 0.5
	if neighbor_ids_count > 1 and neighbor_ids_count < 4:
		current_level = 2
		max_health = 4.0
		line_color = Color(0, 1, 0)
		projectile_damage = 1.5
	if neighbor_ids_count >= 4:
		current_level = 3
		max_health = 5.0
		line_color = Color(1, 0, 0)
		projectile_damage = 2.5
		
	if health > max_health:
		health = max_health

func updateGui():
	var message = str(health) + '/' + str(max_health)
	$gui/container/label.set_text(message)
	var percentage = 100 * (health/max_health)
	$gui/container/bar.set_value(percentage)

func _process(delta):
	updateGui()
	setAnimation()
	update()

func addNeighbor(neighbor):
	neighbor_ids.append(neighbor.get_instance_id())
	updateCurrentLevel()
	print(str(get_instance_id()) + 'neighbor ids ', neighbor_ids)

func _ready():
	default_font.font_data = load('res://fonts/default-font.ttf')
	default_font.size = 22
	set_network_master(int(network_id))
	print('plant ' + str(get_instance_id()) + ' net id ' + str(network_id))

func init(pos, net_id, server_id):
	position = pos
	network_id = int(net_id)
	server_instance_id = server_id

func _physics_process(delta):
	healthLoop()
