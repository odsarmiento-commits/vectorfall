extends Control

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color("07101f")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var box := VBoxContainer.new()
    box.position = Vector2(120, 120)
    box.size = Vector2(620, 450)
    box.add_theme_constant_override("separation", 18)
    add_child(box)

    var kicker := Label.new()
    kicker.text = "BETA JUGABLE · GODOT 4.6 · PROYECTO ORIGINAL"
    kicker.add_theme_font_size_override("font_size", 17)
    kicker.add_theme_color_override("font_color", Color("6fdcff"))
    box.add_child(kicker)

    var title := Label.new()
    title.text = "VECTORFALL"
    title.add_theme_font_size_override("font_size", 64)
    title.add_theme_color_override("font_color", Color("f4f7ff"))
    box.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Lanza · Rebota · Encadena impactos"
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.add_theme_color_override("font_color", Color("b8c5d9"))
    box.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(1, 30)
    box.add_child(spacer)

    var play := Button.new()
    play.text = "JUGAR BETA"
    play.custom_minimum_size = Vector2(340, 62)
    play.add_theme_font_size_override("font_size", 22)
    play.pressed.connect(_play)
    box.add_child(play)

    var info := Label.new()
    info.text = "Arrastra un héroe hacia atrás y suelta.\nRebota contra muros y golpea enemigos.\nESC pausa · R reinicia."
    info.add_theme_font_size_override("font_size", 18)
    info.add_theme_color_override("font_color", Color("9fb0c9"))
    box.add_child(info)

func _play() -> void:
    get_tree().change_scene_to_file("res://scenes/game.tscn")
