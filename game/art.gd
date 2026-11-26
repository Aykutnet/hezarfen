class_name Art
extends RefCounted
## Web sürümündeki çizim fonksiyonlarının birebir aktarımı.
## c: Ctx (canvas taklidi), g: main düğümü (T, R, WX, cam, state'e erişim için).

const OL := "#2b1a10"
const TAU_ := PI * 2.0
const WATER_Y := 468.0
const GAL_G := 430.0
const TOWER_X := 160.0
const GALLERY_Y := 192.0
const GROUND_U := 440.0
const W := 960.0
const H := 540.0

var c: Ctx
var g

func _init(ctx: Ctx, main) -> void:
	c = ctx
	g = main

func T() -> float:
	return g.T

# ---------------------------------------------------------------- kanat / eşya / kafalık / insan
func draw_wing(ang: float, col, L: float) -> void:
	c.save(); c.rotate(ang)
	var tipY := -L * .14
	c.begin_path(); c.move_to(2, -3); c.quad_to(-L * .5, -L * .28, -L, tipY)
	var n := 6
	var px := -L
	var py := tipY
	for i in range(1, n + 1):
		var t := float(i) / n
		var nx: float = lerp(-L, 2.0, t)
		var ny: float = lerp(tipY + 3, 7.0, t)
		c.quad_to((px + nx) / 2, max(py, ny) + 11 * (1 - t * .5), nx, ny)
		px = nx; py = ny
	c.close_path(); c.fill(col); c.set_stroke(OL); c.lw = 2; c.stroke()
	c.set_stroke("rgba(110,70,30,.45)"); c.lw = 1.2
	for i in range(1, n):
		var t := float(i) / n
		var x: float = lerp(-L, 2.0, t)
		c.ln(x * .92, lerp(tipY, -3.0, t) - L * .1 * sin(t * PI), x, lerp(tipY + 3, 7.0, t) + 8)
	c.set_stroke("#7a4a22"); c.lw = 3; c.begin_path(); c.move_to(2, -3); c.quad_to(-L * .5, -L * .28, -L, tipY); c.stroke()
	c.restore()

func draw_terlik_shape() -> void:
	c.ell(0, 0, 5, 10, "#b5651d"); c.set_stroke(OL); c.lw = 1.5; c.stroke(); c.fill_rect(-5, -4, 10, 4, "#e67e22")

func draw_item(k: String) -> void:
	c.set_stroke(OL); c.lw = 1.5
	match k:
		"terlik":
			c.save(); c.translate(0, 24); draw_terlik_shape(); c.restore()
		"baston":
			c.set_stroke("#6e4b2a"); c.lw = 3.5; c.ln(0, 8, 0, 44); c.begin_path(); c.arc(-5, 8, 5, 0, PI, true); c.stroke()
		"sucuk":
			c.set_stroke("#8b1e1e"); c.lw = 7; c.begin_path(); c.move_to(0, 14); c.quad_to(18, 32, 0, 48); c.stroke(); c.set_stroke("#fff"); c.lw = 2; c.ln(-1, 47, -5, 53)
		"balik":
			c.save(); c.translate(0, 32); c.ell(0, 0, 6, 15, "#b8c6d1"); c.stroke(); c.begin_path(); c.move_to(0, 13); c.line_to(-7, 22); c.line_to(7, 22); c.close_path(); c.fill("#b8c6d1"); c.stroke(); c.circ(2, -9, 1.5, "#111"); c.restore()
		"oklava":
			c.set_stroke("#e2c08d"); c.lw = 5; c.ln(0, 2, 0, 46)
		"sapan":
			c.set_stroke("#7a5230"); c.lw = 3; c.ln(0, 16, 0, 30); c.ln(0, 22, -5, 13); c.ln(0, 22, 5, 13); c.set_stroke("#c0392b"); c.lw = 1.5; c.ln(-5, 13, 5, 13)
		"cop":
			c.set_stroke("#2a2a2a"); c.lw = 4.5; c.ln(0, 10, 0, 40)
		"kepce":
			c.set_stroke("#95a5a6"); c.lw = 3; c.ln(0, 6, 0, 36); c.begin_path(); c.arc(0, 38, 8, 0, PI); c.close_path(); c.fill("#bdc3c7"); c.set_stroke(OL); c.lw = 1.5; c.stroke()
		"ferman":
			c.save(); c.translate(0, 20); c.fill_rect(-4, -2, 8, 26, "#f6e7b8"); c.stroke_rect(-4, -2, 8, 26); c.circ(0, 24, 3, "#c0392b"); c.restore()
		"mendil":
			c.begin_path(); c.move_to(0, 18); c.line_to(13, 26 + sin(T() * 12) * 4); c.line_to(2, 34); c.close_path(); c.fill("#e74c3c")
		"muhur":
			c.set_stroke("#5d4037"); c.lw = 4; c.ln(0, 10, 0, 30); c.fill_rect(-9, 30, 18, 9, "#c0392b"); c.set_stroke(OL); c.lw = 1.5; c.stroke_rect(-9, 30, 18, 9); c.circ(0, 8, 4, "#8d6e63"); c.stroke()
		"tokmak":
			c.set_stroke("#6e4b2a"); c.lw = 3.5; c.ln(0, 10, 0, 38); c.rr(-11, 34, 22, 12, 3); c.fill("#8d5a2b"); c.set_stroke(OL); c.lw = 1.5; c.stroke()
		"firca":
			c.set_stroke("#8d6e63"); c.lw = 4; c.ln(0, 14, 0, 26); c.set_fill("#fff"); c.circ(0, 30, 6); c.circ(-4, 33, 4); c.circ(4, 33, 4)
		"havlu":
			var s := sin(T() * 10) * 3
			c.begin_path(); c.move_to(-3, 16); c.line_to(3, 16); c.line_to(5 + s, 48); c.line_to(-5 + s, 48); c.close_path(); c.fill("#fdfefe"); c.stroke(); c.fill_rect(-4 + s * .7, 38, 9, 3, "#c0392b")
		"tespih":
			c.set_fill("#16a085")
			for i in 9:
				var a := i / 9.0 * TAU_
				c.circ(sin(a) * 6, 27 + cos(a) * 9, 2)
			c.circ(0, 38, 2.5, "#d4ac0d")

