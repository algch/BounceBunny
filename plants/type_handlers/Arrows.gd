extends Node

var production_timer = Timer.new()

func _ready():
    production_timer.connect("timeout", self, "_on_production_timer_timeout")

func handle_growing(_plant):
	pass

func handle_menaced(_plant):
    pass

func handle_idle(_plant):
    pass

func _on_production_timer_timeout():
    print("PRODUCE AN ARROW :P")
