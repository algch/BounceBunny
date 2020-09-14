extends StaticBody2D

enum STATE {
	GROWING,
	MENACED,
	IDLE,
}

var current_state = STATE.GROWING setget set_current_state
var targets = {}
var growth_timer = Timer.new()
var should_show_menu = false
var type = globals.PLANT_TYPES.SPROUT
onready var type_2_handler = {
	globals.PLANT_TYPES.SPROUT: $Types/Sprout,
	globals.PLANT_TYPES.ARROWS: $Types/Arrows,
	globals.PLANT_TYPES.SPIKES: $Types/Spikes,
	globals.PLANT_TYPES.POISON: $Types/Poison,
}
var health = globals.MAX_PLANT_HEALTH


func _ready():
	begin_growth()

func _physics_process(_delta):
	health_loop()
	behavior_loop()

func behavior_loop():
	var handler = type_2_handler[type]
	match current_state:
		STATE.GROWING:
			handler.handle_growing(self)
		STATE.MENACED:
			handler.handle_menaced(self)
		STATE.IDLE:
			handler.handle_idle(self)

func begin_growth():
	growth_timer.connect("timeout", self, "_on_growth_timer_timeout")
	growth_timer.set_wait_time(globals.PLANT_GROWTH_TIME)
	add_child(growth_timer)
	growth_timer.start()

func _on_growth_timer_timeout():
	print("growth timer timed out")
	growth_timer.queue_free()
	should_show_menu = true
	set_current_state(STATE.IDLE)

	if targets:
		set_current_state(STATE.MENACED)

func _on_MenuButton_released():
	if not should_show_menu:
		return

	display_plant_menu()

func convert_to_type(selected_type):
	should_show_menu = false
	type = selected_type

func set_current_state(state):
	current_state = state

func handle_enemy_entered(enemy):
	targets[enemy.get_instance_id()] = enemy

	if current_state == STATE.GROWING:
		return

	set_current_state(STATE.MENACED)

func handle_enemy_exited(enemy):
	targets.erase(enemy.get_instance_id())

	if not targets:
		set_current_state(STATE.IDLE)

func health_loop():
	if health <= 0:
		destroy()

func destroy():
	if is_queued_for_deletion():
		return

	queue_free()

func _on_Area2D_body_entered(body):
	if body.is_in_group('enemies'):
		handle_enemy_entered(body)

func _on_Area2D_body_exited(body):
	if body.is_in_group('enemies'):
		handle_enemy_exited(body)

func receiveDamage(damage):
	health -= damage

func display_plant_menu():
	$CanvasLayer/Menu.visible = true

func _on_spikes_pressed():
	_develop_plant(globals.PLANT_TYPES.SPIKES)

func _on_poison_pressed():
	_develop_plant(globals.PLANT_TYPES.POISON)

func _on_arrows_pressed():
	_develop_plant(globals.PLANT_TYPES.ARROWS)

func _develop_plant(plant_type):
	convert_to_type(plant_type)
	$CanvasLayer/Menu.visible = false
