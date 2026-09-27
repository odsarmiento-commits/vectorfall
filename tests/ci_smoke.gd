extends SceneTree

const DATA = preload("res://scripts/game_data.gd")

const SCENES := [
    "res://scenes/main_menu.tscn",
    "res://scenes/game.tscn",
]

func _init() -> void:
    if not _validate_content():
        quit(1)
        return

    for scene_path in SCENES:
        if not await _validate_scene(scene_path):
            quit(1)
            return

    for level_number in range(1, 6):
        GameState.current_level = level_number
        if not await _validate_scene("res://scenes/game.tscn"):
            push_error("El nivel %d no pudo instanciarse." % level_number)
            quit(1)
            return

    print("VECTORFALL_CI_SMOKE_OK · 4 HEROES · 5 LEVELS")
    quit(0)

func _validate_content() -> bool:
    var heroes := DATA.hero_defs()
    if heroes.size() != 4:
        push_error("La beta debe contener exactamente 4 héroes.")
        return false

    var required_roles := {
        "ASALTO": false,
        "TANQUE": false,
        "APOYO": false,
        "CONTROL": false,
    }

    for hero in heroes:
        var role := str(hero.get("archetype", ""))
        if not required_roles.has(role):
            push_error("Arquetipo de héroe no reconocido: %s" % role)
            return false
        required_roles[role] = true

        if str(hero.get("ability", "")).is_empty():
            push_error("Cada héroe debe tener una habilidad activa.")
            return false

    for role in required_roles:
        if not required_roles[role]:
            push_error("Falta el rol obligatorio: %s" % role)
            return false

    var levels := DATA.level_defs()
    if levels.size() != 5:
        push_error("La beta debe contener exactamente 5 niveles.")
        return false

    var final_has_boss := false
    for i in range(levels.size()):
        var level: Dictionary = levels[i]
        if int(level.get("number", 0)) != i + 1:
            push_error("Numeración de nivel inválida en índice %d." % i)
            return false

        var enemies: Array = level.get("enemies", [])
        if enemies.is_empty():
            push_error("El nivel %d no tiene enemigos." % (i + 1))
            return false

        if i == 4:
            for enemy in enemies:
                if str(enemy.get("type", "")) == "boss":
                    final_has_boss = true

    if not final_has_boss:
        push_error("El nivel 5 debe incluir un jefe.")
        return false

    return true

func _validate_scene(scene_path: String) -> bool:
    var resource := load(scene_path)
    if resource == null or not resource is PackedScene:
        push_error("No se pudo cargar: %s" % scene_path)
        return false

    var instance := (resource as PackedScene).instantiate()
    if instance == null:
        push_error("No se pudo instanciar: %s" % scene_path)
        return false

    get_root().add_child(instance)
    await process_frame
    await process_frame
    instance.queue_free()
    await process_frame
    return true