func draw_hat(o: Dictionary, hy: float) -> void:
	c.set_stroke(OL); c.lw = 2
	match str(o.get("hat", "")):
		"kavuk":
			c.ell(0, hy - 14, 16, 11, "#fbf6e9"); c.stroke(); c.set_stroke("rgba(150,130,100,.6)"); c.lw = 1.5
			c.begin_path(); c.ellipse(0, hy - 14, 13, 6, 0, 0, PI); c.stroke(); c.begin_path(); c.ellipse(0, hy - 18, 11, 4, 0, 0, PI); c.stroke()
			c.ell(0, hy - 24, 6, 4.5, "#c0392b"); c.set_stroke(OL); c.lw = 1.5; c.stroke()
		"fes":
			c.begin_path(); c.move_to(-8, hy - 7); c.line_to(8, hy - 7); c.line_to(6, hy - 21); c.line_to(-6, hy - 21); c.close_path(); c.fill("#c0392b"); c.stroke()
			c.set_stroke("#222"); c.lw = 2; c.begin_path(); c.move_to(0, hy - 21); c.quad_to(-8, hy - 20, -9, hy - 10); c.stroke()
		"scarf":
			c.set_stroke(o.get("scarf", "#e74c3c")); c.lw = 6; c.begin_path(); c.arc(0, hy + 1, 12, PI * 1.05, PI * 1.92); c.stroke()
			c.set_fill("#fff")
			for i in 4: c.circ(-10 + i * 2, hy - 8 + i * 5, 1.3)
			c.circ(-12, hy + 4, 1.3)
		"cap":
			c.ell(0, hy - 8, 11.5, 6, o.get("capc", "#2980b9")); c.stroke(); c.ell(9, hy - 7, 7, 2.2, o.get("capc", "#2980b9")); c.stroke()
		"bekci":
			c.fill_rect(-10, hy - 21, 20, 13, "#1b2540"); c.stroke_rect(-10, hy - 21, 20, 13); c.ell(4, hy - 8, 13, 3, "#111"); c.circ(0, hy - 15, 2.5, "#f1c40f")
		"takke":
			c.begin_path(); c.arc(0, hy - 4, 11.5, PI, 0); c.close_path(); c.fill("#7f8c8d"); c.stroke()
		"bald":
			c.ell(-3, hy - 7, 4, 2, "rgba(255,255,255,.6)")
		"ulak":
			c.begin_path(); c.move_to(-9, hy - 7); c.line_to(9, hy - 7); c.line_to(5, hy - 34); c.line_to(-5, hy - 34); c.close_path(); c.fill("#fdfdfd"); c.stroke()
			c.fill_rect(-9, hy - 11, 18, 4, "#e3b23c"); c.ell(-6, hy - 38, 4, 11, "#e67e22", -.5)
		"yenicer":
			c.begin_path(); c.move_to(-9, hy - 7); c.line_to(9, hy - 7); c.line_to(6, hy - 40); c.quad_to(-6, hy - 44, -10, hy - 36); c.quad_to(-20, hy - 22, -22, hy - 6); c.quad_to(-14, hy - 12, -9, hy - 7); c.close_path(); c.fill("#fdfdfd"); c.stroke()
			c.fill_rect(-10, hy - 12, 20, 5, "#d4ac0d"); c.stroke_rect(-10, hy - 12, 20, 5); c.ell(4, hy - 22, 2.5, 5, "#d4ac0d")
		"havlu":
			c.ell(0, hy - 9, 13, 8, "#f8f8f8"); c.stroke(); c.set_stroke("#c0392b"); c.lw = 2; c.ln(-11, hy - 11, 11, hy - 11); c.ln(-12, hy - 6, 12, hy - 6)
		"sarik":
			c.ell(0, hy - 14, 18, 13, o.get("sarikc", "#fbfbf3")); c.stroke(); c.set_stroke("rgba(0,0,0,.18)"); c.lw = 2
			for i in 3:
				c.begin_path(); c.ellipse(0, hy - 11 - i * 5, 16 - i * 2, 5, -.25, 0, PI); c.stroke()
			c.circ(6, hy - 18, 3.2, "#27ae60"); c.set_stroke(OL); c.lw = 1.2; c.stroke(); c.ell(8, hy - 28, 2.5, 8, "#fff", .4); c.stroke()
		"tencere":
			c.fill_rect(-13, hy - 25, 26, 17, "#a4acb3"); c.stroke_rect(-13, hy - 25, 26, 17); c.ell(0, hy - 8, 16, 3.5, "#7f8a93"); c.stroke()
			c.lw = 3; c.set_stroke("#555"); c.ln(-13, hy - 19, -19, hy - 21); c.ln(13, hy - 19, 19, hy - 21); c.fill_rect(-9, hy - 23, 4, 12, "rgba(255,255,255,.55)")
	if o.get("salvar", false):
		var off := {"kavuk": -27, "sarik": -28, "tencere": -27, "yenicer": -44, "fes": -24}
		c.save(); c.translate(0, hy + off.get(o.get("hat", ""), -12)); c.set_stroke(OL); c.lw = 1.6
		c.ell(-11, 7, 7, 12, "#ff8cc6", .35); c.stroke(); c.ell(11, 7, 7, 12, "#ff8cc6", -.35); c.stroke()
		c.rr(-14, -4, 28, 8, 3); c.fill("#ff8cc6"); c.stroke(); c.set_fill("#fff")
		for p in [[-12, 4], [-9, 11], [11, 4], [9, 12], [-4, 0], [5, 0]]: c.circ(p[0], p[1], 1.6)
		c.restore()

