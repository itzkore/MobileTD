extends Node2D
class_name GridPainter

@export var cell_size: int = 64
@export var offset: Vector2 = Vector2.ZERO
@export var grid_color: Color = Color(1, 1, 1, 0.05)
@export var path_color: Color = Color(0.45, 0.35, 0.25, 1)
@export var path_edge_color: Color = Color(0.25, 0.18, 0.12, 1)
@export var spot_color: Color = Color(0.2, 0.6, 0.9, 0.15)

var _path_cells: Array[Vector2i] = []
var _spot_cells: Array[Vector2i] = []

func set_cells(path_cells: Array[Vector2i], spot_cells: Array[Vector2i]) -> void:
	_path_cells = path_cells.duplicate()
	_spot_cells = spot_cells.duplicate()
	queue_redraw()

func set_offset(o: Vector2) -> void:
	offset = o
	queue_redraw()

func _draw() -> void:
	# Draw grid lines
	var rect: Rect2 = get_viewport_rect()
	var w: int = int(rect.size.x)
	var h: int = int(rect.size.y)
	var cs: int = max(1, cell_size)
	var ox: float = fmod(offset.x, float(cs))
	var oy: float = fmod(offset.y, float(cs))
	for x in range(0, w + cs, cs):
		draw_line(Vector2(x + ox, 0), Vector2(x + ox, h), grid_color, 1.0, false)
	for y in range(0, h + cs, cs):
		draw_line(Vector2(0, y + oy), Vector2(w, y + oy), grid_color, 1.0, false)
	# Draw path cells with edge and body for crisp tile-like road
	var margin := 6.0
	for c in _path_cells:
		var p := offset + Vector2(c.x * cs, c.y * cs)
		draw_rect(Rect2(p, Vector2(cs, cs)), path_edge_color)
		draw_rect(Rect2(p + Vector2(margin, margin), Vector2(cs - 2.0 * margin, cs - 2.0 * margin)), path_color)
	# Draw spot cells as subtle squares
	for c in _spot_cells:
		var p2 := offset + Vector2(c.x * cs, c.y * cs)
		draw_rect(Rect2(p2 + Vector2(8, 8), Vector2(cs - 16, cs - 16)), spot_color)
