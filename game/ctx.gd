class_name Ctx
extends RefCounted
## Tarayıcıdaki Canvas 2D API'sinin küçük bir taklidi.
## Web sürümündeki çizim kodu satır satır buraya aktarılabilsin diye
## save/restore/translate/rotate/scale, yol (path) kurma, fill/stroke, clip,
## dikey gradyan ve kenarlıklı yazı destekler.

const TAU_ := PI * 2.0
const OL := "#2b1a10"

var ci: CanvasItem
var rid: RID
var font: SystemFont

# çizim durumu
var xf := Transform2D.IDENTITY
var fill_col := Color.WHITE
var stroke_col := Color.BLACK
var lw := 1.0
var alpha := 1.0
var clip_poly := PackedVector2Array() # tuval (global) koordinatında
var _stack: Array = []

# yol
var _subs: Array = [] # her biri {"p": PackedVector2Array, "c": bool}

static var _col_cache := {}

func _init(item: CanvasItem) -> void:
	ci = item
	rid = item.get_canvas_item()
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Trebuchet MS", "Segoe UI", "Verdana", "Roboto", "sans-serif"])
	font.font_weight = 700
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY

# ---------------------------------------------------------------- renk
static func col(s) -> Color:
	if s is Color:
		return s
	var k: String = s
	if _col_cache.has(k):
		return _col_cache[k]
	var c := Color.WHITE
	if k.begins_with("#"):
		c = Color.html(k)
	elif k.begins_with("rgb"):
		var inner := k.substr(k.find("(") + 1)
		inner = inner.substr(0, inner.find(")"))
		var parts := inner.split(",")
		c = Color(float(parts[0]) / 255.0, float(parts[1]) / 255.0, float(parts[2]) / 255.0, float(parts[3]) if parts.size() > 3 else 1.0)
	else:
		c = Color.from_string(k, Color.WHITE)
	_col_cache[k] = c
	return c

func set_fill(s) -> void:
	fill_col = col(s)

func set_stroke(s) -> void:
	stroke_col = col(s)

# ---------------------------------------------------------------- dönüşüm
func save() -> void:
	_stack.push_back([xf, fill_col, stroke_col, lw, alpha, clip_poly])

func restore() -> void:
	if _stack.is_empty():
		return
	var s: Array = _stack.pop_back()
	xf = s[0]; fill_col = s[1]; stroke_col = s[2]; lw = s[3]; alpha = s[4]; clip_poly = s[5]

func reset(base := Transform2D.IDENTITY) -> void:
	xf = base
	_stack.clear()
	alpha = 1.0
	clip_poly = PackedVector2Array()

func translate(x: float, y: float) -> void:
	xf = xf * Transform2D(0.0, Vector2(x, y))

func rotate(a: float) -> void:
	xf = xf * Transform2D(a, Vector2.ZERO)

func scale(sx: float, sy: float) -> void:
	xf = xf * Transform2D(Vector2(sx, 0), Vector2(0, sy), Vector2.ZERO)

func _sc() -> float:
	return max(0.05, sqrt(abs(xf.determinant())))

# ---------------------------------------------------------------- yol
func begin_path() -> void:
	_subs.clear()

func _cur() -> Dictionary:
	if _subs.is_empty():
		_subs.push_back({"p": PackedVector2Array(), "c": false})
	return _subs[-1]

func _add(p: Vector2) -> void:
	var s := _cur()
	var a: PackedVector2Array = s["p"]
	if a.size() > 0 and a[a.size() - 1].distance_squared_to(p) < 0.0001:
		return
	a.push_back(p)
	s["p"] = a

func move_to(x: float, y: float) -> void:
	_subs.push_back({"p": PackedVector2Array([Vector2(x, y)]), "c": false})

func line_to(x: float, y: float) -> void:
	_add(Vector2(x, y))

func close_path() -> void:
	if _subs.is_empty():
		return
	var s: Dictionary = _subs[-1]
	s["c"] = true
	var a: PackedVector2Array = s["p"]
	var start := a[0] if a.size() > 0 else Vector2.ZERO
	_subs.push_back({"p": PackedVector2Array([start]), "c": false})

func _last() -> Vector2:
	var a: PackedVector2Array = _cur()["p"]
	return a[a.size() - 1] if a.size() > 0 else Vector2.ZERO

func quad_to(cx: float, cy: float, x: float, y: float) -> void:
	var p0 := _last()
	var c := Vector2(cx, cy)
	var p1 := Vector2(x, y)
	var n := clampi(int((p0.distance_to(c) + c.distance_to(p1)) * _sc() / 6.0) + 3, 4, 24)
	for i in range(1, n + 1):
		var t := float(i) / n
		_add(p0.lerp(c, t).lerp(c.lerp(p1, t), t))

