extends SceneTree

func _ensure_game_state() -> Node:
    var existing: Node = get_root().get_node_or_null("GameState")
    if existing != null:
        return existing

    var state_script: Script = load("res://scripts/game_state.gd") as Script
    if state_script == null:
        return null

    var state: Node = state_script.new() as Node
    state.name = "GameState"
    get_root().add_child(state)
    return state

func _init() -> void:
    var state: Node = _ensure_game_state()
    if state == null:
        push_error("No se pudo crear GameState para las pruebas.")
        quit(1)
        return

    state.current_level = 1

    var packed := load("res://scenes/game.tscn")
    if packed == null or not packed is PackedScene:
        push_error("No se pudo cargar la escena de juego.")
        quit(1)
        return

    var game = (packed as PackedScene).instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    if game.heroes.size() != 4:
        push_error("Se esperaban 4 héroes en combate.")
        quit(1)
        return

    if game.enemies.size() != 3:
        push_error("El nivel 1 debe comenzar con 3 enemigos.")
        quit(1)
        return

    var aren = game.heroes[0]
    game.active_actor = aren
    game.phase = "player_aim"
    game._use_ability()
    if not aren.ability_used or aren.damage_boost <= 1.0 or aren.speed_boost <= 1.0:
        push_error("La habilidad de AREN no aplicó Embestida.")
        quit(1)
        return

    var morvak = game.heroes[1]
    game.active_actor = morvak
    game.phase = "player_aim"
    game._use_ability()
    for hero in game.heroes:
        if hero.shield < 55.0:
            push_error("MURO DE HIERRO no otorgó escudo al equipo.")
            quit(1)
            return

    var arelia = game.heroes[2]
    var target = game.heroes[0]
    target.take_damage(90.0)
    var damaged_hp: float = target.hp

    game.active_actor = arelia
    game.phase = "player_aim"
    game._use_ability()
    if target.hp <= damaged_hp:
        push_error("DESTELLO REPARADOR no curó a un aliado dañado.")
        quit(1)
        return

    var kaien = game.heroes[3]
    game.active_actor = kaien
    game.phase = "player_aim"
    game._use_ability()
    if not game.skip_enemy_phase:
        push_error("MAREA SOMBRÍA no armó el salto de fase enemiga.")
        quit(1)
        return

    game.queue_free()
    await process_frame

    print("VECTORFALL_GAMEPLAY_SMOKE_OK · 4 ABILITIES")
    quit(0)
