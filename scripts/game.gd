extends Node2D

const ACTOR_SCRIPT = preload("res://scripts/arena_actor.gd")
const DATA = preload("res://scripts/game_data.gd")

const ARENA := Rect2(54.0, 116.0, 1172.0, 480.0)
const MAX_DRAG := 190.0
const STOP_SPEED := 68.0
const BOUNCE := 0.86
const MAX_MOTION_TIME := 4.8

var current_level := 1
var level_data: Dictionary = {}
var obstacles: Array = []

var heroes: Array = []
var enemies: Array = []

var phase := "boot"
var round_number := 1
var acted_heroes: Dictionary = {}
var enemy_index := 0
var active_actor = null

var dragging := false
var drag_mouse := Vector2.ZERO
var motion_time := 0.0
var hit_registry: Dictionary = {}
var combo_hits := 0

var paused := false
var finished := false
var skip_enemy_phase := false

var level_label: Label
var phase_label: Label
var round_label: Label
var status_label: Label
var ability_button: Button
var ability_desc_label: Label
var power_bar: ProgressBar

var result_panel: PanelContainer
var result_title: Label
var result_text: Label
var next_button: Button

func _ready() -> void:
    current_level = clampi(GameState.current_level, 1, 5)
    level_data = DATA.get_level(current_level)
    obstacles = level_data["obstacles"].duplicate(true)

    _build_ui()
    _spawn_heroes()
    _spawn_enemies()
    _begin_round()
    queue_redraw()

func _process(delta: float) -> void:
    if paused or finished:
        return
    if phase == "player_moving" or phase == "enemy_moving":
        _step_motion(delta)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if not finished:
            paused = not paused
            _update_hud()
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            get_tree().reload_current_scene()
            return
        if event.keycode == KEY_SPACE:
            _use_ability()
            return

    if paused or finished or phase != "player_aim" or active_actor == null:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if event.position.distance_to(active_actor.position) <= active_actor.radius + 20.0:
                dragging = true
                drag_mouse = event.position
                _update_power()
                queue_redraw()
        elif dragging:
            drag_mouse = event.position
            _update_power()
            _launch_player()
    elif event is InputEventMouseMotion and dragging:
        drag_mouse = event.position
        _update_power()
        queue_redraw()

