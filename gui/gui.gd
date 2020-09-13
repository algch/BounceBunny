extends Control

signal action_changed(direction)

var affected_plant = null

func _on_swipeDetector_swipe(swipe_direction : Vector2):
	var x_swipe : = int(swipe_direction.x)
	if x_swipe != 0:
		emit_signal("action_changed", int(x_swipe))

func action_selector_left():
	pass

func action_selector_right():
	pass

func _on_swipeDetector_swipe_canceled(position_start : Vector2):
	print("swipe canceled")

func _on_TextureButton_pressed():
	print("pause")

func display_plant_menu(plant):
	$plantMenu.visible = true
	affected_plant = plant

func _on_spikes_pressed():
	_develop_affected_plant(globals.PLANT_TYPES.SPIKES)

func _on_poison_pressed():
	_develop_affected_plant(globals.PLANT_TYPES.POISON)

func _on_arrows_pressed():
	_develop_affected_plant(globals.PLANT_TYPES.ARROWS)

func _develop_affected_plant(type):
	affected_plant.convert_to_type(type)
	$plantMenu.visible = false
