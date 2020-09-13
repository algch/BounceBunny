extends Node

onready var player = get_node('player')
var GAME_OVER = false
var score = 0

var difficulty = 0

var INITIAL_MAX_SPIDERS = 10 
var INITIAL_MAX_SPAWNER_HEALTH = 20.0
var INITIAL_MAX_SPAWNER_HEALTH_RECOVERY = 0.5

var INITIAL_MAX_SPIDER_SPEED = 100
var INITIAL_MAX_SPIDER_DAMAGE = 0.5
var INITIAL_MAX_SPIDER_HEALTH = 3.0

var MAX_SPIDERS = INITIAL_MAX_SPIDERS 
var MAX_SPAWNER_HEALTH = INITIAL_MAX_SPAWNER_HEALTH
var MAX_SPAWNER_HEALTH_RECOVERY = INITIAL_MAX_SPAWNER_HEALTH_RECOVERY

var MAX_SPIDER_SPEED = INITIAL_MAX_SPIDER_SPEED
var MAX_SPIDER_DAMAGE = INITIAL_MAX_SPIDER_DAMAGE
var MAX_SPIDER_HEALTH = INITIAL_MAX_SPIDER_HEALTH

var available_actions = [globals.ACTIONS.MOVE, globals.ACTIONS.ATTACK, globals.ACTIONS.PLANT]
var selected_action : = 0

var savegame = File.new()
var save_path = 'user://savegame.save'
var initial_save_date = {'highscore': 0}

onready var plants_graph = {}

func create_save():
	savegame.open(save_path, File.WRITE)
	savegame.store_var(initial_save_date)
	savegame.close()

func increaseScore():
	score += 1
	difficulty = int(score/500)
	MAX_SPIDERS = INITIAL_MAX_SPIDERS + difficulty
	MAX_SPAWNER_HEALTH = INITIAL_MAX_SPAWNER_HEALTH + (0.5 * difficulty)
	MAX_SPAWNER_HEALTH_RECOVERY = INITIAL_MAX_SPAWNER_HEALTH_RECOVERY + (0.1 * difficulty)

	MAX_SPIDER_SPEED = INITIAL_MAX_SPIDER_SPEED + (10 * difficulty)
	MAX_SPIDER_DAMAGE = INITIAL_MAX_SPIDER_DAMAGE + (0.1 * difficulty)
	MAX_SPIDER_HEALTH = INITIAL_MAX_SPIDER_HEALTH + (0.25 * difficulty)

func getHighScore():
	savegame.open(save_path, File.READ)
	var save_data = savegame.get_var()
	savegame.close()
	return save_data['highscore']

func setHighScore(val):
	var save_data= {'highscore': val}
	savegame.open(save_path, File.WRITE)
	savegame.store_var(save_data)
	savegame.close()

func gameOver():
	GAME_OVER = true
	$player/pauseScreen.visible = true
	$player/pauseScreen/label.set_text('GAME\nOVER')
	$player/resumeRestart.visible = true
	$player/resumeRestart.set_process(true)
	$player/quit.visible = true
	$player/quit.set_process(true)

	if getHighScore() < score:
		setHighScore(score)

func _ready():
	randomize()
	if not savegame.file_exists(save_path):
		create_save()
	$player/highScore.set_text('HIGHSCORE: ' + str(getHighScore()))

func _on_gui_action_changed(change_dir):
	var action_index = selected_action + change_dir
	if action_index < 0:
		action_index = available_actions.size() - 1
	elif action_index > available_actions.size() - 1:
		action_index = 0
	selected_action = action_index
	if get_selected_action() == globals.ACTIONS.ATTACK:
		$player.current_weapon = globals.PROJECTILE_TYPES.ATTACK
	if get_selected_action() == globals.ACTIONS.PLANT:
		$player.current_weapon = globals.PROJECTILE_TYPES.SUMMON
	$CanvasLayer/gui/topDisplay/action.set_text(get_selected_action_as_string())

func get_selected_action():
	return available_actions[selected_action]

func get_selected_action_as_string():
	match get_selected_action():
		globals.ACTIONS.MOVE:
			return "MOVE"
		globals.ACTIONS.ATTACK:
			return "ATTACK"
		globals.ACTIONS.PLANT:
			return "PLANT"
	return ""

func _on_player_damage_received(current_health):
	$CanvasLayer/gui/topDisplay/health.set_text(str(current_health))