func _build_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)

    var top := ColorRect.new()
    top.color = Color(0.025, 0.045, 0.085, 0.97)
    top.position = Vector2.ZERO
    top.size = Vector2(1280, 98)
    ui.add_child(top)

    level_label = Label.new()
    level_label.position = Vector2(28, 14)
    level_label.size = Vector2(620, 34)
    level_label.add_theme_font_size_override("font_size", 23)
    level_label.add_theme_color_override("font_color", level_data["accent"])
    ui.add_child(level_label)

    phase_label = Label.new()
    phase_label.position = Vector2(28, 52)
    phase_label.size = Vector2(730, 28)
    phase_label.add_theme_font_size_override("font_size", 16)
    phase_label.add_theme_color_override("font_color", Color("c7d1e2"))
    ui.add_child(phase_label)

    round_label = Label.new()
    round_label.position = Vector2(810, 24)
    round_label.size = Vector2(180, 32)
    round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    round_label.add_theme_font_size_override("font_size", 17)
    round_label.add_theme_color_override("font_color", Color("9fb0c9"))
    ui.add_child(round_label)

    var title := Label.new()
    title.text = "VECTORFALL"
    title.position = Vector2(1010, 18)
    title.size = Vector2(235, 38)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("f4f7ff"))
    ui.add_child(title)

    var bottom := ColorRect.new()
    bottom.color = Color(0.025, 0.045, 0.085, 0.98)
    bottom.position = Vector2(0, 610)
    bottom.size = Vector2(1280, 110)
    ui.add_child(bottom)

    status_label = Label.new()
    status_label.position = Vector2(28, 628)
    status_label.size = Vector2(540, 58)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 17)
    status_label.add_theme_color_override("font_color", Color("f3e67c"))
    ui.add_child(status_label)

    ability_button = Button.new()
    ability_button.position = Vector2(595, 626)
    ability_button.size = Vector2(285, 50)
    ability_button.add_theme_font_size_override("font_size", 15)
    ability_button.pressed.connect(_use_ability)
    ui.add_child(ability_button)

    ability_desc_label = Label.new()
    ability_desc_label.position = Vector2(595, 681)
    ability_desc_label.size = Vector2(330, 28)
    ability_desc_label.add_theme_font_size_override("font_size", 12)
    ability_desc_label.add_theme_color_override("font_color", Color("93a6c1"))
    ui.add_child(ability_desc_label)

    power_bar = ProgressBar.new()
    power_bar.position = Vector2(950, 643)
    power_bar.size = Vector2(280, 20)
    power_bar.max_value = 100
    power_bar.show_percentage = false
    ui.add_child(power_bar)

    var power_hint := Label.new()
    power_hint.text = "POTENCIA DE LANZAMIENTO"
    power_hint.position = Vector2(950, 670)
    power_hint.size = Vector2(280, 24)
    power_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    power_hint.add_theme_font_size_override("font_size", 12)
    power_hint.add_theme_color_override("font_color", Color("9fb0c9"))
    ui.add_child(power_hint)

    result_panel = PanelContainer.new()
    result_panel.position = Vector2(370, 190)
    result_panel.size = Vector2(540, 330)
    result_panel.visible = false
    ui.add_child(result_panel)

    var result_box := VBoxContainer.new()
    result_box.add_theme_constant_override("separation", 15)
    result_panel.add_child(result_box)

    result_title = Label.new()
    result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_title.add_theme_font_size_override("font_size", 31)
    result_box.add_child(result_title)

    result_text = Label.new()
    result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_text.custom_minimum_size = Vector2(500, 85)
    result_text.add_theme_font_size_override("font_size", 16)
    result_box.add_child(result_text)

    next_button = Button.new()
    next_button.custom_minimum_size = Vector2(360, 48)
    next_button.pressed.connect(_next_level)
    result_box.add_child(next_button)

    var retry := Button.new()
    retry.text = "REINTENTAR NIVEL"
    retry.custom_minimum_size = Vector2(360, 44)
    retry.pressed.connect(func(): get_tree().reload_current_scene())
    result_box.add_child(retry)

    var menu := Button.new()
    menu.text = "VOLVER A CAMPAÑA"
    menu.custom_minimum_size = Vector2(360, 44)
    menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    result_box.add_child(menu)

func _spawn_heroes() -> void:
    var positions := [
        Vector2(175, 190),
        Vector2(170, 305),
        Vector2(175, 420),
        Vector2(170, 535)
    ]

    var defs := DATA.hero_defs()
    for i in range(defs.size()):
        var hero_data: Dictionary = defs[i].duplicate(true)
        hero_data["team"] = "hero"

        var hero = ACTOR_SCRIPT.new()
        hero.setup(hero_data)
        hero.position = positions[i]
        hero.died.connect(_on_actor_died)
        hero.health_changed.connect(_on_health_changed)
        add_child(hero)
        heroes.append(hero)

func _spawn_enemies() -> void:
    for entry in level_data["enemies"]:
        var kind := str(entry["type"])
        var enemy_data := DATA.enemy_stats(kind, current_level)
        enemy_data["team"] = "enemy"

        var enemy = ACTOR_SCRIPT.new()
        enemy.setup(enemy_data)
        enemy.position = entry["pos"]
        enemy.died.connect(_on_actor_died)
        enemy.health_changed.connect(_on_health_changed)
        add_child(enemy)
        enemies.append(enemy)

func _begin_round() -> void:
    if finished:
        return
    if _living_heroes().is_empty():
        _finish(false)
        return
    if _living_enemies().is_empty():
        _finish(true)
        return

    acted_heroes.clear()
    enemy_index = 0
    phase = "player_prepare"
    active_actor = null
    power_bar.value = 0
    _update_hud()
    _next_player_turn()

