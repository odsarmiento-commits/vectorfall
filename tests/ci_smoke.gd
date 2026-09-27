extends SceneTree

const SCENES := [
    "res://scenes/main_menu.tscn",
    "res://scenes/game.tscn",
]

func _init() -> void:
    for scene_path in SCENES:
        var resource := load(scene_path)
        if resource == null or not resource is PackedScene:
            push_error("No se pudo cargar: %s" % scene_path)
            quit(1)
            return
        var instance := (resource as PackedScene).instantiate()
        if instance == null:
            push_error("No se pudo instanciar: %s" % scene_path)
            quit(1)
            return
        get_root().add_child(instance)
        await process_frame
        instance.queue_free()
        await process_frame

    print("VECTORFALL_CI_SMOKE_OK")
    quit(0)