## yandan görünüş insan, (x,y) = ayaklar
func draw_person(x: float, y: float, o: Dictionary) -> void:
	var s: float = o.get("s", 1.0)
	var f: float = o.get("f", 1.0)
	c.save(); c.translate(x, y - float(o.get("z", 0.0))); c.scale(s * f, s)
	if o.get("rot", 0.0):
		c.translate(0, -30); c.rotate(o["rot"]); c.translate(0, 30)
	var sw: float = sin(float(o.get("ph", 0.0))) * float(o.get("run", 0.0))
	var skin = o.get("skin", "#f1c27d")
	var sleeve = o.get("sleeve", "#5a3a20")
	var wc = o.get("wc", null)
	if o.get("wings", false):
		c.save(); c.translate(-4, -41); draw_wing(float(o.get("wa", 0.0)) + .2, wc[0] if wc else "#d6c39b", o.get("wl", 60.0)); c.restore()
	c.set_stroke(sleeve); c.lw = 6; c.ln(-3, -40, -3 - sw * 8, -26)
	c.set_stroke(o.get("pants", "#3b2a1e")); c.lw = 6
	var l1 := sw * 9
	c.ln(-4, -16, -4 + l1, -3); c.ln(4, -16, 4 - l1, -3)
	c.set_fill(o.get("shoe", "#6b2d14")); c.ell(-4 + l1 + 3, -2, 6, 3.5); c.ell(4 - l1 + 3, -2, 6, 3.5)
	var w: float = o.get("wide", 1.0)
	c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.move_to(-12 * w, -13); c.quad_to(-15 * w, -37, -9, -46); c.line_to(9, -46); c.quad_to(15 * w, -37, 12 * w, -13); c.quad_to(0, -9, -12 * w, -13); c.close_path()
	c.fill(o["body"]); c.stroke()
	if o.get("sash", null):
		c.fill_rect(-13.5 * w, -31, 27 * w, 5, o["sash"])
	if o.get("apron", null):
		c.begin_path(); c.move_to(1, -42); c.line_to(11, -42); c.line_to(13 * w, -14); c.line_to(0, -12); c.close_path(); c.fill("#f5f5ef"); c.stroke()
		c.set_fill("rgba(200,30,30,.6)"); c.circ(8, -24, 2); c.circ(5, -30, 1.5)
	var hy := -56.0
	var mood: String = o.get("mood", "normal")
	if o.get("hat", "") == "scarf":
		c.ell(-3, hy - 1, 14, 13.5, o.get("scarf", "#e74c3c")); c.stroke()
	c.circ(0, hy, 11, skin); c.stroke()
	c.circ(10, hy + 1, 4.5, o.get("nose", "#e9a46e")); c.stroke()
	if mood == "dizzy":
		c.set_stroke(OL); c.lw = 1.8; c.ln(2, hy - 6, 7, hy - 1); c.ln(7, hy - 6, 2, hy - 1)
	elif mood == "happy":
		c.set_stroke(OL); c.lw = 2; c.begin_path(); c.arc(4.5, hy - 2, 3, PI * 1.1, PI * 1.9); c.stroke()
	else:
		c.circ(4.5, hy - 3, 3.3, "#fff"); c.set_stroke(OL); c.lw = 1; c.stroke(); c.circ(5.5 + float(o.get("look", 0.0)), hy - 3, 1.8, "#111")
	c.set_stroke(OL); c.lw = 2.2
	if mood == "angry": c.ln(0, hy - 10, 8, hy - 6)
	elif mood == "scared" or mood == "surprised": c.ln(0, hy - 10, 8, hy - 12)
	else: c.ln(0, hy - 8.5, 8, hy - 8.5)
	if o.get("beard", null):
		c.begin_path(); c.move_to(-7, hy + 2); c.quad_to(-4, hy + 19, 4, hy + 17); c.quad_to(10, hy + 13, 10, hy + 6); c.quad_to(3, hy + 9, -7, hy + 2); c.fill(o["beard"])
	var shout: float = o.get("shout", 0.0)
	if shout > 0:
		c.ell(6.5, hy + 8, 3.2, 2 + shout * 3.5, "#5a0f0f")
	elif mood == "happy" or mood == "smile":
		c.set_stroke(OL); c.lw = 1.8; c.begin_path(); c.arc(6, hy + 5, 3.5, .2, PI - .4); c.stroke()
	else:
		c.set_stroke(OL); c.lw = 1.8; c.ln(3, hy + 8, 8.5, hy + 7)
	if o.get("must", null):
		c.ell(8.5, hy + 5.5, 6, 2.4, o["must"])
	draw_hat(o, hy)
	if o.get("wings", false):
		c.save(); c.translate(-2, -41); draw_wing(float(o.get("wa", 0.0)), wc[1] if wc else "#f6ecd4", o.get("wl", 60.0)); c.restore()
	c.save(); c.translate(2, -41); c.rotate(o["arm"] if o.has("arm") else sw * .7)
	c.set_stroke(sleeve); c.lw = 6; c.ln(0, 0, 0, 14); c.circ(0, 16.5, 3.6, skin); c.set_stroke(OL); c.lw = 1; c.stroke()
	if o.get("item", null):
		draw_item(o["item"])
	c.restore()
	c.restore()

func shadow(x: float, y: float, r: float, z := 0.0) -> void:
	var k := 1.0 / (1.0 + z / 60.0)
	c.ell(x, y, r * 1.25 * k, r * .45 * k, "rgba(0,0,0,.22)")

func draw_feather(x: float, y: float, s := 1.0) -> void:
	c.save(); c.translate(x, y); c.rotate(.6 + sin(T() * 3) * .2); c.scale(s, s)
	c.ell(0, 0, 7, 20, "#fffbe8"); c.set_stroke(OL); c.lw = 2; c.stroke(); c.set_stroke("#c9a86a"); c.ln(0, -18, 0, 26)
	c.restore()

func kavuk_icon(x: float, y: float, on: bool, s := 1.0) -> void:
	c.save(); c.translate(x, y); c.scale(s, s); c.alpha = 1.0 if on else .25
	c.ell(0, 0, 13, 9, "#fbf6e9"); c.set_stroke(OL); c.lw = 2; c.stroke(); c.ell(0, -8, 5, 4, "#c0392b"); c.stroke()
	c.restore()

# ---------------------------------------------------------------- uçuş dünyası
func hill_y(x: float) -> float:
	return WATER_Y - 26 - (sin(x * .0045) * 12 + sin(x * .013 + 1) * 7 + 14)

func draw_cloud(x: float, y: float, s: float) -> void:
	c.set_fill("rgba(255,255,255,.92)"); c.circ(x, y, 22 * s); c.circ(x + 24 * s, y - 10 * s, 26 * s); c.circ(x + 50 * s, y, 20 * s); c.ell(x + 24 * s, y + 8 * s, 46 * s, 14 * s)