func _next_player_turn() -> void:
    if finished:
        return
    if _living_enemies().is_empty():
        _finish(true)
        return
    if _living_heroes().is_empty():
        _finish(false)
        return

    for hero in heroes:
        hero.set_active(false)

    active_actor = null
    for hero in heroes:
        if hero.alive and not acted_heroes.has(hero.get_instance_id()):
            active_actor = hero
            break

    if active_actor == null:
        _begin_enemy_phase()
        return

    active_actor.set_active(true)
    phase = "player_aim"
    dragging = false
    combo_hits = 0
    hit_registry.clear()
    power_bar.value = 0
    _update_hud()

func _launch_player() -> void:
    if active_actor == null:
        return

    dragging = false
    var pull := active_actor.position - drag_mouse
    var strength := minf(pull.length(), MAX_DRAG)

    if strength < 24.0:
        power_bar.value = 0
        queue_redraw()
        return

    acted_heroes[active_actor.get_instance_id()] = true

    var speed := lerpf(430.0, 1120.0, strength / MAX_DRAG)
    speed *= active_actor.speed_boost

    active_actor.launch(pull.normalized() * speed)
    active_actor.set_active(false)

    phase = "player_moving"
    motion_time = 0.0
    combo_hits = 0
    hit_registry.clear()
    _update_hud()

func _begin_enemy_phase() -> void:
    phase = "enemy_wait"
    active_actor = null
    power_bar.value = 0
    _update_hud()

    if skip_enemy_phase:
        skip_enemy_phase = false
        phase_label.text = "CAMPO ESTÁTICO · fase enemiga anulada"
        await get_tree().create_timer(0.7).timeout
        if is_inside_tree() and not finished:
            round_number += 1
            _begin_round()
        return

    enemy_index = 0
    await get_tree().create_timer(0.35).timeout
    if is_inside_tree() and not finished:
        _launch_next_enemy()

func _launch_next_enemy() -> void:
    if finished:
        return

    var living := _living_enemies()
    if enemy_index >= living.size():
        active_actor = null
        round_number += 1
        _begin_round()
        return

    active_actor = living[enemy_index]

    if active_actor.stunned_turns > 0:
        active_actor.stunned_turns -= 1
        active_actor.queue_redraw()
        enemy_index += 1
        _launch_next_enemy()
        return

    var target = _nearest_hero(active_actor.position)
    if target == null:
        _finish(false)
        return

    var direction := (target.position - active_actor.position).normalized()
    active_actor.launch(direction * active_actor.ai_speed)

    phase = "enemy_moving"
    motion_time = 0.0
    combo_hits = 0
    hit_registry.clear()
    _update_hud()

func _step_motion(delta: float) -> void:
    if active_actor == null or not is_instance_valid(active_actor) or not active_actor.alive:
        _end_motion_phase()
        return

    motion_time += delta
    active_actor.remember_trail()
    active_actor.position += active_actor.velocity * delta
    active_actor.velocity *= pow(0.40, delta)

    _bounce_walls(active_actor)
    _bounce_obstacles(active_actor)
    _check_actor_hits(active_actor)

    if active_actor.velocity.length() < STOP_SPEED or motion_time >= MAX_MOTION_TIME:
        active_actor.stop()
        _end_motion_phase()

    queue_redraw()

func _bounce_walls(actor) -> void:
    var r: float = actor.radius
    var left := ARENA.position.x + r
    var right := ARENA.end.x - r
    var top := ARENA.position.y + r
    var bottom := ARENA.end.y - r

    if actor.position.x < left:
        actor.position.x = left
        actor.velocity.x = absf(actor.velocity.x) * BOUNCE
    elif actor.position.x > right:
        actor.position.x = right
        actor.velocity.x = -absf(actor.velocity.x) * BOUNCE

    if actor.position.y < top:
        actor.position.y = top
        actor.velocity.y = absf(actor.velocity.y) * BOUNCE
    elif actor.position.y > bottom:
        actor.position.y = bottom
        actor.velocity.y = -absf(actor.velocity.y) * BOUNCE