func bezier_to(c1x: float, c1y: float, c2x: float, c2y: float, x: float, y: float) -> void:
	var p0 := _last()
	var c1 := Vector2(c1x, c1y)
	var c2 := Vector2(c2x, c2y)
	var p1 := Vector2(x, y)
	var n := clampi(int((p0.distance_to(c1) + c1.distance_to(c2) + c2.distance_to(p1)) * _sc() / 6.0) + 3, 4, 32)
	for i in range(1, n + 1):
		var t := float(i) / n
		var u := 1.0 - t
		_add(p0 * u * u * u + c1 * 3.0 * u * u * t + c2 * 3.0 * u * t * t + p1 * t * t * t)

static func _sweep(a0: float, a1: float, ccw: bool) -> float:
	var s := a1 - a0
	if not ccw:
		if s >= TAU_:
			return TAU_
		s = fposmod(s, TAU_)
	else:
		if -s >= TAU_:
			return -TAU_
		s = -fposmod(-s, TAU_)
	return s

func ellipse(x: float, y: float, rx: float, ry: float, rot := 0.0, a0 := 0.0, a1 := TAU_, ccw := false) -> void:
	rx = max(0.1, abs(rx)); ry = max(0.1, abs(ry))
	var sw := _sweep(a0, a1, ccw)
	var n := clampi(int(abs(sw) * max(rx, ry) * _sc() / 3.0) + 4, 6, 72)
	var cr := cos(rot)
	var sr := sin(rot)
	for i in range(n + 1):
		var a := a0 + sw * float(i) / n
		var px := cos(a) * rx
		var py := sin(a) * ry
		_add(Vector2(x + px * cr - py * sr, y + px * sr + py * cr))

func arc(x: float, y: float, r: float, a0: float, a1: float, ccw := false) -> void:
	ellipse(x, y, r, r, 0.0, a0, a1, ccw)

func rect(x: float, y: float, w: float, h: float) -> void:
	move_to(x, y); line_to(x + w, y); line_to(x + w, y + h); line_to(x, y + h); close_path()

func round_rect(x: float, y: float, w: float, h: float, r: float) -> void:
	r = min(r, min(abs(w), abs(h)) / 2.0)
	move_to(x + r, y)
	line_to(x + w - r, y)
	arc(x + w - r, y + r, r, -PI / 2, 0)
	line_to(x + w, y + h - r)
	arc(x + w - r, y + h - r, r, 0, PI / 2)
	line_to(x + r, y + h)
	arc(x + r, y + h - r, r, PI / 2, PI)
	line_to(x, y + r)
	arc(x + r, y + r, r, PI, PI * 1.5)
	close_path()

# ---------------------------------------------------------------- boyama
func _ca(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * alpha)

func _draw_poly(poly: PackedVector2Array, c: Color, use_xf := true) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		# kendini kesen yol: Clipper ile düzelt
		for m in Geometry2D.merge_polygons(poly, PackedVector2Array()):
			if Geometry2D.is_polygon_clockwise(m) and m.size() >= 3:
				pass
			var i2 := Geometry2D.triangulate_polygon(m)
			if not i2.is_empty():
				RenderingServer.canvas_item_add_set_transform(rid, xf if use_xf else Transform2D.IDENTITY)
				RenderingServer.canvas_item_add_triangle_array(rid, i2, m, PackedColorArray([c]))
		return
	RenderingServer.canvas_item_add_set_transform(rid, xf if use_xf else Transform2D.IDENTITY)
	RenderingServer.canvas_item_add_triangle_array(rid, idx, poly, PackedColorArray([c]))

func fill(c = null) -> void:
	if c != null:
		set_fill(c)
	var cc := _ca(fill_col)
	if cc.a <= 0.002:
		return
	for s in _subs:
		var p: PackedVector2Array = s["p"]
		if p.size() < 3:
			continue
		if clip_poly.size() >= 3:
			var g := xf * p
			for q in Geometry2D.intersect_polygons(g, clip_poly):
				if q.size() >= 3:
					_draw_poly(q, cc, false)
		else:
			_draw_poly(p, cc)

func stroke() -> void:
	var cc := _ca(stroke_col)
	if cc.a <= 0.002:
		return
	ci.draw_set_transform_matrix(xf)
	for s in _subs:
		var p: PackedVector2Array = s["p"]
		if p.size() < 2:
			continue
		if s["c"]:
			p = p.duplicate()
			p.push_back(p[0])
		ci.draw_polyline(p, cc, lw, true)

