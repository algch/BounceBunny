extends Control

signal action_changed(direction)

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