func _bounce_obstacles(actor) -> void:
    for obstacle in obstacles:
        var expanded: Rect2 = obstacle.grow(actor.radius)
        if not expanded.has_point(actor.position):
            continue

        var left_d := absf(actor.position.x - expanded.position.x)
        var right_d := absf(actor.position.x - expanded.end.x)
        var top_d := absf(actor.position.y - expanded.position.y)
        var bottom_d := absf(actor.position.y - expanded.end.y)
        var smallest := minf(minf(left_d, right_d), minf(top_d, bottom_d))

        if smallest == left_d:
            actor.position.x = expanded.position.x
            actor.velocity.x = -absf(actor.velocity.x) * BOUNCE
        elif smallest == right_d:
            actor.position.x = expanded.end.x
            actor.velocity.x = absf(actor.velocity.x) * BOUNCE
        elif smallest == top_d:
            actor.position.y = expanded.position.y
            actor.velocity.y = -absf(actor.velocity.y) * BOUNCE
        else:
            actor.position.y = expanded.end.y
            actor.velocity.y = absf(actor.velocity.y) * BOUNCE

func _check_actor_hits(actor) -> void:
    var targets := enemies if actor.team == "hero" else heroes

    for target in targets:
        if not target.alive:
            continue
        if actor.position.distance_to(target.position) > actor.radius + target.radius:
            continue

        var key := target.get_instance_id()
        if hit_registry.has(key):
            continue
        hit_registry[key] = true

        combo_hits += 1
        var speed_factor := clampf(actor.velocity.length() / 830.0, 0.62, 1.40)
        var combo_factor := 1.0 + minf(float(maxi(combo_hits - 1, 0)) * 0.10, 0.40)
        var dealt := target.take_damage(actor.damage * actor.damage_boost * speed_factor * combo_factor)

        var normal := (actor.position - target.position).normalized()
        if normal == Vector2.ZERO:
            normal = Vector2.RIGHT

        actor.position = target.position + normal * (actor.radius + target.radius + 2.0)
        actor.velocity = actor.velocity.bounce(normal) * 0.89

        _damage_popup(target.position, dealt, actor.team == "hero", combo_hits)

func _end_motion_phase() -> void:
    if finished:
        return

    var moving_actor = active_actor
    var was_hero := false

    if moving_actor != null and is_instance_valid(moving_actor):
        was_hero = moving_actor.team == "hero"
        moving_actor.stop()
        if was_hero:
            moving_actor.reset_temporary_buffs()

    active_actor = null

    if _living_heroes().is_empty():
        _finish(false)
        return
    if _living_enemies().is_empty():
        _finish(true)
        return

    if was_hero:
        _next_player_turn()
    else:
        enemy_index += 1
        _launch_next_enemy()

func _use_ability() -> void:
    if paused or finished or phase != "player_aim" or active_actor == null:
        return
    if active_actor.team != "hero" or active_actor.ability_used:
        return

    active_actor.ability_used = true

    match active_actor.archetype:
        "ASALTO":
            active_actor.damage_boost = 1.75
            active_actor.speed_boost = 1.18
            _ability_flash("SOBRECARGA LISTA")
        "TANQUE":
            for hero in _living_heroes():
                hero.add_shield(55.0)
            _ability_flash("FORTALEZA · +55 ESCUDO AL EQUIPO")
        "APOYO":
            for hero in _living_heroes():
                var healed := hero.heal(45.0)
                if healed > 0.0:
                    _heal_popup(hero.position, healed)
            _ability_flash("PULSO VITAL · EQUIPO RESTAURADO")
        "CONTROL":
            skip_enemy_phase = true
            _ability_flash("CAMPO ESTÁTICO ARMADO")

    active_actor.queue_redraw()
    _update_hud()