func draw_skyline(off: float, col, dy: float, skyl: Array) -> void:
	c.save(); c.translate(-off, dy); c.set_fill(col)
	c.begin_path(); c.move_to(off - 20, WATER_Y)
	var x := off - 20
	while x <= off + W + 40:
		c.line_to(x, hill_y(x)); x += 20
	c.line_to(off + W + 40, WATER_Y); c.close_path(); c.fill()
	for b in skyl:
		if b.x + b.w < off - 150 or b.x > off + W + 150:
			continue
		var hy: float = hill_y(b.x + b.w / 2) + 4
		if b.t == "h":
			c.fill_rect(b.x, hy - b.h, b.w, b.h); c.begin_path(); c.move_to(b.x - 3, hy - b.h); c.line_to(b.x + b.w / 2, hy - b.h - 10); c.line_to(b.x + b.w + 3, hy - b.h); c.fill()
		else:
			var cx: float = b.x + b.w / 2
			c.fill_rect(b.x + 15, hy - 35, b.w - 30, 35); c.begin_path(); c.arc(cx, hy - 35, 32, PI, 0); c.fill(); c.fill_rect(cx - 2, hy - 80, 4, 15)
			for mx in [b.x + 4, b.x + b.w - 4]:
				c.fill_rect(mx - 3, hy - 90, 6, 90); c.begin_path(); c.move_to(mx - 4, hy - 90); c.line_to(mx, hy - 110); c.line_to(mx + 4, hy - 90); c.fill(); c.fill_rect(mx - 5, hy - 70, 10, 3)
	c.restore()

func draw_water(cam: float) -> void:
	var R: Dictionary = g.R
	var lodos: bool = g.WX == "lodos"
	c.vgrad_rect(0, WATER_Y, W, H - WATER_Y, [[0, R.wa[0]], [1, R.wa[1]]])
	c.begin_path(); c.move_to(0, WATER_Y + 6)
	var x := 0.0
	while x <= W:
		c.line_to(x, WATER_Y + sin((x + cam) * .04 + T() * 2.5) * (8.0 if lodos else 3.0)); x += 12
	c.line_to(W, WATER_Y + 6); c.close_path(); c.fill(R.wa[2])
	c.set_stroke("rgba(255,255,255,.35)"); c.lw = 2
	for i in 14:
		var xx: float = fposmod(i * 137 - cam * .9, W)
		var y := WATER_Y + 18 + (i * 29) % 60
		c.ln(xx, y, xx + 18 + sin(T() + i) * 6, y)

func draw_house(x: float, base: float, w: float, h: float, col, roof = "#a5452c") -> void:
	c.set_stroke(OL); c.lw = 2; c.fill_rect(x, base - h, w, h, col); c.stroke_rect(x, base - h, w, h)
	c.begin_path(); c.move_to(x - 6, base - h); c.line_to(x + w / 2, base - h - w * .35); c.line_to(x + w + 6, base - h); c.close_path(); c.fill(roof); c.stroke()
	c.set_fill("#f4d03f" if g.R.get("night", 0) else "#4a3428")
	var n := maxi(1, int(w / 22))
	for i in n:
		var wx := x + (w / n) * (i + .5) - 5
		c.fill_rect(wx, base - h + 10, 10, 13)
		if h > 55: c.fill_rect(wx, base - h + 32, 10, 13)

func draw_galata(x: float) -> void:
	c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.move_to(x - 40, GAL_G); c.line_to(x - 33, GALLERY_Y + 8); c.line_to(x + 33, GALLERY_Y + 8); c.line_to(x + 40, GAL_G); c.close_path(); c.fill("#cbb595"); c.stroke()
	c.set_stroke("rgba(90,70,50,.25)"); c.lw = 1
	var y := GALLERY_Y + 24
	while y < GAL_G:
		c.ln(x - 37, y, x + 37, y); y += 16
	c.set_fill("#3d2f25")
	for wy in [250, 310, 370]:
		for wx in [-15, 8]:
			c.rr(x + wx, wy, 8, 16, 4); c.fill()
	c.set_stroke(OL); c.lw = 2; c.fill_rect(x - 28, GALLERY_Y - 40, 56, 48, "#d8c6a8"); c.stroke_rect(x - 28, GALLERY_Y - 40, 56, 48)
	c.set_fill("#3d2f25")
	for wx in [-20, -5, 10]:
		c.rr(x + wx, GALLERY_Y - 32, 10, 22, 5); c.fill()
	c.begin_path(); c.move_to(x - 34, GALLERY_Y - 38); c.line_to(x, GALLERY_Y - 125); c.line_to(x + 34, GALLERY_Y - 38); c.close_path(); c.fill("#5f7184"); c.stroke()
	c.set_stroke("#444"); c.ln(x, GALLERY_Y - 125, x, GALLERY_Y - 140); c.circ(x, GALLERY_Y - 141, 3, "#e3b23c")
	c.fill_rect(x - 44, GALLERY_Y, 88, 8, "#6d5a48"); c.set_stroke(OL); c.stroke_rect(x - 44, GALLERY_Y, 88, 8)

func draw_galata_rail(x: float) -> void:
	var hw := 34 if g.R.start == "minare" else 44
	c.set_stroke("#6d5a48"); c.lw = 2
	var i := -hw + 2
	while i <= hw - 2:
		c.ln(x + i, GALLERY_Y, x + i, GALLERY_Y - 12); i += 7
	c.lw = 3; c.ln(x - hw, GALLERY_Y - 12, x + hw, GALLERY_Y - 12)

func draw_minare(x: float) -> void:
	c.set_stroke(OL); c.lw = 2
	var dx := x - 190
	c.fill_rect(dx - 120, GAL_G - 120, 240, 120, "#e8b9a0"); c.stroke_rect(dx - 120, GAL_G - 120, 240, 120)
	c.set_fill("#9aa7b5"); c.begin_path(); c.arc(dx, GAL_G - 120, 80, PI, 0); c.close_path(); c.fill(); c.stroke()
	for sx in [-95, 95]:
		c.begin_path(); c.arc(dx + sx, GAL_G - 120, 30, PI, 0); c.close_path(); c.fill(); c.stroke()
	c.set_fill("#4a3428")
	for i in 7:
		c.rr(dx - 105 + i * 32, GAL_G - 95, 12, 22, 6); c.fill()
	c.set_stroke("#d4ac0d"); c.lw = 2.5; c.ln(dx, GAL_G - 200, dx, GAL_G - 218); c.set_stroke(OL); c.lw = 2
	c.fill_rect(x - 13, GALLERY_Y + 8, 26, GAL_G - GALLERY_Y - 8, "#efe3d0"); c.stroke_rect(x - 13, GALLERY_Y + 8, 26, GAL_G - GALLERY_Y - 8)
	c.fill_rect(x - 18, GAL_G - 40, 36, 40, "#e3d5bd"); c.stroke_rect(x - 18, GAL_G - 40, 36, 40)
	c.fill_rect(x - 10, GALLERY_Y - 50, 20, 50, "#efe3d0"); c.stroke_rect(x - 10, GALLERY_Y - 50, 20, 50)
	c.begin_path(); c.move_to(x - 12, GALLERY_Y - 50); c.line_to(x, GALLERY_Y - 130); c.line_to(x + 12, GALLERY_Y - 50); c.close_path(); c.fill("#8797a8"); c.stroke()
	c.set_stroke("#d4ac0d"); c.ln(x, GALLERY_Y - 130, x, GALLERY_Y - 142); c.set_stroke(OL)
	c.begin_path(); c.move_to(x - 34, GALLERY_Y); c.line_to(x + 34, GALLERY_Y); c.line_to(x + 16, GALLERY_Y + 18); c.line_to(x - 16, GALLERY_Y + 18); c.close_path(); c.fill("#d8c6a8"); c.stroke()
	c.fill_rect(x - 36, GALLERY_Y, 72, 6, "#6d5a48"); c.stroke_rect(x - 36, GALLERY_Y, 72, 6)