func image(tex: Texture2D, x: float, y: float, w: float, h: float) -> void:
	ci.draw_set_transform_matrix(xf)
	ci.draw_texture_rect(tex, Rect2(x, y, w, h), false, Color(1, 1, 1, alpha))

## kesik çizgi (setLineDash taklidi)
func stroke_dashed(on: float, off: float) -> void:
	var cc := _ca(stroke_col)
	ci.draw_set_transform_matrix(xf)
	for s in _subs:
		var p: PackedVector2Array = s["p"]
		if p.size() < 2:
			continue
		if s["c"]:
			p = p.duplicate(); p.push_back(p[0])
		var drawing := true
		var left := on
		for i in range(p.size() - 1):
			var a := p[i]
			var b := p[i + 1]
			var seg := a.distance_to(b)
			var pos := 0.0
			while pos < seg:
				var step: float = min(left, seg - pos)
				if drawing:
					ci.draw_line(a.lerp(b, pos / seg), a.lerp(b, (pos + step) / seg), cc, lw, true)
				pos += step
				left -= step
				if left <= 0.0001:
					drawing = not drawing
					left = on if drawing else off

func clip() -> void:
	for s in _subs:
		var p: PackedVector2Array = s["p"]
		if p.size() >= 3:
			clip_poly = xf * p
			return

func fill_rect(x: float, y: float, w: float, h: float, c = null) -> void:
	begin_path(); rect(x, y, w, h); fill(c)

func stroke_rect(x: float, y: float, w: float, h: float) -> void:
	begin_path(); rect(x, y, w, h); stroke()

## dikey gradyan; stops = [[konum, renk], ...]
func vgrad_rect(x: float, y: float, w: float, h: float, stops: Array) -> void:
	for i in range(stops.size() - 1):
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		var y0: float = y + h * float(a[0])
		var y1: float = y + h * float(b[0])
		var ca := _ca(col(a[1]))
		var cb := _ca(col(b[1]))
		var pts := PackedVector2Array([Vector2(x, y0), Vector2(x + w, y0), Vector2(x + w, y1), Vector2(x, y1)])
		ci.draw_set_transform_matrix(xf)
		ci.draw_polygon(pts, PackedColorArray([ca, ca, cb, cb]))

# ---------------------------------------------------------------- kısayollar (web sürümündeki yardımcılar)
func circ(x: float, y: float, r: float, c = null) -> void:
	begin_path(); arc(x, y, max(0.1, r), 0, TAU_); fill(c)

func ell(x: float, y: float, rx: float, ry: float, c = null, rot := 0.0) -> void:
	begin_path(); ellipse(x, y, rx, ry, rot, 0, TAU_); fill(c)

func ln(a: float, b: float, c: float, d: float) -> void:
	begin_path(); move_to(a, b); line_to(c, d); stroke()

func rr(x: float, y: float, w: float, h: float, r: float) -> void:
	begin_path(); round_rect(x, y, w, h, r)

func star(x: float, y: float, r: float, rot: float, c) -> void:
	save(); translate(x, y); rotate(rot); begin_path()
	for i in 10:
		var a := i * PI / 5 - PI / 2
		var q := r * 0.45 if i % 2 else r
		line_to(cos(a) * q, sin(a) * q)
	close_path(); fill(c); set_stroke(OL); lw = 1.5; stroke(); restore()

# ---------------------------------------------------------------- yazı
func measure(s: String, size: float) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x

func _text_pos(s: String, x: float, y: float, size: int, align: String) -> Vector2:
	var w := measure(s, size)
	var ox := 0.0
	if align == "center":
		ox = -w / 2.0
	elif align == "right":
		ox = -w
	var base := y + (font.get_ascent(size) - font.get_descent(size)) / 2.0
	return Vector2(x + ox, base)

## web sürümündeki txt(): kalın, ortalı, kenarlıklı yazı
func txt(s: String, x: float, y: float, size: float, color = "#fff", align := "center", outline = OL, olw := -1.0) -> void:
	var sz := maxi(1, int(round(size)))
	var pos := _text_pos(s, x, y, sz, align)
	ci.draw_set_transform_matrix(xf)
	if outline != null:
		var w: float = olw if olw > 0 else maxf(3.0, size / 5.0)
		ci.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(round(w)), _ca(col(outline)))
	ci.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, _ca(col(color)))

func wrap(text: String, max_w: float, size: float) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for w in text.split(" "):
		var t := (cur + " " + w) if cur != "" else w
		if measure(t, size) > max_w and cur != "":
			out.push_back(cur)
			cur = w
		else:
			cur = t
	if cur != "":
		out.push_back(cur)
	return out