func _finish(victory: bool) -> void:
    if finished:
        return

    finished = true
    dragging = false
    phase = "finished"
    power_bar.value = 0

    if active_actor != null and is_instance_valid(active_actor):
        active_actor.stop()

    for hero in heroes:
        hero.set_active(false)

    result_panel.visible = true

    if victory:
        result_title.text = "NIVEL SUPERADO"
        result_title.add_theme_color_override("font_color", Color("76edb0"))

        if current_level < 5:
            GameState.unlock_level(current_level + 1)
            result_text.text = "%s asegurado. Se desbloqueó el nivel %d." % [
                level_data["name"],
                current_level + 1
            ]
            next_button.text = "SIGUIENTE NIVEL"
            next_button.visible = true
        else:
            GameState.complete_campaign()
            result_title.text = "BETA COMPLETADA"
            result_text.text = "La Corona Vectorial cayó. Completaste los cinco niveles de la campaña beta."
            next_button.text = "VOLVER A CAMPAÑA"
            next_button.visible = true
    else:
        result_title.text = "EQUIPO FUERA DE LÍNEA"
        result_title.add_theme_color_override("font_color", Color("ff728a"))
        result_text.text = "Los cuatro agentes fueron derribados. Cambia los ángulos y reserva las habilidades para el momento correcto."
        next_button.visible = false

    _update_hud()

func _next_level() -> void:
    if current_level < 5:
        GameState.select_level(current_level + 1)
        get_tree().reload_current_scene()
    else:
        get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _living_heroes() -> Array:
    return heroes.filter(func(hero): return hero.alive)

func _living_enemies() -> Array:
    return enemies.filter(func(enemy): return enemy.alive)

func _nearest_hero(from_pos: Vector2):
    var best = null
    var best_distance := INF

    for hero in heroes:
        if not hero.alive:
            continue
        var distance := from_pos.distance_squared_to(hero.position)
        if distance < best_distance:
            best_distance = distance
            best = hero

    return best

func _on_actor_died(_actor) -> void:
    _update_hud()

func _on_health_changed(_actor) -> void:
    _update_hud()

func _update_power() -> void:
    if active_actor == null:
        power_bar.value = 0
        return

    power_bar.value = clampf(
        (active_actor.position - drag_mouse).length() / MAX_DRAG,
        0.0,
        1.0
    ) * 100.0

func _update_hud() -> void:
    level_label.text = "NIVEL %d · %s  —  %s" % [
        current_level,
        level_data.get("name", ""),
        level_data.get("subtitle", "")
    ]

    round_label.text = "RONDA %d" % round_number

    if finished:
        phase_label.text = "COMBATE FINALIZADO"
    elif paused:
        phase_label.text = "PAUSA · ESC para continuar"
    elif phase == "player_aim":
        phase_label.text = "TU FASE · arrastra al agente activo hacia atrás y suelta"
    elif phase == "player_moving":
        phase_label.text = "IMPACTO EN CURSO%s" % (" · COMBO x%d" % combo_hits if combo_hits > 1 else "")
    elif phase == "enemy_wait" or phase == "enemy_moving":
        phase_label.text = "FASE ENEMIGA · %d hostiles restantes" % _living_enemies().size()
    else:
        phase_label.text = "PREPARANDO RONDA"

    if active_actor != null and is_instance_valid(active_actor):
        if active_actor.team == "hero":
            status_label.text = "%s · %s\nPV %d/%d  ·  ESCUDO %d  ·  DAÑO %d" % [
                active_actor.actor_name,
                active_actor.archetype,
                ceili(active_actor.hp),
                ceili(active_actor.max_hp),
                ceili(active_actor.shield),
                ceili(active_actor.damage)
            ]
            ability_button.text = "%s  [ESPACIO]%s" % [
                active_actor.ability_name,
                " · USADA" if active_actor.ability_used else ""
            ]
            ability_button.disabled = active_actor.ability_used or phase != "player_aim" or paused
            ability_desc_label.text = active_actor.ability_desc
        else:
            status_label.text = "%s\nPV %d/%d  ·  ENEMIGOS %d" % [
                active_actor.actor_name,
                ceili(active_actor.hp),
                ceili(active_actor.max_hp),
                _living_enemies().size()
            ]
            ability_button.text = "HABILIDAD"
            ability_button.disabled = true
            ability_desc_label.text = "Espera a que termine la fase enemiga."
    else:
        status_label.text = "Agentes operativos: %d/4\nHostiles restantes: %d" % [
            _living_heroes().size(),
            _living_enemies().size()
        ]
        ability_button.text = "HABILIDAD"
        ability_button.disabled = true
        ability_desc_label.text = ""