func draw_fener(x: float) -> void:
	c.set_stroke(OL); c.lw = 2
	c.save(); c.alpha = .16
	var a := sin(T() * .8)
	c.begin_path(); c.move_to(x, GALLERY_Y - 20); c.line_to(x + 700, GALLERY_Y - 80 - 160 * a); c.line_to(x + 700, GALLERY_Y + 40 - 160 * a); c.close_path(); c.fill("#fff6b0"); c.restore()
	c.begin_path(); c.move_to(x - 38, GAL_G); c.line_to(x - 26, GALLERY_Y + 8); c.line_to(x + 26, GALLERY_Y + 8); c.line_to(x + 38, GAL_G); c.close_path(); c.fill("#fdfdfd")
	c.save(); c.clip()
	var y := GALLERY_Y + 8
	while y < GAL_G:
		c.fill_rect(x - 40, y, 80, 28, "#e74c3c"); y += 56
	c.restore()
	c.begin_path(); c.move_to(x - 38, GAL_G); c.line_to(x - 26, GALLERY_Y + 8); c.line_to(x + 26, GALLERY_Y + 8); c.line_to(x + 38, GAL_G); c.close_path(); c.stroke()
	c.fill_rect(x - 20, GALLERY_Y - 38, 40, 38, "#34495e"); c.stroke_rect(x - 20, GALLERY_Y - 38, 40, 38)
	c.fill_rect(x - 15, GALLERY_Y - 34, 30, 28, Color(1, 240.0 / 255, 150.0 / 255, .75 + sin(T() * 4) * .25))
	c.begin_path(); c.arc(x, GALLERY_Y - 38, 22, PI, 0); c.close_path(); c.fill("#c0392b"); c.stroke()
	c.fill_rect(x - 44, GALLERY_Y, 88, 8, "#6d5a48"); c.stroke_rect(x - 44, GALLERY_Y, 88, 8)

func draw_start(x: float) -> void:
	match g.R.start:
		"minare": draw_minare(x)
		"fener": draw_fener(x)
		_: draw_galata(x)

func draw_galleon(x: float, pir: bool) -> void:
	var b := WATER_Y + sin(T() * 1.5) * 2
	c.set_stroke("#4a2f17"); c.lw = 5; c.ln(x - 30, b - 40, x - 30, b - 218); c.ln(x + 40, b - 44, x + 40, b - 196); c.lw = 1.5; c.ln(x - 30, b - 200, x + 112, b - 50); c.ln(x - 30, b - 200, x - 104, b - 64)
	var sail := "#2f2f2f" if pir else "#f3ead2"
	c.set_stroke(OL); c.lw = 2
	for e in [[-30, -205, 34], [-30, -142, 40], [40, -186, 30], [40, -128, 36]]:
		var mx: float = e[0]; var top: float = e[1]; var w: float = e[2]
		c.begin_path(); c.move_to(x + mx - w, b + top); c.line_to(x + mx + w, b + top); c.quad_to(x + mx + w + 9, b + top + 28, x + mx + w, b + top + 55); c.line_to(x + mx - w, b + top + 55); c.quad_to(x + mx - w + 9, b + top + 28, x + mx - w, b + top); c.close_path(); c.fill(sail); c.stroke()
	if pir:
		c.circ(x - 26, b - 118, 11, "#fff"); c.circ(x - 30, b - 120, 3, "#111"); c.circ(x - 22, b - 120, 3, "#111"); c.set_stroke("#fff"); c.lw = 3; c.ln(x - 42, b - 104, x - 10, b - 96); c.ln(x - 42, b - 96, x - 10, b - 104)
	else:
		c.circ(x - 24, b - 114, 10, "#c0392b"); c.circ(x - 20, b - 114, 8, sail)
	c.set_stroke(OL); c.lw = 2; c.begin_path(); c.move_to(x - 30, b - 218); c.line_to(x - 4, b - 212 + sin(T() * 6) * 3); c.line_to(x - 30, b - 204); c.close_path(); c.fill("#111" if pir else "#c0392b"); c.stroke()
	c.begin_path(); c.move_to(x - 105, b - 42); c.line_to(x + 115, b - 50); c.quad_to(x + 98, b + 5, x + 62, b + 10); c.line_to(x - 72, b + 10); c.quad_to(x - 102, b - 4, x - 105, b - 42); c.close_path(); c.fill("#3b2416" if pir else "#7a4a22"); c.stroke()
	c.fill_rect(x - 105, b - 66, 62, 24, "#5a3a22" if pir else "#a0662f"); c.stroke_rect(x - 105, b - 66, 62, 24)
	c.fill_rect(x - 100, b - 36, 205, 4, "#e3b23c")
	for i in 6: c.circ(x - 70 + i * 30, b - 20, 4.5, "#111")
	draw_person(x + 70, b - 48, {"s": .5, "f": -1.0, "body": "#8e2b2b" if pir else "#2c3e70", "sleeve": "#444", "hat": "scarf" if pir else "fes", "scarf": "#111", "must": "#222", "beard": "#222" if pir else null, "mood": "angry", "arm": -2.4 + sin(T() * 6) * .3})
	c.txt("KORSAN GEMİSİ" if pir else "TERSANE KALYONU", x, b - 236, 13, "#fff")

