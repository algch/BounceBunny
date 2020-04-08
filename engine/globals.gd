extends Node

enum ITEM_TYPES {
    SEED,
    HEAL,
}

enum PROJECTILE_TYPES {
    ATTACK,
    SUMMON,
}

var GAME_OVER = false
var score = 0

var difficulty = 0

var INITIAL_MAX_SPIDERS = 10 
var INITIAL_MAX_SPAWNER_HEALTH = 20.0
var INITIAL_MAX_SPAWNER_HEALTH_RECOVERY = 0.5

var INITIAL_MAX_SPIDER_SPEED = 100
var INITIAL_MAX_SPIDER_DAMAGE = 0.5
var INITIAL_MAX_SPIDER_HEALTH = 3.0

var INITIAL_PLAYER_DAMAGE = 0.5
var INITIAL_PLAYER_MANA = 100.0

var MAX_SPIDERS = INITIAL_MAX_SPIDERS 
var MAX_SPAWNER_HEALTH = INITIAL_MAX_SPAWNER_HEALTH
var MAX_SPAWNER_HEALTH_RECOVERY = INITIAL_MAX_SPAWNER_HEALTH_RECOVERY

var MAX_SPIDER_SPEED = INITIAL_MAX_SPIDER_SPEED
var MAX_SPIDER_DAMAGE = INITIAL_MAX_SPIDER_DAMAGE
var MAX_SPIDER_HEALTH = INITIAL_MAX_SPIDER_HEALTH

var savegame = File.new()
var save_path = 'user://savegame.save'
var initial_save_date = {'highscore': 0}

func create_save():
	savegame.open(save_path, File.WRITE)
	savegame.store_var(initial_save_date)
	savegame.close()

func calculateChance(probability):
    return randf() <= probability


func getRandomItemType():
    return ITEM_TYPES.values()[randi()%len(ITEM_TYPES)]

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
    var player = get_node('/root/player')
    GAME_OVER = true
    player.get_node('pauseScreen').visible = true
    player.get_node('pauseScreen').label.set_text('GAME\nOVER')
    player.get_node('resumeRestart').visible = true
    player.get_node('resumeRestart').set_process(true)
    player.get_node('quit').visible = true
    player.get_node('quit').set_process(true)

    if getHighScore() < score:
        setHighScore(score)