func _ability_flash(message: String) -> void:
    phase_label.text = message

func _damage_popup(pos: Vector2, amount: float, friendly: bool, combo: int) -> void:
    var label := Label.new()
    label.text = "-%d%s" % [
        roundi(amount),
        "  COMBO x%d" % combo if combo > 1 else ""
    ]
    label.position = pos + Vector2(-55, -50)
    label.size = Vector2(120, 30)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override(
        "font_color",
        Color("7cecff") if friendly else Color("ff8195")
    )
    label.z_index = 50
    add_child(label)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", label.position + Vector2(0, -34), 0.55)
    tween.tween_property(label, "modulate:a", 0.0, 0.55)
    tween.chain().tween_callback(label.queue_free)

func _heal_popup(pos: Vector2, amount: float) -> void:
    var label := Label.new()
    label.text = "+%d" % roundi(amount)
    label.position = pos + Vector2(-35, -48)
    label.size = Vector2(70, 28)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color("65e39a"))
    label.z_index = 50
    add_child(label)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", label.position + Vector2(0, -30), 0.55)
    tween.tween_property(label, "modulate:a", 0.0, 0.55)
    tween.chain().tween_callback(label.queue_free)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("07101f"), true)
    draw_rect(ARENA, Color("0a1729"), true)

    var accent: Color = level_data.get("accent", Color("49c9ff"))
    var grid := Color(accent.r, accent.g, accent.b, 0.08)

    var x := ARENA.position.x + 40.0
    while x < ARENA.end.x:
        draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), grid, 1.0)
        x += 40.0

    var y := ARENA.position.y + 40.0
    while y < ARENA.end.y:
        draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), grid, 1.0)
        y += 40.0

    draw_rect(ARENA, Color(accent.r, accent.g, accent.b, 0.55), false, 3.0)

    for obstacle in obstacles:
        draw_rect(obstacle, Color("142d49"), true)
        draw_rect(obstacle, Color(accent.r, accent.g, accent.b, 0.46), false, 2.0)

    for hero in heroes:
        _draw_trail(hero, Color(0.35, 0.82, 1.0, 0.25))

    for enemy in enemies:
        _draw_trail(enemy, Color(1.0, 0.34, 0.50, 0.20))

    if dragging and phase == "player_aim" and active_actor != null:
        var pull := active_actor.position - drag_mouse
        var clamped := pull.limit_length(MAX_DRAG)
        var release_point := active_actor.position - clamped

        draw_line(active_actor.position, release_point, Color("f9e36a"), 4.0)
        draw_circle(release_point, 8.0, Color("f9e36a"))

        if clamped.length() > 24.0:
            var direction := clamped.normalized()
            for i in range(1, 9):
                draw_circle(
                    active_actor.position + direction * 43.0 * i,
                    maxf(2.0, 6.0 - float(i) * 0.4),
                    Color(0.55, 0.92, 1.0, 0.65)
                )

func _draw_trail(actor, color: Color) -> void:
    if actor == null or actor.trail.size() < 2:
        return

    for i in range(actor.trail.size() - 1):
        draw_line(actor.trail[i], actor.trail[i + 1], color, 3.0)