func draw_kk(x: float) -> void:
	var b := WATER_Y
	c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.ellipse(x, b + 4, 80, 18, 0, PI, 0); c.close_path(); c.fill("#7d7468"); c.stroke()
	c.fill_rect(x - 50, b - 38, 100, 36, "#efe8da"); c.stroke_rect(x - 50, b - 38, 100, 36)
	c.set_fill("#4a5a6a")
	for wx in [-38, -22, 16, 30]: c.fill_rect(x + wx, b - 28, 7, 12)
	c.begin_path(); c.move_to(x - 54, b - 38); c.line_to(x + 54, b - 38); c.line_to(x + 44, b - 48); c.line_to(x - 44, b - 48); c.close_path(); c.fill("#8a9aaa"); c.stroke()
	c.fill_rect(x - 17, b - 185, 34, 140, "#f5f0e6"); c.stroke_rect(x - 17, b - 185, 34, 140)
	c.set_fill("#4a5a6a")
	for i in 4:
		c.rr(x - 5, b - 172 + i * 32, 10, 16, 5); c.fill()
	c.fill_rect(x - 24, b - 192, 48, 8, "#d8d0c0"); c.stroke_rect(x - 24, b - 192, 48, 8)
	c.fill_rect(x - 11, b - 214, 22, 22, "#f5f0e6"); c.stroke_rect(x - 11, b - 214, 22, 22)
	c.begin_path(); c.move_to(x - 14, b - 214); c.quad_to(x - 6, b - 232, x, b - 246); c.quad_to(x + 6, b - 232, x + 14, b - 214); c.close_path(); c.fill("#7f93a8"); c.stroke()
	c.set_stroke("#555"); c.lw = 1.5; c.ln(x, b - 246, x, b - 262)
	c.begin_path(); c.move_to(x, b - 262); c.line_to(x + 14, b - 258 + sin(T() * 6) * 2); c.line_to(x, b - 254); c.fill("#c0392b")
	c.txt("KIZ KULESİ", x, b - 280, 13, "#fff")

func draw_mid(x: float) -> void:
	if g.R.mid == "kk": draw_kk(x)
	else: draw_galleon(x, g.R.mid == "korsan")

func draw_evliya(o: Dictionary) -> void:
	var x: float = o.x
	var y: float = o.y
	var sq: float = 1 + sin(o.sq * 30) * .14 * o.sq if o.sq > 0 else 1.0
	c.set_stroke("#6e4b2a"); c.lw = 1.5; c.ln(x - 26, y - 44, x - 16, y - 8); c.ln(x + 26, y - 44, x + 16, y - 8)
	c.save(); c.translate(x, y - 80); c.scale(1 / sq, sq); c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.move_to(-26, 38); c.bezier_to(-72, 0, -56, -60, 0, -60); c.bezier_to(56, -60, 72, 0, 26, 38); c.close_path(); c.fill("#e74c3c")
	c.save(); c.clip()
	var i := -3
	while i <= 3:
		c.fill_rect(i * 12 - 6, -62, 12, 104, "#f1c40f"); i += 2
	c.restore()
	c.begin_path(); c.move_to(-26, 38); c.bezier_to(-72, 0, -56, -60, 0, -60); c.bezier_to(56, -60, 72, 0, 26, 38); c.close_path(); c.stroke(); c.restore()
	draw_person(x + 2, y + 4, {"s": .5, "f": -1.0, "body": "#16a085", "sleeve": "#138d75", "hat": "sarik", "beard": "#5a3a20", "must": "#5a3a20", "mood": "smile", "arm": -1.3 + sin(T() * 9) * .25})
	c.set_stroke(OL); c.lw = 2; c.rr(x - 18, y - 10, 36, 20, 4); c.fill("#a0703a"); c.stroke(); c.set_stroke("rgba(60,30,10,.5)"); c.lw = 1; c.ln(x - 18, y - 3, x + 18, y - 3); c.ln(x - 18, y + 4, x + 18, y + 4)
	c.set_stroke(OL); c.fill_rect(x - 16, y - 18, 11, 8, "#fdf6e3"); c.stroke_rect(x - 16, y - 18, 11, 8)
	c.txt("EVLİYA ÇELEBİ", x, y - 152, 12, "#fff")

func draw_mosque(x: float, base: float) -> void:
	c.set_stroke(OL); c.lw = 2
	for mx in [x - 118, x + 118]:
		c.fill_rect(mx - 6, base - 240, 12, 240, "#ece6d6"); c.stroke_rect(mx - 6, base - 240, 12, 240); c.fill_rect(mx - 9, base - 180, 18, 6, "#d8d0c0"); c.stroke_rect(mx - 9, base - 180, 18, 6)
		c.begin_path(); c.move_to(mx - 7, base - 240); c.line_to(mx, base - 275); c.line_to(mx + 7, base - 240); c.close_path(); c.fill("#8797a8"); c.stroke()
	c.fill_rect(x - 92, base - 120, 184, 120, "#ece6d6"); c.stroke_rect(x - 92, base - 120, 184, 120)
	c.set_fill("#8797a8")
	for sx in [-62, 62]:
		c.begin_path(); c.arc(x + sx, base - 120, 28, PI, 0); c.close_path(); c.fill(); c.stroke()
	c.begin_path(); c.arc(x, base - 120, 58, PI, 0); c.close_path(); c.fill(); c.stroke()
	c.set_stroke("#d4ac0d"); c.lw = 2.5; c.ln(x, base - 178, x, base - 196)
	c.set_fill("#4a5a6a")
	for i in 6:
		c.rr(x - 80 + i * 29, base - 100, 12, 24, 6); c.fill()

func draw_laundry(l: Dictionary) -> void:
	var x: float = l.x
	var b := GROUND_U
	c.set_stroke("#6e4b2a"); c.lw = 4; c.ln(x - 44, b, x - 44, b - 66); c.ln(x + 44, b, x + 44, b - 66)
	c.set_stroke("#ddd"); c.lw = 1.5; c.begin_path(); c.move_to(x - 44, b - 64); c.quad_to(x, b - 54, x + 44, b - 64); c.stroke()
	var sw := sin(T() * 3 + x) * .15
	c.set_stroke(OL); c.lw = 1.5
	c.save(); c.translate(x - 26, b - 60); c.rotate(sw); c.fill_rect(-9, 0, 18, 20, "#5dade2"); c.stroke_rect(-9, 0, 18, 20); c.restore()
	if not l.taken:
		c.save(); c.translate(x, b - 58); c.rotate(-sw); c.ell(-6, 12, 6, 12, "#ff8cc6"); c.stroke(); c.ell(6, 12, 6, 12, "#ff8cc6"); c.stroke(); c.fill_rect(-11, 0, 22, 5, "#ff8cc6"); c.stroke_rect(-11, 0, 22, 5)
		c.set_fill("#fff"); c.circ(-6, 10, 1.5); c.circ(6, 15, 1.5); c.circ(-4, 18, 1.5); c.restore()
	c.save(); c.translate(x + 26, b - 60); c.rotate(sw * 1.3); c.fill_rect(-7, 0, 14, 24, "#fff"); c.stroke_rect(-7, 0, 14, 24); c.fill_rect(-7, 16, 14, 3, "#e74c3c"); c.restore()

