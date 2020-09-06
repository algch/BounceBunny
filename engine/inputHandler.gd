extends MarginContainer

onready var player = get_node("/root/main/player")
onready var main = get_node("/root/main")

var recalculate_move = false

func _on_inputHandler_gui_input(event):
	if not player:
		return

	_action(event)
	_aiming_loop()

func _action(event):
	match main.get_selected_action():
		globals.ACTIONS.MOVE:
			_handle_move_action(event)
		globals.ACTIONS.ATTACK:
			_handle_attack_action(event)
		globals.ACTIONS.PLANT:
			pass

func _handle_move_action(event):
	if event.is_action("touch") or recalculate_move:
		var direction = (get_global_mouse_position() - Vector2(360, 630)).normalized()
		player.direction = direction
		recalculate_move = true

	if event.is_action_released('touch'):
		player.direction = Vector2(0, 0)
		recalculate_move = false

func _handle_attack_action(event):
	if event.is_action_pressed('touch') and player.current_state != player.STATE.charging:
		player.current_state = player.STATE.charging
		player.shoot_point_start = get_global_mouse_position()

	if event.is_action_released('touch') and player.current_state == player.STATE.charging:
		var shoot_length = (get_global_mouse_position() - player.shoot_point_start).length()
		shoot_length = shoot_length if shoot_length <= player.MAX_SHOOT_LENGTH else player.MAX_SHOOT_LENGTH
		var power = shoot_length/player.MAX_SHOOT_LENGTH
		player.get_node("animation").set_frame(0)

		player.current_state = player.STATE.idle
		if power >= 0.2:
			var direction = (player.shoot_point_start - get_global_mouse_position()).normalized()
			if player.current_weapon == globals.PROJECTILE_TYPES.ATTACK:
				player.attack(power, direction)
			if player.current_weapon == globals.PROJECTILE_TYPES.SUMMON:
				player.summonPlant(power, direction)	

			player.releaseAnimation()

func _aiming_loop():
	if player.current_state != player.STATE.charging:
		return

	var reference = (player.shoot_point_start - get_global_mouse_position())
	var partial_power = reference.length()/player.MAX_SHOOT_LENGTH
	partial_power = partial_power if partial_power <= 1.0 else 1.0
	reference = reference.normalized()
	var frame = floor(partial_power * player.ANIMATION_FRAME_COUNT)
	player.get_node("animation").set_frame(frame)
	if partial_power <= 0.2:
		return
	var angle = reference.angle() + PI/2.0
	player.get_node("animation").rotation = angle
