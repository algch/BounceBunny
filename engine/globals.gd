extends Node

enum ITEM_TYPES {
    SUPPORT,
    TELEPORT,
    HEAL,
    SCORE,
}

enum PROJECTILE_TYPES {
    ATTACK,
    SUMMON,
    SCORE,
    TELEPORT,
}


func calculateChance(probability):
    return randf() <= probability


func getRandomItemType():
    return ITEM_TYPES.values()[randi()%len(ITEM_TYPES)]
