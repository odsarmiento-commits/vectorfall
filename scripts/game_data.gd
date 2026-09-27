extends RefCounted
class_name GameData

static func hero_defs() -> Array:
    return [
        {
            "name": "AREN",
            "archetype": "ASALTO",
            "class_label": "GUERRERO",
            "role_label": "DAÑO FÍSICO / OFENSIVO",
            "ability": "EMBESTIDA ATRAVESANTE",
            "ability_desc": "El siguiente lanzamiento gana +75% daño y +18% velocidad.",
            "max_hp": 125.0,
            "damage": 44.0,
            "radius": 29.0,
            "armor": 0.04,
            "color": Color("58b9ff"),
            "sprite_path": "res://assets/heroes/aren.webp",
            "sprite_scale": 1.10
        },
        {
            "name": "MORVAK",
            "archetype": "TANQUE",
            "class_label": "TANQUE",
            "role_label": "PROTECTOR / CONTROL",
            "ability": "MURO DE HIERRO",
            "ability_desc": "Otorga 55 de escudo a todo el equipo.",
            "max_hp": 230.0,
            "damage": 28.0,
            "radius": 35.0,
            "armor": 0.26,
            "color": Color("a85545"),
            "sprite_path": "res://assets/heroes/morvak.webp",
            "sprite_scale": 1.15
        },
        {
            "name": "ARELIA",
            "archetype": "APOYO",
            "class_label": "MAGA",
            "role_label": "SOPORTE / CURACIÓN",
            "ability": "DESTELLO REPARADOR",
            "ability_desc": "Cura 45 PV a todos los aliados vivos.",
            "max_hp": 150.0,
            "damage": 27.0,
            "radius": 29.0,
            "armor": 0.08,
            "color": Color("e7c36a"),
            "sprite_path": "res://assets/heroes/arelia.webp",
            "sprite_scale": 1.12
        },
        {
            "name": "KAIEN",
            "archetype": "CONTROL",
            "class_label": "NINJA",
            "role_label": "ASESINO / MOVILIDAD",
            "ability": "MAREA SOMBRÍA",
            "ability_desc": "Desorienta al enemigo y anula por completo la siguiente fase enemiga.",
            "max_hp": 135.0,
            "damage": 34.0,
            "radius": 28.0,
            "armor": 0.05,
            "color": Color("3db8e6"),
            "sprite_path": "res://assets/heroes/kaien.webp",
            "sprite_scale": 1.13
        }
    ]

