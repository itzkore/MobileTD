extends Control

## Simple ripple feedback: scales and fades on press.

@export var target_path: NodePath
@export var scale_amount: float = 0.06
@export var duration: float = 0.12

var _btn: BaseButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    if target_path != NodePath():
        _btn = get_node_or_null(target_path)
    if not _btn and owner and owner is BaseButton:
        _btn = owner
    if not _btn:
        _btn = get_parent() as BaseButton
    if _btn:
        _btn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
    var h := get_tree().root.get_node_or_null("Haptics")
    if h and h.has_method("tap"):
        h.tap()
    if not _btn:
        return
    var n := _btn as CanvasItem
    if n == null:
        return
    var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    var orig_scale: Vector2 = n.scale
    var orig_mod: Color = n.modulate
    if OS.has_feature("Android"):
        # On Android: avoid scaling to prevent rare GPU/Container crashes; do only an alpha flash.
        tween.tween_property(n, "modulate", Color(orig_mod.r, orig_mod.g, orig_mod.b, 0.85), duration * 0.5)
        tween.tween_property(n, "modulate", orig_mod, duration * 0.5)
    else:
        tween.tween_property(n, "scale", orig_scale * (1.0 + scale_amount), duration * 0.5)
        tween.parallel().tween_property(n, "modulate", Color(orig_mod.r, orig_mod.g, orig_mod.b, 0.85), duration * 0.5)
        tween.tween_property(n, "scale", orig_scale, duration * 0.5)
        tween.parallel().tween_property(n, "modulate", orig_mod, duration * 0.5)