func draw_ferry(f: Dictionary) -> void:
	var x: float = f.x
	var lodos: bool = g.WX == "lodos"
	var b := WATER_Y + sin(T() * 2 + x) * (7.0 if lodos else 2.0)
	c.save()
	if lodos:
		c.translate(x, b); c.rotate(sin(T() * 2.2 + x) * .07); c.translate(-x, -b)
	c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.move_to(x - 112, b - 28); c.line_to(x + 112, b - 28); c.line_to(x + 96, b + 8); c.line_to(x - 96, b + 8); c.close_path(); c.fill("#1d1d1d"); c.stroke()
	c.fill_rect(x - 108, b - 46, 216, 20, "#f4f4f4"); c.stroke_rect(x - 108, b - 46, 216, 20)
	c.fill_rect(x - 80, b - 62, 150, 16, "#e9e9e9"); c.stroke_rect(x - 80, b - 62, 150, 16)
	c.set_fill("#3a6ea5")
	for i in 9: c.fill_rect(x - 100 + i * 23, b - 42, 12, 10)
	c.fill_rect(x + 8, b - 92, 22, 30, "#f4f4f4"); c.stroke_rect(x + 8, b - 92, 22, 30); c.fill_rect(x + 8, b - 92, 22, 8, "#1d1d1d")
	c.txt("BOĞAZ-1", x - 40, b - 12, 11, "#fff", "center", null)
	c.circ(x - 60, b - 55, 6, "#f1c27d"); c.stroke(); c.fill_rect(x - 66, b - 64, 12, 5, "#1b2540")
	f.cap.x = x - 60; f.cap.y = b - 55
	c.restore()

func draw_wind(w: Dictionary, cam: float) -> void:
	var x0: float = w.x - cam
	c.save(); c.alpha = .2
	c.fill_rect(x0, 0, w.w, WATER_Y, "#fff3b0" if w.k == "up" else ("#8fa6c2" if w.k == "down" else "#d0e6ff"))
	c.alpha = .6; c.set_stroke("#fff"); c.lw = 2.5
	for i in 10:
		var sx: float = x0 + (i + .5) * w.w / 10
		var ph: float = fmod(T() * 180 + i * 97, WATER_Y)
		if w.k == "up":
			var y := WATER_Y - ph
			c.begin_path(); c.move_to(sx, y); c.quad_to(sx + 8, y - 15, sx, y - 30); c.stroke()
		elif w.k == "down":
			var y := ph
			c.begin_path(); c.move_to(sx, y); c.quad_to(sx - 8, y + 15, sx, y + 30); c.stroke()
		else:
			var y := 30.0 + i * 44
			var xx: float = x0 + w.w - fmod(T() * 220 + i * 61, w.w)
			c.begin_path(); c.move_to(xx, y); c.quad_to(xx - 15, y - 8, xx - 35, y); c.stroke()
	c.alpha = 1
	c.txt("↑ SICAK HAVA ↑" if w.k == "up" else ("↓ POYRAZ ↓" if w.k == "down" else "← KARŞI RÜZGÂR"), x0 + w.w / 2, 64, 16, "#fff")
	c.restore()

func draw_gull(x: float, y: float, f: float, t: float, spin: float) -> void:
	c.save(); c.translate(x, y); c.scale(f, 1)
	if spin: c.rotate(spin)
	var w := sin(t * 14)
	c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.move_to(-2, -3); c.quad_to(-10, -18 - w * 12, -26, -12 - w * 20); c.quad_to(-12, -4, -2, 2); c.fill("#b9c3cc"); c.stroke()
	c.begin_path(); c.move_to(-14, 0); c.line_to(-26, -5); c.line_to(-26, 5); c.close_path(); c.fill("#9aa5ae"); c.stroke()
	c.ell(0, 0, 16, 9, "#fff"); c.stroke(); c.circ(12, -6, 7.5, "#fff"); c.stroke()
	c.begin_path(); c.move_to(18, -8); c.line_to(30, -4); c.line_to(18, -2); c.close_path(); c.fill("#f39c12"); c.stroke()
	c.circ(14, -8, 2, "#111"); c.lw = 2.2; c.ln(10, -13, 17, -10)
	c.lw = 2; c.begin_path(); c.move_to(2, -2); c.quad_to(-4, -16 + w * 10, -20, -10 + w * 22); c.quad_to(-8, 0, 2, 3); c.fill("#dfe5ea"); c.stroke()
	c.restore()

func draw_fish(x: float, y: float, rot: float) -> void:
	c.save(); c.translate(x, y); c.rotate(rot); c.set_stroke(OL); c.lw = 2
	c.begin_path(); c.move_to(-14, 0); c.line_to(-27, -10); c.line_to(-27, 10); c.close_path(); c.fill("#ff9f43"); c.stroke()
	c.ell(0, 0, 17, 10, "#ffb35c"); c.stroke(); c.fill_rect(3, -7, 11, 5, "#111"); c.lw = 1.5; c.ln(3, -5, -2, -6)
	c.ell(12, 3, 5, 1.8, "#3b2a1e"); c.restore()

func draw_carpet(x: float, y: float) -> void:
	c.save(); c.translate(x, y)
	draw_person(-2, -2, {"s": .55, "f": -1.0, "body": "#1e8449", "sleeve": "#196f3d", "hat": "fes", "must": "#222", "mood": "smile", "arm": -1.6 + sin(T() * 6) * .3})
	c.set_stroke(OL); c.lw = 2; c.begin_path()
	for i in 11:
		var xx := -48 + i * 9.6
		var yy := sin(T() * 8 + i * .7) * 4
		if i: c.line_to(xx, yy)
		else: c.move_to(xx, yy)
	for i in range(10, -1, -1):
		c.line_to(-48 + i * 9.6, sin(T() * 8 + i * .7) * 4 + 9)
	c.close_path(); c.fill("#b03a2e"); c.stroke()
	c.set_stroke("#f1c40f"); c.lw = 2; c.begin_path()
	for i in 11:
		var xx := -48 + i * 9.6
		var yy := sin(T() * 8 + i * .7) * 4 + 4.5
		if i: c.line_to(xx, yy)
		else: c.move_to(xx, yy)
	c.stroke()
	c.lw = 1.5
	for sx in [-48, 48]:
		var yy := sin(T() * 8 + (7 if sx > 0 else 0)) * 4
		for k in 4: c.ln(sx, yy + k * 3, sx + (6 if sx > 0 else -6), yy + k * 3 + 1)
	c.restore()

