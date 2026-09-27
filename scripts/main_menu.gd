extends Control

const DATA = preload("res://scripts/game_data.gd")

var level_box: VBoxContainer
var progress_label: Label

func _get_game_state() -> Node:
    return get_node_or_null("/root/GameState")

func _ready() -> void:
    _build_background()
    _build_header()
    _build_level_panel()
    _build_roster()
    _refresh_levels()

func _build_background() -> void:
    var bg := ColorRect.new()
    bg.color = Color("07101f")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var band := ColorRect.new()
    band.color = Color("0b1b32")
    band.position = Vector2(0, 0)
    band.size = Vector2(1280, 96)
    band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(band)

func _build_header() -> void:
    var title := Label.new()
    title.text = "VECTORFALL"
    title.position = Vector2(54, 20)
    title.size = Vector2(430, 54)
    title.add_theme_font_size_override("font_size", 46)
    title.add_theme_color_override("font_color", Color("f4f7ff"))
    add_child(title)

    var tag := Label.new()
    tag.text = "BETA · 4 AGENTES · 5 NIVELES"
    tag.position = Vector2(910, 34)
    tag.size = Vector2(310, 30)
    tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    tag.add_theme_font_size_override("font_size", 16)
    tag.add_theme_color_override("font_color", Color("6fdcff"))
    add_child(tag)

    var intro := Label.new()
    intro.text = "Lanza, rebota y encadena impactos. Cada agente cubre un rol distinto."
    intro.position = Vector2(54, 112)
    intro.size = Vector2(1160, 32)
    intro.add_theme_font_size_override("font_size", 20)
    intro.add_theme_color_override("font_color", Color("b7c5d9"))
    add_child(intro)

func _build_level_panel() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(54, 166)
    panel.size = Vector2(520, 360)
    add_child(panel)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 12)
    panel.add_child(outer)

    var heading := Label.new()
    heading.text = "CAMPAÑA"
    heading.add_theme_font_size_override("font_size", 24)
    heading.add_theme_color_override("font_color", Color("f3e67c"))
    outer.add_child(heading)

    progress_label = Label.new()
    progress_label.add_theme_font_size_override("font_size", 15)
    progress_label.add_theme_color_override("font_color", Color("9fb0c9"))
    outer.add_child(progress_label)

    level_box = VBoxContainer.new()
    level_box.add_theme_constant_override("separation", 8)
    outer.add_child(level_box)

    var help := Label.new()
    help.text = "Controles: arrastra al agente activo y suelta · ESPACIO habilidad · ESC pausa · R reinicia"
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.custom_minimum_size = Vector2(470, 50)
    help.add_theme_font_size_override("font_size", 14)
    help.add_theme_color_override("font_color", Color("8295af"))
    outer.add_child(help)

func _build_roster() -> void:
    var heading := Label.new()
    heading.text = "EQUIPO VECTOR"
    heading.position = Vector2(620, 166)
    heading.size = Vector2(590, 32)
    heading.add_theme_font_size_override("font_size", 24)
    heading.add_theme_color_override("font_color", Color("f4f7ff"))
    add_child(heading)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.position = Vector2(620, 208)
    grid.size = Vector2(590, 318)
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    add_child(grid)

    for hero_data in DATA.hero_defs():
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(285, 145)
        grid.add_child(card)

        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 5)
        card.add_child(box)

        var name_label := Label.new()
        name_label.text = "%s  ·  %s" % [hero_data["name"], hero_data["archetype"]]
        name_label.add_theme_font_size_override("font_size", 19)
        name_label.add_theme_color_override("font_color", hero_data["color"])
        box.add_child(name_label)

        var stats := Label.new()
        stats.text = "PV %d   DAÑO %d   ARM %d%%" % [
            int(hero_data["max_hp"]),
            int(hero_data["damage"]),
            roundi(float(hero_data["armor"]) * 100.0)
        ]
        stats.add_theme_font_size_override("font_size", 13)
        stats.add_theme_color_override("font_color", Color("b9c6d8"))
        box.add_child(stats)

        var ability := Label.new()
        ability.text = "%s — %s" % [hero_data["ability"], hero_data["ability_desc"]]
        ability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ability.custom_minimum_size = Vector2(255, 55)
        ability.add_theme_font_size_override("font_size", 13)
        ability.add_theme_color_override("font_color", Color("d9e2ef"))
        box.add_child(ability)

    var footer := Label.new()
    footer.text = "Todos los gráficos de esta beta son originales y generados por el propio proyecto."
    footer.position = Vector2(620, 542)
    footer.size = Vector2(590, 42)
    footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    footer.add_theme_font_size_override("font_size", 13)
    footer.add_theme_color_override("font_color", Color("7487a0"))
    add_child(footer)

    var reset := Button.new()
    reset.text = "REINICIAR PROGRESO"
    reset.position = Vector2(54, 548)
    reset.size = Vector2(205, 40)
    reset.pressed.connect(_reset_progress)
    add_child(reset)

func _refresh_levels() -> void:
    for child in level_box.get_children():
        child.queue_free()

    var state: Node = _get_game_state()
    var max_unlocked: int = 1
    var campaign_complete: bool = false
    if state != null:
        max_unlocked = clampi(int(state.get("max_unlocked")), 1, 5)
        campaign_complete = bool(state.get("campaign_complete"))

    progress_label.text = "Nivel máximo desbloqueado: %d / 5%s" % [
        max_unlocked,
        " · CAMPAÑA COMPLETADA" if campaign_complete else ""
    ]

    for level_data in DATA.level_defs():
        var level_number := int(level_data["number"])
        var unlocked := level_number <= max_unlocked

        var button := Button.new()
        button.custom_minimum_size = Vector2(485, 46)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.text = "%d. %s  —  %s%s" % [
            level_number,
            level_data["name"],
            level_data["subtitle"],
            "" if unlocked else "  [BLOQUEADO]"
        ]
        button.disabled = not unlocked
        button.add_theme_font_size_override("font_size", 15)
        button.pressed.connect(_play_level.bind(level_number))
        level_box.add_child(button)

func _play_level(level_number: int) -> void:
    var state: Node = _get_game_state()
    if state != null and state.has_method("select_level"):
        state.call("select_level", level_number)
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func _reset_progress() -> void:
    var state: Node = _get_game_state()
    if state != null and state.has_method("reset_progress"):
        state.call("reset_progress")
    _refresh_levels()
