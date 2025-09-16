extends Node

## UIScaler: centralized UI scaling for mobile/desktop
## Usage:
##   - Add to Autoload as "UIScaler"
##   - Call UIScaler.apply_to(root_control) in _ready of UI scenes

var scale_factor: float = 1.0

func _ready() -> void:
    scale_factor = _compute_scale()

func _compute_scale() -> float:
    # Base scale 1.0 for desktop, scale up for phones/tablets
    var dpi: float = float(DisplayServer.screen_get_dpi())
    var size: Vector2i = DisplayServer.window_get_size()
    var min_dim: int = min(size.x, size.y)

    var s: float = 1.0
    if min_dim <= 900:
        # Phone landscape/portrait
        s = 1.8 if dpi >= 320.0 else 1.5
    elif min_dim <= 1280:
        # Small tablet
        s = 1.4
    else:
        s = 1.0
    return clamp(s, 1.0, 2.2)

func apply_to(root: Control) -> void:
    if not is_instance_valid(root):
        return
    root.scale = Vector2(scale_factor, scale_factor)
    # Optional: increase default theme font sizes if present
    var theme := root.theme
    if theme:
        var base := int(14.0 * scale_factor)
        theme.set_font_size("font_size", "Label", max(14, base))
        theme.set_font_size("font_size", "Button", max(16, base + 2))