func draw_simit(x: float, y: float, s := 1.0) -> void:
	c.save(); c.translate(x, y); c.scale(s, s)
	c.set_stroke(OL); c.lw = 12; c.begin_path(); c.arc(0, 0, 11, 0, TAU_); c.close_path(); c.stroke()
	c.set_stroke("#c47a35"); c.lw = 9; c.stroke()
	c.set_fill("#f7e7b4")
	for i in 10:
		var a := i * TAU_ / 10
		c.circ(cos(a) * 11, sin(a) * 11, 1.1)
	c.restore()

func draw_cay(x: float, y: float, s := 1.0) -> void:
	c.save(); c.translate(x, y); c.scale(s, s); c.set_stroke(OL); c.lw = 2
	c.ell(0, 13, 14, 4, "#e74c3c"); c.stroke()
	c.begin_path(); c.move_to(-8, -14); c.quad_to(-3, -2, -6, 4); c.quad_to(-7, 12, 0, 12); c.quad_to(7, 12, 6, 4); c.quad_to(3, -2, 8, -14); c.close_path(); c.fill("rgba(255,255,255,.65)"); c.stroke()
	c.begin_path(); c.move_to(-6, -8); c.quad_to(-2, -1, -5, 4); c.quad_to(-6, 10, 0, 10); c.quad_to(6, 10, 5, 4); c.quad_to(2, -1, 6, -8); c.close_path(); c.fill("#b8321f")
	c.restore()

func draw_rival(o: Dictionary, has_bubble: bool) -> void:
	var x: float = o.x
	var y: float = o.y
	var fail: bool = o.st == "fail"
	c.save(); c.translate(x, y); c.rotate(sin(o.rot) * .6 if fail else 0.0); c.translate(-x, -y); c.set_stroke(OL); c.lw = 2
	var man := {"s": .55, "f": 1.0, "body": "#2980b9" if o.k == "fici" else ("#7f8c8d" if o.k == "kazan" else "#d35400"), "sleeve": "#444",
		"hat": "takke" if o.k == "kazan" else ("fes" if o.k == "fici" else "cap"), "capc": "#27ae60", "must": "#222", "mood": "scared" if fail else "smile", "shout": .6 if has_bubble else 0.0}
	if o.k == "fici":
		man["arm"] = -2.6 + sin(T() * 16) * .5
		draw_person(x, y + 6, man)
		c.save(); c.translate(x - 4, y - 12); draw_wing(.2 + sin(T() * 16) * .6, "#bdc3c7", 30); c.restore()
		c.set_stroke(OL); c.lw = 2; c.rr(x - 15, y - 18, 30, 32, 8); c.fill("#8e5b2e"); c.stroke(); c.set_stroke("#4a3020"); c.lw = 2.5; c.ln(x - 15, y - 10, x + 15, y - 10); c.ln(x - 15, y + 6, x + 15, y + 6)
		c.txt("TURŞU", x, y - 1, 8, "#fff", "center", null)
	elif o.k == "ucurtma":
		var ko: float = o.ft if fail else 0.0
		var kx := x - 30 - ko * 120
		var ky := y - 95 - ko * 160
		if ko < 2.5:
			c.save(); c.translate(kx, ky); c.rotate(sin(T() * 2) * .15 + ko * 4); c.set_stroke(OL); c.lw = 2
			c.begin_path(); c.move_to(0, -38); c.line_to(30, 0); c.line_to(0, 46); c.line_to(-30, 0); c.close_path(); c.fill("#e74c3c"); c.stroke()
			c.begin_path(); c.move_to(0, -38); c.line_to(30, 0); c.line_to(0, 0); c.close_path(); c.fill("#f1c40f")
			c.begin_path(); c.move_to(0, 46); c.line_to(-30, 0); c.line_to(0, 0); c.close_path(); c.fill("#f1c40f")
			c.lw = 1.5; c.ln(0, -38, 0, 46); c.ln(-30, 0, 30, 0)
			var cols := ["#e74c3c", "#3498db", "#f1c40f", "#2ecc71"]
			for i in 4:
				c.set_stroke(cols[i]); c.ln(sin(T() * 4 + i) * 6, 46 + i * 9, sin(T() * 4 + i + 1) * 6, 55 + i * 9)
			c.restore()
		if not fail:
			c.set_stroke("#555"); c.lw = 1; c.ln(kx, ky + 46, x + 2, y - 2)
		man["arm"] = -3.0
		draw_person(x, y + 30, man)
	else:
		man["arm"] = -2.3 + sin(T() * 6) * .3
		man["item"] = "kepce"
		draw_person(x, y + 4, man)
		c.set_stroke(OL); c.lw = 2
		c.begin_path(); c.move_to(x - 22, y - 16); c.line_to(x + 22, y - 16); c.quad_to(x + 24, y + 16, x, y + 18); c.quad_to(x - 24, y + 16, x - 22, y - 16); c.close_path(); c.fill("#2c2c2c"); c.stroke()
		c.ell(x, y - 16, 23, 5, "#444"); c.stroke(); c.set_stroke("#555"); c.lw = 3; c.ln(x - 22, y - 10, x - 29, y - 4); c.ln(x + 22, y - 10, x + 29, y - 4)
	c.restore()
	if not fail:
		c.txt(D.RIV[o.k].n, x, y - (150 if o.k == "ucurtma" else 58), 11, "#fff")

# ---------------------------------------------------------------- arayüz parçaları
func bar(x: float, y: float, w: float, h: float, v: float, col, label := "") -> void:
	c.rr(x, y, w, h, h / 2); c.fill("rgba(0,0,0,.45)")
	if v > 0:
		c.rr(x + 2, y + 2, (w - 4) * clamp(v, 0, 1), h - 4, (h - 4) / 2); c.fill(col)
	c.rr(x, y, w, h, h / 2); c.set_stroke(OL); c.lw = 2; c.stroke()
	if label != "":
		c.txt(label, x + w / 2, y + h / 2 + 1, 12, "#fff", "center", OL, 3)