static func level_defs() -> Array:
    return [
        {
            "number": 1,
            "name": "MUELLE CERO",
            "subtitle": "Calibración de lanzamiento",
            "accent": Color("49c9ff"),
            "obstacles": [
                Rect2(605, 285, 72, 145)
            ],
            "enemies": [
                {"type": "shard", "pos": Vector2(930, 220)},
                {"type": "shard", "pos": Vector2(1035, 355)},
                {"type": "sentinel", "pos": Vector2(940, 505)}
            ]
        },
        {
            "number": 2,
            "name": "CÁMARA PRISMA",
            "subtitle": "Ángulos cerrados",
            "accent": Color("9c7dff"),
            "obstacles": [
                Rect2(505, 205, 68, 175),
                Rect2(735, 385, 72, 165)
            ],
            "enemies": [
                {"type": "shard", "pos": Vector2(910, 200)},
                {"type": "brute", "pos": Vector2(1040, 285)},
                {"type": "shard", "pos": Vector2(915, 440)},
                {"type": "sentinel", "pos": Vector2(1050, 535)}
            ]
        },
        {
            "number": 3,
            "name": "PASARELA ROTA",
            "subtitle": "Corredores de impacto",
            "accent": Color("55e6a5"),
            "obstacles": [
                Rect2(430, 225, 150, 54),
                Rect2(620, 425, 165, 54),
                Rect2(790, 210, 58, 125)
            ],
            "enemies": [
                {"type": "hunter", "pos": Vector2(980, 185)},
                {"type": "shard", "pos": Vector2(1060, 285)},
                {"type": "brute", "pos": Vector2(950, 390)},
                {"type": "hunter", "pos": Vector2(1070, 490)},
                {"type": "sentinel", "pos": Vector2(900, 545)}
            ]
        },
        {
            "number": 4,
            "name": "NÚCLEO MAGNÉTICO",
            "subtitle": "Cerco de alta presión",
            "accent": Color("ff8a66"),
            "obstacles": [
                Rect2(465, 185, 58, 150),
                Rect2(465, 415, 58, 150),
                Rect2(680, 300, 145, 62),
                Rect2(895, 205, 55, 135)
            ],
            "enemies": [
                {"type": "hunter", "pos": Vector2(1050, 175)},
                {"type": "brute", "pos": Vector2(1070, 270)},
                {"type": "sentinel", "pos": Vector2(985, 355)},
                {"type": "hunter", "pos": Vector2(1080, 435)},
                {"type": "brute", "pos": Vector2(1000, 520)},
                {"type": "shard", "pos": Vector2(1110, 555)}
            ]
        },
        {
            "number": 5,
            "name": "CORONA VECTORIAL",
            "subtitle": "Asalto al corazón de la red",
            "accent": Color("ff5d8f"),
            "obstacles": [
                Rect2(455, 210, 70, 120),
                Rect2(455, 430, 70, 120),
                Rect2(635, 305, 95, 70),
                Rect2(820, 205, 65, 125),
                Rect2(820, 430, 65, 125)
            ],
            "enemies": [
                {"type": "hunter", "pos": Vector2(1005, 185)},
                {"type": "brute", "pos": Vector2(1090, 270)},
                {"type": "boss", "pos": Vector2(1000, 365)},
                {"type": "sentinel", "pos": Vector2(1095, 465)},
                {"type": "hunter", "pos": Vector2(995, 545)}
            ]
        }
    ]

static func get_level(level_number: int) -> Dictionary:
    var levels := level_defs()
    var index := clampi(level_number, 1, levels.size()) - 1
    return levels[index].duplicate(true)

static func enemy_stats(kind: String, level_number: int) -> Dictionary:
    var level_scale := 1.0 + float(level_number - 1) * 0.10
    match kind:
        "shard":
            return {
                "name": "FRAGMENTO",
                "max_hp": 62.0 * level_scale,
                "damage": 19.0 * level_scale,
                "radius": 24.0,
                "armor": 0.0,
                "ai_speed": 760.0,
                "color": Color("ff607d"),
                "glyph": "shard"
            }
        "brute":
            return {
                "name": "ARiete",
                "max_hp": 132.0 * level_scale,
                "damage": 28.0 * level_scale,
                "radius": 34.0,
                "armor": 0.18,
                "ai_speed": 610.0,
                "color": Color("ee77ff"),
                "glyph": "brute"
            }
        "hunter":
            return {
                "name": "RASTREADOR",
                "max_hp": 82.0 * level_scale,
                "damage": 35.0 * level_scale,
                "radius": 25.0,
                "armor": 0.04,
                "ai_speed": 890.0,
                "color": Color("ff9b55"),
                "glyph": "hunter"
            }
        "boss":
            return {
                "name": "THAL'KRYN",
                "max_hp": 460.0,
                "damage": 42.0,
                "radius": 52.0,
                "armor": 0.22,
                "ai_speed": 670.0,
                "color": Color("5cd8e8"),
                "glyph": "boss"
            }
        _:
            return {
                "name": "CENTINELA",
                "max_hp": 94.0 * level_scale,
                "damage": 25.0 * level_scale,
                "radius": 28.0,
                "armor": 0.08,
                "ai_speed": 700.0,
                "color": Color("e85f86"),
                "glyph": "sentinel"
            }
