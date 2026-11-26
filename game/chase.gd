extends "res://game/main.gd"
## İniş, kovalamaca, saray ve son ekranı (web sürümündeki aynı bölümlerin aktarımı).
## Test: --scene=landing|chase|saray   --t=saniye (kovalamacada zamanı ileri sar)

const SURV := 60.0
const AR := {"x0": 24.0, "x1": 936.0, "y0": 140.0, "y1": 514.0}
const ZN := ["MEYDAN", "ÇARŞI", "İSKELE"]
const ARENA_SC := 1.5
const ZOBST := [
	[{"x": 480, "y": 330, "r": 48, "k": "cesme"}, {"x": 190, "y": 420, "r": 20, "k": "barrel"}, {"x": 775, "y": 240, "r": 20, "k": "barrel"}, {"x": 845, "y": 452, "r": 16, "k": "tree"}, {"x": 118, "y": 212, "r": 30, "k": "kahve"}],
	[{"x": 300, "y": 265, "r": 40, "k": "tezgah", "c": 0}, {"x": 660, "y": 255, "r": 40, "k": "tezgah", "c": 1}, {"x": 480, "y": 430, "r": 40, "k": "tezgah", "c": 2}, {"x": 140, "y": 440, "r": 15, "k": "kufe"}, {"x": 835, "y": 410, "r": 15, "k": "kufe"}, {"x": 850, "y": 200, "r": 18, "k": "barrel"}],
	[{"x": 260, "y": 310, "r": 44, "k": "kayik"}, {"x": 700, "y": 390, "r": 44, "k": "kayik"}, {"x": 480, "y": 215, "r": 13, "k": "baba"}, {"x": 130, "y": 470, "r": 13, "k": "baba"}, {"x": 860, "y": 250, "r": 17, "k": "halat"}, {"x": 540, "y": 490, "r": 18, "k": "barrel"}]]
const PERKS := [
	{"id": "yurek", "ic": "❤️", "n": "Aslan Yürek", "d": "Canların dolar ve +1 kavuk kazanırsın"},
	{"id": "pabuc", "ic": "👟", "n": "Kanatlı Pabuç", "d": "Koşu hızın %20 artar"},
	{"id": "ruzgar", "ic": "💨", "n": "Rüzgâr Gülü", "d": "Kaçış hamlesi iki kat sık dolar"},
	{"id": "kalkan", "ic": "🛡️", "n": "Bakır Sini", "d": "Sonraki 2 darbe siniye çarpıp seker"},
	{"id": "lokum", "ic": "🍬", "n": "Lokum Kesesi", "d": "Lokum saçarsın; mahalleli %20 yavaşlar"},
	{"id": "tuy", "ic": "🪶", "n": "Sihirli Tüy", "d": "Bölüme 8 saniye uçarak başlarsın"}]
const LOSE_T := {"dayak": "DAYAK YEDİN!", "terlik": "TERLİKLENDİN!", "karpuz": "KARPUZLANDIN!", "boss": "MÜHÜRLENDİN!", "havlu": "HAVLULANDIN!"}

var C := {}
var ARENA := {}
var OBST: Array = []
var arenas := {}
var SR := {}
var E := {}

## arka planı bir kez dokuya çizen yardımcı düğüm
class Baker extends Node2D:
	var fn: Callable
	func _draw() -> void:
		fn.call(self)

func _ready() -> void:
	super._ready()
	var sc: String = args.get("scene", "")
	if sc == "landing":
		state = "flight"; init_world(); reset_stats(); P.onTower = false; P.x = SHORE_X + 60; P.y = GROUND_U - 30; P.vx = 300.0; P.vy = 120.0; cam = P.x - 260; start_landing()
	elif sc == "chase" or sc == "saray":
		init_world(); reset_stats(); stats.dist = R.m; stats.landed = true
		start_chase()
		if args.has("t"):
			C.t = float(args["t"])
			if C.t >= 40: set_zone(2)
			elif C.t >= 20: set_zone(1)
		if sc == "saray":
			start_saray()

# ---------------------------------------------------------------- yardımcılar
func dst(a: Dictionary, b: Dictionary) -> float:
	return Vector2(a.x - b.x, a.y - b.y).length()

func banner(text: String, sub: String) -> void:
	C.banner = {"text": text, "sub": sub, "t": 0.0}
	Snd.play("pop"); Snd.speak("anlatici", text, 2)

func news(t: String) -> void:
	if C.news.size() < 4: C.news.append(t)

func in_ell(e: Dictionary, h: Dictionary, r: float) -> bool:
	return pow((e.x - h.x) / r, 2) + pow((e.y - h.y) / (r * .55), 2) < 1

func bounds(e: Dictionary) -> void:
	e.x = clamp(e.x, AR.x0, AR.x1); e.y = clamp(e.y, AR.y0, AR.y1)

func obst_push(e: Dictionary) -> void:
	for o in OBST:
		var dx: float = e.x - o.x
		var dy: float = (e.y - o.y) * 1.6
		var d := sqrt(dx * dx + dy * dy)
		var m: float = o.r + e.r * .7
		if d < m and d > .01:
			var k := (m - d) / d
			e.x += dx * k; e.y += dy * k / 1.6

func obst_near(x: float, y: float, pad: float) -> bool:
	for o in OBST:
		if Vector2(o.x - x, (o.y - y) * 1.6).length() < o.r + pad:
			return true
	return false

# ---------------------------------------------------------------- iniş
func start_landing() -> void:
	state = "landing"
	var hard: bool = P.vy > 170 or P.rot > .5
	LD = {"t": 0.0, "ev": {}, "hard": hard, "slide": true, "salvarFly": null, "yeller": null, "exclaim": 0}
	P.y = GROUND_U - 30; P.vy = 0.0; P.vx = clamp(P.vx, 240.0, 330.0); P.rot = 1.3 if hard else 0.0; P.hitT = 0.0
	Snd.play("thud"); shake = 14.0; slow = .15; pop_text(P.x, P.y - 40, "GÜÜÜM!" if hard else "TAK!", "#ffe066", 42); dust(P.x, GROUND_U, 16)
	stats.landed = true; stats.hard = hard; stats.dist = R.m; stats.score += 1000 + (0 if hard else 400)
	Snd.music_stop()
	if D.save_data.route + 1 < D.ROUTES.size() and D.save_data.unl < D.save_data.route + 2:
		D.save_data.unl = D.save_data.route + 2; D.save(); toast("🔓 YENİ ROTA: %s" % D.ROUTES[D.save_data.route + 1].n)
	var best = null
	for s in shore:
		if best == null or abs(s.x - P.x) < abs(best.x - P.x): best = s
	for s in shore:
		if s.type == "teyze" and not is_same(s, best): s.type = best.type
	best.type = "teyze"
	LD.yeller = best

func upd_landing(dt: float) -> void:
	LD.t += dt
	var t: float = LD.t
	if LD.slide:
		P.vx -= 330 * dt
		if P.vx <= 0:
			P.vx = 0.0; LD.slide = false
		P.x += P.vx * dt
		if randf() < .6: dust(P.x, GROUND_U, 1)
		if not P.salvar:
			for l in laundry:
				if not l.taken and abs(P.x - l.x) < 30:
					l.taken = 1; P.salvar = true; Snd.play("flap"); pop_text(P.x, P.y - 60, "ŞLAP!", "#ff9ff3", 30)
	elif P.rot > 0:
		P.rot = max(0.0, P.rot - dt * 1.5)
	if t > 1.3 and not P.salvar and LD.salvarFly == null:
		var n = null
		for l in laundry:
			if not l.taken and (n == null or abs(l.x - P.x) < abs(n.x - P.x)): n = l
		if n != null:
			n.taken = 1; LD.salvarFly = {"x": n.x, "y": GROUND_U - 50, "t": 0.0}; Snd.play("throw")
	if LD.salvarFly != null:
		LD.salvarFly.t += dt * 1.6
		if LD.salvarFly.t >= 1:
			P.salvar = true; LD.salvarFly = null; pop_text(P.x, P.y - 60, "ŞLAP!", "#ff9ff3", 30); Snd.play("flap")
	for s in shore:
		if t < 6.2: s.f = -1.0 if P.x < s.x else 1.0
	once(LD, 1.0, func(): say(P, "Yüz üstü ama... İNDİM!" if LD.hard else "İNDİM! TARİH YAZDIM!", 1.8, -58, 3); Snd.play("fanfare"))
	once(LD, 2.4, func():
		Snd.play("cricket")
		for s in shore:
			if abs(s.x - P.x) < 520: say(s, "...", 1.3, -75))
	once(LD, 3.7, func(): Snd.play("pop"); Snd.play("gasp"); LD.exclaim = 1)
	once(LD, 4.2, func(): Snd.play("yellHigh"); say(LD.yeller, "O BENİM ŞALVARIM!!!", 2, -78, 3); shake = 6.0)
	once(LD, 5.0, func():
		Snd.play("yell")
		var others := shore.filter(func(s): return not is_same(s, LD.yeller) and abs(s.x - P.x) < 520)
		if others.size() > 0: say(others[0], "CİN BU, CİN!", 1.6, -75, 3)
		if others.size() > 1: say(others[1], "TUTUN ŞUNU!", 1.6, -75, 1))
	once(LD, 5.9, func(): say(P, "Eee... bilim?", 1.2, -58, 3))
	if t > 6.2:
		for s in shore:
			s.x += s.f * 230 * dt; s.ph += dt * 14
	if t > 1.5 and t < 6.2 and (hit(["Space", "Enter"]) or ptr.tap):
		LD.t = 6.2
		if not P.salvar: P.salvar = true
		LD.salvarFly = null
	cam = lerp(cam, P.x - 420, min(1.0, dt * 3))
	if t > 7.1: start_chase()

func draw_landing_ui() -> void:
	if LD.t > 1.5 and LD.t < 6.2: c.txt("SPACE: geç", W - 14, H - 16, 13, "#fff", "right", OL, 3)
	if LD.t > 6.2:
		var k: float = min(1.0, (LD.t - 6.2) * 4)
		c.save(); c.translate(W / 2, H / 2 - 40); c.scale(k * 1.2, k * 1.2); c.rotate(sin(T * 30) * .05); c.txt("KAÇ!!!", 0, 0, 110, "#ff4757", "center", OL, 12); c.restore()

func draw_shore_people() -> void:
	for s in shore:
		var o: Dictionary = D.VT[s.type].duplicate()
		var arm := .2
		var mood: String = s.get("mood", "normal")
		var run := 0.0
		var shout := 0.0
		if state == "landing":
			if LD.t > 6.2:
				run = 1.0; arm = -2.4 + sin(T * 12 + s.ph) * .4; mood = "angry"; shout = .6
			elif LD.t > 3.7:
				arm = -2.6 + sin(T * 20 + s.ph) * .15; mood = "angry"
			elif LD.t > 2.4:
				mood = "surprised"
		elif P.x > SHORE_X - 900 and state == "flight":
			mood = "surprised"; arm = -2.3; s.f = -1.0 if P.x < s.x else 1.0
		o.merge({"s": .8 * float(o.get("s", 1.0)), "f": s.f, "ph": s.ph, "run": run, "arm": arm, "mood": mood, "shout": .7 if has_bubble(s) else shout}, true)
		art.draw_person(s.x, GROUND_U, o)
		if state == "landing" and LD.exclaim and LD.t < 4.8:
			var k: float = min(1.0, (LD.t - 3.7) * 6)
			c.txt("!", s.x, GROUND_U - 92 - abs(sin(T * 10)) * 6, 34 * k, "#ff4757")

func draw_flight_extra() -> void:
	if state == "landing" and LD.salvarFly != null:
		var s: Dictionary = LD.salvarFly
		var k: float = s.t
		var x: float = lerp(float(s.x), float(P.x), k)
		var y: float = lerp(float(s.y), float(P.y) - 50.0, k) - sin(k * PI) * 80
		c.save(); c.translate(x, y); c.rotate(k * TAU_ * 2); c.ell(-6, 8, 6, 12, "#ff8cc6"); c.ell(6, 8, 6, 12, "#ff8cc6"); c.restore()

# ---------------------------------------------------------------- arena (arka plan)
func set_zone(z: int) -> void:
	C.zone = z
	var key := "%d_%d" % [D.save_data.route, z]
	if not arenas.has(key):
		for k in arenas.keys():
			if not k.begins_with("%d_" % D.save_data.route):
				arenas[k].vp.queue_free(); arenas.erase(k)
		arenas[key] = build_arena(z)
	ARENA = arenas[key]
	OBST = []
	for o in ZOBST[z]:
		OBST.append(o.duplicate())

func gen_arena(z: int) -> Dictionary:
	var L := {"z": z, "doors": [], "wins": [], "houses": [], "cob": [], "lines": [], "boats": [], "planks": []}
	if z == 2:
		for i in 22:
			var x := randf_range(0, W)
			L.lines.append([x, randf_range(70, 120), randf_range(12, 26)])
		for bx in [150, 520, 800]:
			L.boats.append([bx, choice(["#c0392b", "#2e86c1", "#f1c40f"])])
		var y := 136.0
		while y < H:
			var xs: Array = []
			var x := randf_range(0, 120)
			while x < W:
				xs.append(x); x += randf_range(90, 170)
			L.planks.append([y, choice(["#a47148", "#9a6a40", "#b07a4f", "#a8744a"]), xs]); y += 18
	else:
		var row := 0
		var y := 130.0
		while y < H + 10:
			var x := (row % 2) * 11.0 - 11
			while x < W + 22:
				L.cob.append([x + randf_range(-1, 1), y, choice(R.gr)]); x += 22
			y += 13; row += 1
		var x := -10.0
		while x < W:
			var w := randf_range(130, 175)
			var h := randf_range(80, 104)
			var hs := {"x": x, "w": w, "h": h, "c1": choice(R.hs), "cs": choice([["#e74c3c", "#fff"], ["#27ae60", "#fff"], ["#2980b9", "#f1c40f"], ["#8e44ad", "#fff"]]), "dx": x + w * randf_range(.3, .7)}
			L.houses.append(hs)
			var n := 3 if w > 150 else 2
			for i in n:
				var wx := x + (w / n) * (i + .5) - 11
				var wy := 130 - h + 8
				var wh := h * .5 - 16
				L.wins.append({"x": wx + 11, "y": wy + wh})
			if hs.dx > 40 and hs.dx < W - 40: L.doors.append({"x": hs.dx, "y": 144.0})
			x += w + 12
	return L

func build_arena(z: int) -> Dictionary:
	var L := gen_arena(z)
	var vp := SubViewport.new()
	vp.size = Vector2i(int(W * ARENA_SC), int(H * ARENA_SC))
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var b := Baker.new()
	b.scale = Vector2(ARENA_SC, ARENA_SC)
	b.fn = func(node): draw_arena(Ctx.new(node), L)
	vp.add_child(b)
	add_child(vp)
	L["vp"] = vp
	L["tex"] = vp.get_texture()
	return L

func draw_arena(x2: Ctx, L: Dictionary) -> void:
	var z: int = L.z
	x2.vgrad_rect(0, 0, W, 140, [[0, R.sky[0]], [130.0 / 140.0, R.sky[1]], [1, R.sky[1]]])
	if z == 2:
		x2.begin_path(); x2.move_to(0, 64)
		var x := 0.0
		while x <= W:
			x2.line_to(x, 56 + sin(x * .02) * 5); x += 30
		x2.line_to(W, 66); x2.close_path(); x2.fill(R.sk[1])
		for i in 6:
			var dx := 60.0 + i * 170
			x2.begin_path(); x2.arc(dx, 56, 10, PI, 0); x2.fill(); x2.fill_rect(dx + 16, 32, 3, 26)
		x2.vgrad_rect(0, 62, W, 66, [[0, R.wa[2]], [1, R.wa[0]]])
		x2.set_stroke("rgba(255,255,255,.4)"); x2.lw = 2
		for l in L.lines: x2.ln(l[0], l[1], l[0] + l[2], l[1])
		for bt in L.boats:
			var bx: float = bt[0]
			x2.set_stroke(OL); x2.lw = 2
			x2.begin_path(); x2.move_to(bx - 34, 96); x2.line_to(bx + 34, 96); x2.line_to(bx + 24, 110); x2.line_to(bx - 24, 110); x2.close_path(); x2.fill(bt[1]); x2.stroke()
			x2.set_stroke("#5d4037"); x2.lw = 3; x2.ln(bx, 96, bx, 62)
			x2.set_stroke(OL); x2.lw = 1.5; x2.begin_path(); x2.move_to(bx + 2, 64); x2.line_to(bx + 26, 90); x2.line_to(bx + 2, 90); x2.close_path(); x2.fill("#f3ead2"); x2.stroke()
		x2.fill_rect(0, 122, W, 14, "#9e9e9e"); x2.set_stroke("rgba(0,0,0,.3)"); x2.lw = 1
		x = 0.0
		while x < W:
			x2.ln(x, 122, x, 136); x += 40
		for pl in L.planks:
			var y: float = pl[0]
			x2.fill_rect(0, y, W, 18, pl[1]); x2.set_stroke("rgba(60,35,15,.5)"); x2.lw = 1.5; x2.ln(0, y, W, y)
			for px in pl[2]: x2.ln(px, y, px, y + 18)
	else:
		x2.fill_rect(0, 124, W, H - 124, R.gr[0])
		x2.set_stroke("rgba(90,60,30,.22)"); x2.lw = 1
		for cb in L.cob:
			x2.ell(cb[0], cb[1], 9.5, 5.2, cb[2]); x2.stroke()
		if z == 1:
			x2.fill_rect(0, 300, W, 70, "rgba(120,40,40,.18)"); x2.set_stroke("rgba(241,196,15,.35)"); x2.lw = 3; x2.ln(0, 304, W, 304); x2.ln(0, 366, W, 366)
		for hs in L.houses:
			var x: float = hs.x
			var w: float = hs.w
			var h: float = hs.h
			var base := 130.0
			x2.set_stroke(OL); x2.lw = 2
			x2.fill_rect(x, base - h * .5, w, h * .5, "#e6dccb"); x2.stroke_rect(x, base - h * .5, w, h * .5)
			x2.fill_rect(x - 5, base - h, w + 10, h * .5 + 2, hs.c1); x2.stroke_rect(x - 5, base - h, w + 10, h * .5 + 2)
			x2.set_stroke("rgba(0,0,0,.12)"); x2.lw = 1
			var yy := base - h + 6
			while yy < base - h * .5:
				x2.ln(x - 5, yy, x + w + 5, yy); yy += 6
			x2.set_stroke(OL); x2.lw = 2
			x2.begin_path(); x2.move_to(x - 14, base - h); x2.line_to(x + w + 14, base - h); x2.line_to(x + w - 6, base - h - 18); x2.line_to(x + 6, base - h - 18); x2.close_path(); x2.fill(R.roof); x2.stroke()
			if z == 1:
				var cs: Array = hs.cs
				var ay := base - h * .5
				for i in int(ceil((w + 10) / 14)):
					x2.begin_path(); x2.move_to(x - 5 + i * 14, ay); x2.line_to(x + 9 + i * 14, ay); x2.line_to(x + 9 + i * 14, ay + 12); x2.quad_to(x + 2 + i * 14, ay + 17, x - 5 + i * 14, ay + 12); x2.close_path(); x2.fill(cs[i % 2])
				x2.set_stroke(OL); x2.lw = 1.5; x2.ln(x - 5, ay, x + w + 5, ay); x2.lw = 2
			var n := 3 if w > 150 else 2
			for i in n:
				var wx := x + (w / n) * (i + .5) - 11
				var wy := base - h + 8
				var wh := h * .5 - 16
				x2.fill_rect(wx, wy, 22, wh, "#f4d03f" if R.get("night", 0) else "#3a2a20"); x2.set_stroke(OL); x2.stroke_rect(wx, wy, 22, wh)
				x2.set_stroke("#c8a26a"); x2.lw = 1
				var k := 4.0
				while k < 22:
					x2.ln(wx + k, wy, wx + k, wy + wh); k += 6
				k = 4.0
				while k < wh:
					x2.ln(wx, wy + k, wx + 22, wy + k); k += 6
				x2.set_stroke(OL); x2.lw = 2
			var dx: float = hs.dx
			x2.begin_path(); x2.move_to(dx - 12, base); x2.line_to(dx - 12, base - 26); x2.arc(dx, base - 26, 12, PI, 0); x2.line_to(dx + 12, base); x2.close_path(); x2.fill("#6b4226"); x2.stroke()
	x2.vgrad_rect(0, 130, W, 22, [[0, "rgba(0,0,0,.25)"], [1, "rgba(0,0,0,0)"]])
	x2.fill_rect(0, 524, W, 16, "#a8977c"); x2.fill_rect(0, 520, W, 6, "#c4b394")
	if R.get("night", 0):
		x2.fill_rect(0, 0, W, H, "rgba(10,15,50,.36)")
		var ds: Array = L.doors if L.doors.size() > 0 else [{"x": 150, "y": 150}, {"x": 480, "y": 150}, {"x": 810, "y": 150}]
		for d in ds:
			for i in 10:
				x2.circ(d.x, d.y - 20, 95.0 * (1.0 - i / 10.0), Color(1, .82, .47, .045))
		for s in STARS:
			if s.y < 60: x2.circ(s.x, s.y * .9, s.r * .8, "rgba(255,255,255,.8)")

# ---------------------------------------------------------------- engeller
func draw_obst(o: Dictionary) -> void:
	var x: float = o.x
	var y: float = o.y
	c.set_stroke(OL); c.lw = 2
	match o.k:
		"cesme":
			c.fill_rect(x - 62, y - 10, 124, 12, "#bfb6a6"); c.stroke_rect(x - 62, y - 10, 124, 12)
			c.fill_rect(x - 52, y - 78, 104, 68, "#ece6d8"); c.stroke_rect(x - 52, y - 78, 104, 68)
			c.set_fill("#2e86c1")
			for i in 4: c.fill_rect(x - 46 + i * 26, y - 72, 14, 8)
			c.begin_path(); c.move_to(x - 16, y - 12); c.line_to(x - 16, y - 44); c.arc(x, y - 44, 16, PI, 0); c.line_to(x + 16, y - 12); c.close_path(); c.fill("#c9bfae"); c.stroke()
			c.fill_rect(x - 3, y - 38, 6, 8, "#d4ac0d"); c.set_stroke("rgba(120,190,240,.9)"); c.lw = 3; c.ln(x, y - 30, x, y - 16 + sin(T * 20))
			c.set_stroke(OL); c.lw = 2; c.fill_rect(x - 30, y - 18, 60, 10, "#b5ab99"); c.stroke_rect(x - 30, y - 18, 60, 10)
			c.begin_path(); c.move_to(x - 66, y - 78); c.line_to(x + 66, y - 78); c.line_to(x + 54, y - 90); c.line_to(x - 54, y - 90); c.close_path(); c.fill("#d8d0c0"); c.stroke()
			c.begin_path(); c.arc(x, y - 90, 30, PI, 0); c.close_path(); c.fill("#8fa1b3"); c.stroke()
			c.set_stroke("#d4ac0d"); c.lw = 2.5; c.ln(x, y - 120, x, y - 132); c.circ(x, y - 134, 3, "#d4ac0d")
		"barrel":
			art.shadow(x, y, 18); c.rr(x - 16, y - 34, 32, 34, 6); c.fill("#8e5b2e"); c.stroke(); c.set_stroke("#4a3020"); c.lw = 2.5; c.ln(x - 16, y - 26, x + 16, y - 26); c.ln(x - 16, y - 8, x + 16, y - 8)
			c.ell(x, y - 34, 16, 5, "#a87244"); c.set_stroke(OL); c.lw = 2; c.stroke()
		"kahve":
			art.shadow(x, y, 32); c.fill_rect(x - 52, y - 80, 4, 80, "#6e4b2a"); c.fill_rect(x - 80, y - 96, 64, 18, "#8d5a2b"); c.stroke_rect(x - 80, y - 96, 64, 18); c.txt("KAHVEHANE", x - 48, y - 87, 9, "#ffe066", "center", null)
			var ch: bool = C.kahveCheer > 0
			art.draw_person(x - 24, y - 4, {"body": "#6d7f3c", "sleeve": "#55632e", "hat": "fes", "must": "#e6e6e6", "beard": "#e6e6e6", "s": .8, "f": 1.0, "arm": (-2.8 + sin(T * 20) * .3) if ch else (-1.3 + sin(T * 3) * .2), "mood": "happy" if ch else "smile", "shout": .6 if (o.has("m1") and has_bubble(o.m1)) else 0.0})
			art.draw_person(x + 26, y - 4, {"body": "#7f6a4d", "sleeve": "#6a573e", "hat": "takke", "must": "#ccc", "s": .8, "f": -1.0, "arm": (-2.8 + sin(T * 22) * .3) if ch else (-1.2 + sin(T * 2.5 + 1) * .2), "mood": "happy" if ch else "smile", "shout": .6 if (o.has("m2") and has_bubble(o.m2)) else 0.0})
			c.set_stroke(OL); c.lw = 2; c.fill_rect(x - 3, y - 24, 6, 24, "#6e4b2a"); c.ell(x, y - 26, 26, 8, "#8d5a2b"); c.stroke(); c.fill_rect(x - 14, y - 33, 28, 10, "#d4ac6e"); c.stroke_rect(x - 14, y - 33, 28, 10)
			c.set_stroke("#5d4037"); c.ln(x, y - 33, x, y - 23)
			for i in 3:
				c.circ(x - 10 + i * 3, y - 28, 1.6, "#fff"); c.circ(x + 5 + i * 3, y - 28, 1.6, "#222")
			art.draw_cay(x - 20, y - 36, .4); art.draw_cay(x + 20, y - 36, .4)
		"tree":
			if R.mid == "korsan":
				art.shadow(x, y, 22); c.set_stroke("#8d6e63"); c.lw = 9; c.begin_path(); c.move_to(x, y); c.quad_to(x + 12, y - 50, x + 4, y - 100); c.stroke(); c.set_stroke(OL); c.lw = 2
				for i in 6:
					var a := -PI / 2 + (i - 2.5) * .55 + sin(T * 2 + i) * .05
					c.begin_path(); c.move_to(x + 4, y - 100); c.quad_to(x + 4 + cos(a) * 30, y - 100 + sin(a) * 30 - 14, x + 4 + cos(a) * 52, y - 100 + sin(a) * 52 + 12); c.quad_to(x + 4 + cos(a) * 26, y - 100 + sin(a) * 26, x + 4, y - 100); c.fill("#27ae60" if i % 2 else "#2ecc71"); c.stroke()
				c.circ(x, y - 96, 5, "#6e4b2a"); c.circ(x + 8, y - 94, 5, "#6e4b2a")
			else:
				art.shadow(x, y, 26); c.fill_rect(x - 7, y - 58, 14, 58, "#6e4b2a"); c.stroke_rect(x - 7, y - 58, 14, 58)
				c.save(); c.alpha = .94
				for e in [[-22, -78, 30, "#4f8a3a"], [20, -82, 32, "#4f8a3a"], [0, -102, 34, "#5fa046"], [-6, -74, 26, "#5fa046"]]:
					c.circ(x + e[0], y + e[1], e[2], e[3]); c.stroke()
				c.restore()
		"tezgah":
			art.shadow(x, y, 40)
			var cs: Array = [["#e74c3c", "#fff"], ["#27ae60", "#fff"], ["#2980b9", "#f1c40f"]][o.c]
			var gd: Array = [["#e67e22", "#f39c12"], ["#8e44ad", "#c0392b"], ["#f1c40f", "#27ae60"]][o.c]
			c.set_stroke("#5d4037"); c.lw = 3; c.ln(x - 46, y, x - 46, y - 94); c.ln(x + 46, y, x + 46, y - 94); c.set_stroke(OL); c.lw = 2
			c.fill_rect(x - 50, y - 34, 100, 22, "#8d5a2b"); c.stroke_rect(x - 50, y - 34, 100, 22); c.fill_rect(x - 46, y - 12, 92, 12, "#6d4422")
			for i in 9:
				c.circ(x - 42 + i * 10.5, y - 38 - (i % 2) * 4, 6, gd[i % 2]); c.set_stroke("rgba(0,0,0,.35)"); c.lw = 1; c.stroke()
			for i in 8:
				c.begin_path(); c.move_to(x - 54 + i * 13.5, y - 98); c.line_to(x - 54 + (i + 1) * 13.5, y - 98); c.line_to(x - 54 + (i + 1) * 13.5, y - 86); c.quad_to(x - 54 + (i + .5) * 13.5, y - 80, x - 54 + i * 13.5, y - 86); c.close_path(); c.fill(cs[i % 2])
			c.set_stroke(OL); c.lw = 2; c.fill_rect(x - 56, y - 104, 112, 7, cs[0]); c.stroke_rect(x - 56, y - 104, 112, 7)
		"kufe":
			art.shadow(x, y, 16); c.begin_path(); c.move_to(x - 15, y - 26); c.line_to(x + 15, y - 26); c.line_to(x + 11, y); c.line_to(x - 11, y); c.close_path(); c.fill("#b9894f"); c.stroke()
			c.set_stroke("rgba(90,60,30,.6)"); c.lw = 1
			var kk := -20
			while kk < 0:
				c.ln(x - 14, y + kk, x + 14, y + kk); kk += 6
			for e in [[-7, "#e74c3c"], [7, "#e67e22"], [0, "#27ae60"]]:
				c.circ(x + e[0], y - 29 - (6 if e[0] == 0 else 0), 6, e[1])
		"kayik":
			art.shadow(x, y, 46); c.begin_path(); c.move_to(x - 60, y - 30); c.line_to(x + 60, y - 30); c.quad_to(x + 52, y - 2, x + 30, y); c.line_to(x - 30, y); c.quad_to(x - 52, y - 2, x - 60, y - 30); c.close_path(); c.fill("#2e86c1"); c.stroke()
			c.fill_rect(x - 58, y - 30, 116, 6, "#f4f4f4"); c.stroke_rect(x - 58, y - 30, 116, 6); c.fill_rect(x - 30, y - 20, 60, 4, "#c0392b"); c.set_stroke("#8d5a2b"); c.lw = 3; c.ln(x - 20, y - 34, x + 40, y - 48); c.set_stroke(OL); c.lw = 2
			c.txt("MARTI-3", x, y - 11, 10, "#fff", "center", null)
		"baba":
			art.shadow(x, y, 13); c.rr(x - 10, y - 22, 20, 22, 4); c.fill("#2c3e50"); c.stroke(); c.ell(x, y - 22, 13, 5, "#34495e"); c.stroke()
		"halat":
			art.shadow(x, y, 17)
			for i in 4:
				c.ell(x, y - 4 - i * 5, 17 - i * 2, 7 - i, "#d4ac6e"); c.stroke()

# ---------------------------------------------------------------- kovalamaca başlangıcı
func rand_type() -> String:
	var t: float = C.t
	var z: int = C.zone
	var pool := ["teyze", "amca", "cocuk", "balikci", "hanim", "teyze"]
	if t > 8: pool.append("imam")
	if t > 15: pool.append_array(["kasap", "bekci", "cocuk"])
	if t > 30: pool.append_array(["kasap", "bekci", "teyze"])
	if z == 1: pool.append_array(["berber", "berber", "hamamci", "hamamci"])
	if z == 2: pool.append_array(["balikci", "balikci", "hamamci", "berber"])
	if R.get("night", 0): pool.append("bekci")
	return choice(pool)

func spawn_villager(type: String, side := "", dd = null) -> Dictionary:
	var d: Dictionary = dd if dd != null else D.VT[type]
	var x := 0.0
	var y := 0.0
	if side == "": side = choice(["left", "right", "bottom", "door", "door"])
	if side == "door" and ARENA.doors.is_empty(): side = choice(["left", "right"])
	match side:
		"left": x = -30; y = randf_range(170, 500)
		"right": x = W + 30; y = randf_range(170, 500)
		"bottom": x = randf_range(60, 900); y = H + 30
		_:
			var dr: Dictionary = choice(ARENA.doors)
			x = dr.x; y = dr.y; dust(x, y, 6)
	var v := {"type": type, "d": d, "x": x, "y": y, "vx": 0.0, "vy": 0.0, "r": float(d.r), "stun": 0.0, "imm": 0.0, "gloat": 0.0, "eat": 0.0, "eatTarget": null, "cool": randf_range(1.5, 3), "ph": randf_range(0, 6), "shoutT": randf_range(1, 5),
		"f": -1.0, "z": 0.0, "vz": 0.0, "rot": 0.0, "rotA": 0.0, "dance": 0.0, "slipImm": 0.0, "entered": false, "zig": randf_range(0, 6), "flat": false, "lastItem": null, "pend": null, "wind": 0.0, "inCloud": false}
	C.vill.append(v)
	if type == "bekci": Snd.play("whistle")
	return v

func pick_kinci():
	var g: Dictionary = D.save_data.grudge
	var cands: Array = []
	var total := 0.0
	for t in g:
		if int(g[t]) >= 3 and D.VT.has(t):
			cands.append(t); total += float(g[t])
	if cands.is_empty(): return null
	var r := randf() * total
	for t in cands:
		r -= float(g[t])
		if r <= 0: return t
	return cands[0]

func start_chase() -> void:
	state = "chase"; flash = 1.0; parts = []; texts = []; bubbles = []; cam = 0.0
	var pool: Array = []
	for s in shore: pool.append(s.type)
	C = {"t": 0.0, "zone": 0, "spawnT": 3.0, "eventT": 6.0, "lastEv": "", "banner": {"text": "KAÇ!!!", "sub": "Padişahın ulağı gelene kadar dayan!", "t": 0.0}, "vill": [], "proj": [], "cats": [], "haz": [], "items": [], "cart": null, "halay": null,
		"win": false, "lose": false, "e": {"t": 0.0, "ev": {}}, "featherT": 12.0, "pool": pool, "talkT": 3.0, "ulak": null, "cloud": null, "yellCd": 0.0,
		"news": ["SON DAKİKA: Uçan bir adam %s meydanına indi!" % R.to, "Şalvar sahibi teyze: \"O şalvar annemden yadigârdı!\""], "tk": null, "boss": null, "mini": null, "miniDone": 0, "portrait": null, "cause": "dayak", "potUsed": 0, "stamp": 0,
		"gullX": randf_range(220, 740), "winT": 4.0, "kahveT": 3.0, "kahveCheer": 0.0, "kinci": pick_kinci(), "kinciDone": 0, "gust": null, "gustT": 6.0, "saray": null, "hpMax": 5, "spMul": 1.0, "dashMul": 1.0, "shield": 0, "villMul": 1.0, "pick": null, "perks": []}
	for k in ["bumps", "cart", "ff", "dance", "bossStun", "mini", "kin", "saray", "stuns", "hits", "terlik", "dodges", "surv"]:
		if not stats.has(k): stats[k] = 0
	set_zone(0); rain_puddles()
	P = {"x": 240.0, "y": 330.0, "vx": 0.0, "vy": 0.0, "r": 15.0, "hp": 5, "inv": 1.5, "dashT": 0.0, "dashCd": 0.0, "dx": 1.0, "dy": 0.0, "f": 1.0, "ph": 0.0, "wet": 0.0, "foam": 0.0, "trip": 0.0, "flyT": 0.0, "fz": 0.0, "z": 0.0, "vz": 0.0, "rot": 0.0, "salvar": true, "dance": 0.0, "knock": 0.0}
	for i in 4:
		var t: String = C.pool.pop_front() if C.pool.size() > 0 else rand_type()
		var v := spawn_villager(t, "right")
		v.x = W + 30 + i * 50; v.y = 200.0 + i * 80
	Snd.play("yell"); Snd.music("chase")

func rain_puddles() -> void:
	if WX != "yagmur": return
	for i in 3:
		var h := {}
		for tries in 30:
			h = {"k": "kova", "x": randf_range(100, 860), "y": randf_range(200, 480), "t": 9.0, "warn": 0.0, "r": 52.0, "done": true, "puddle": 1e9, "win": null}
			if not obst_near(h.x, h.y, 60): break
		C.haz.append(h)

# ---------------------------------------------------------------- hasar / mermiler / olaylar
func hurt_player(src: Dictionary, kind := "") -> void:
	if C.lose or C.win: return
	if C.shield > 0:
		C.shield -= 1; P.inv = 1.2; Snd.play("clang"); shake = 6.0; pop_text(P.x, P.y - 95, "TANNN! SİNİ KALKANI!", "#ffd166", 24); stars_fx(P.x, P.y - 60, 6); return
	if D.save_data.hat == "tencere" and not C.potUsed:
		C.potUsed = 1; P.inv = 1.2; Snd.play("clang"); shake = 7.0; pop_text(P.x, P.y - 95, "DANNG! TENCERE KALKANI!", "#dfe6e9", 24); say(P, "Tencere hayat kurtarır!", 1.3, -100); stars_fx(P.x, P.y - 60, 6); return
	C.cause = kind if kind != "" else ("boss" if src.get("boss") else ("karpuz" if is_same(src, C.cart) else "dayak"))
	P.hp -= 1; P.inv = 1.3
	var a := atan2(P.y - src.y, P.x - src.x)
	P.vx = cos(a) * 420; P.vy = sin(a) * 420; P.knock = .25; P.dashT = 0.0
	shake = 12.0; slow = .1; Snd.play("bonk"); stars_fx(P.x, P.y - 50, 7); pop_text(P.x, P.y - 70, choice(["PAT!", "KÜT!", "ŞAP!", "TAK!", "ÇAT!"]), "#ffdd33", 38); stats.hits += 1
	if src.has("d"):
		src.gloat = .9; say(src, choice(["Oh olsun!", "Bir tane de benden!", "Uç bakalım şimdi!", "Hah!"]), 1.2, -88)
	if P.hp > 0:
		if not src.has("d"): say(P, choice(D.L_HURT), 1.4, -100)
	else:
		start_beat()

func throw_proj(v: Dictionary, thr) -> void:
	var k: String = "terlik" if (thr is int and thr == 1) else str(thr)
	var homing: bool = k == "terlik" and randf() < .18
	var tx: float = P.x + P.vx * .35
	var ty: float = P.y + P.vy * .35
	var a := atan2(ty - v.y, tx - v.x)
	var sp := 250.0 if homing else (360.0 if k == "terlik" else 310.0)
	C.proj.append({"k": k, "x": v.x, "y": v.y, "z": 40.0, "vx": cos(a) * sp, "vy": sin(a) * sp, "rot": 0.0, "life": 3.6 if homing else 1.6, "homing": homing, "sp": sp, "owner": v, "landed": false})
	Snd.play("throw")
	if homing:
		pop_text(v.x, v.y - 95, "GÜDÜMLÜ TERLİK!", "#ff6b6b", 22); say(v, "Annemden öğrendim!", 1.6, -88)
	elif k == "kopuk" and randf() < .4: say(v, "Köpüğü yedin!", 1.2, -88)
	elif k == "tespih" and randf() < .4: say(v, "Tespih tutar!", 1.2, -88)

func grudge(v: Dictionary, how: String) -> void:
	if v.has("boss") or not D.NAMES.has(v.type): return
	var g: Dictionary = D.save_data.grudge
	g[v.type] = int(g.get(v.type, 0)) + 1
	D.save_data.gh[v.type] = how
	if v.get("kinci", false) and not stats.kin:
		stats.kin = 1; v.pend = {"t": .6, "text": "Yine mi?! Bu iş burada bitmez!"}; news("%s yine yere serildi. Kin defteri kabardı." % D.NAMES[v.type])

func stun_v(v: Dictionary, t: float, line: String, score := 40, how := "kafa") -> void:
	v.stun = max(v.stun, t)
	if line != "": say(v, line, 1.4, -88)
	stats.stuns += 1; stats.score += score
	grudge(v, how)

func kahve_cheer() -> void:
	if C.zone != 0: return
	for o in OBST:
		if o.k == "kahve" and o.has("m1"):
			C.kahveCheer = 1.6; say(o.m1, choice(["Oleeey!", "Gol! ...Yani çarpışma!", "Bir daha, bir daha!"]), 1.4, -78)

func bump(a: Dictionary, b: Dictionary, nx: float, ny: float) -> void:
	a.stun = 1.7; b.stun = 1.7; a.imm = 3.0; b.imm = 3.0
	a.vx = -nx * 180; a.vy = -ny * 180; b.vx = nx * 180; b.vy = ny * 180
	var pr: Array = choice(D.L_ARGUE)
	say(a, pr[0], 1.5, -88); b.pend = {"t": .55, "text": pr[1]}; Snd.play("bonk"); shake = max(shake, 6.0)
	var mx: float = (a.x + b.x) / 2
	var my: float = (a.y + b.y) / 2
	pop_text(mx, my - 70, choice(["DANK!", "TOS!", "KAFA KAFAYA!", "ÇARPIŞMA!"]), "#7bed9f", 30); stars_fx(mx, my - 50, 8)
	stats.stuns += 2; stats.bumps += 1; stats.score += 120; grudge(a, "kafa"); grudge(b, "kafa"); kahve_cheer()
	if randf() < .5: news(choice(["İki komşu kafa kafaya çarpıştı. Dayak sırası tartışılıyor.", "Mahallede kafa kafaya çarpışma! Doktor: \"İkisinin de kafası zaten boştu.\"", "Çarpışan komşular barıştı, sonra tekrar küstü."]))

func start_event() -> void:
	var e := ""
	while true:
		e = choice(["kova", "kedi", "karpuz", "simit", "halay"])
		if e != C.lastEv and not (e == "kova" and ARENA.wins.is_empty()): break
	C.lastEv = e
	news({"kova": "Teyzeler pencereden su döküyor. Belediye: \"Bizim suyumuz değil.\"", "kedi": "Mahalle kedileri açıklama yaptı: \"Miyav. Miyav miyav.\"", "karpuz": "Karpuzcu: \"Arabam kendi kendine kaçtı, ben karışmam!\"", "simit": "Simitçi tepsiyi düşürdü. Mahalle iki saniyeliğine dayağı unuttu.", "halay": "Düğün alayı kovalamacaya karıştı. Gelin: \"Benim düğünüm!\""}[e])
	match e:
		"kova":
			banner("PENCEREDEN SU!", "Teyze çamaşır suyunu döküyor... hedef: herkes!")
			for i in 4:
				var near := i == 0
				var h := {"k": "kova", "x": clamp(P.x + randf_range(-40, 40), 60, 900) if near else randf_range(60, 900), "y": clamp(P.y + randf_range(-30, 30), 170, 500) if near else randf_range(175, 500), "t": 0.0, "warn": 1.4 + i * .3, "r": 58.0, "done": false, "puddle": 0.0}
				var wn = null
				for w in ARENA.wins:
					if wn == null or abs(w.x - h.x) < abs(wn.x - h.x): wn = w
				h["win"] = wn
				C.haz.append(h)
		"kedi":
			banner("KEDİ SÜRÜSÜ!", "Üsküdar'ın asıl sahipleri geçiyor")
			var from_l := randf() < .5
			for i in 9:
				C.cats.append({"x": (-40 - i * randf_range(50, 90)) if from_l else (W + 40 + i * randf_range(50, 90)), "y": randf_range(165, 505), "vx": (1.0 if from_l else -1.0) * randf_range(260, 340), "ph": randf_range(0, 6), "col": choice(["#f39c12", "#555", "#eee", "#d35400", "#222"])})
			Snd.play("meow")
		"karpuz":
			banner("KARPUZ ARABASI KAÇTI!", "Şeritten çekil!")
			var dir := 1.0 if randf() < .5 else -1.0
			C.cart = {"y": clamp(P.y + randf_range(-25, 25), 175, 500), "warn": 1.5, "x": -140.0 if dir > 0 else W + 140, "dir": dir, "hits": [], "go": 0, "owner": {"x": 0.0, "y": 0.0, "vo": "karpuzcu"}}
			Snd.play("rumble")
		"simit":
			banner("SİMİTÇİ TEPSİYİ DÜŞÜRDÜ!", "Simit ye, can bul! (Mahalleli de seviyor)")
			for i in 5:
				var it := {}
				for tries in 20:
					it = {"k": "simit", "x": randf_range(80, 880), "y": randf_range(185, 500), "t": 0.0, "got": false}
					if not obst_near(it.x, it.y, 20): break
				C.items.append(it)
		"halay":
			banner("DÜĞÜN HALAYI!", "Halaya yakalanan oynar!")
			var dir := 1.0 if randf() < .5 else -1.0
			C.halay = {"y": clamp(P.y + randf_range(-60, 60), 190, 480), "x": -40.0 if dir > 0 else W + 40, "dir": dir, "beat": 0.0}

func start_win() -> void:
	C.win = true; C.e = {"t": 0.0, "ev": {}}; Snd.music("win"); Snd.play("whistle"); C.cart = null; C.halay = null; C.proj = []
	C.ulak = {"vo": "ulak", "x": clamp(P.x + 120 if P.x < 480 else P.x - 120, 80, 880), "y": 140.0, "ty": clamp(P.y, 200, 380), "arrived": false}
	if abs(C.ulak.x - 480) < 90: C.ulak.x = 380.0 if C.ulak.x < 480 else 580.0
	for v in C.vill:
		v.stun = 0.0; v.dance = 0.0; v.eat = 0.0; v.wind = 0.0

func start_beat() -> void:
	C.lose = true; C.e = {"t": 0.0, "ev": {}}; Snd.music_stop(); C.cloud = {"x": P.x, "y": P.y, "pt": 0.0}; Snd.play("yell"); shake = 16.0

# ---------------------------------------------------------------- güçlendirme
func pick_x(i: int) -> float:
	return W / 2 - 345 + i * 240

func start_pick() -> void:
	var pool := PERKS.duplicate()
	pool.shuffle()
	if P.hp < C.hpMax:
		for i in pool.size():
			if pool[i].id == "yurek":
				var y = pool[i]; pool.remove_at(i); pool.push_front(y); break
	var o := pool.slice(0, 3)
	o.shuffle()
	C.pick = {"o": o, "sel": 1, "t": 0.0}
	Snd.play("pop")

func choose_perk(i: int) -> void:
	var k: Dictionary = C.pick.o[i]
	match k.id:
		"yurek": C.hpMax = mini(8, C.hpMax + 1); P.hp = C.hpMax
		"pabuc": C.spMul += .2
		"ruzgar": C.dashMul *= .5
		"kalkan": C.shield += 2
		"lokum": C.villMul *= .8
		"tuy": P.flyT = 8.0
	C.perks.append(k.ic); C.pick = null; P.inv = max(P.inv, 1.5); Snd.play("fanfare"); stars_fx(P.x, P.y - 50, 10); pop_text(P.x, P.y - 90, k.n.to_upper() + "!", "#ffe066", 28)

func upd_pick(dt: float) -> void:
	var p: Dictionary = C.pick
	p.t += dt
	if hit(["ArrowLeft", "KeyA"]): p.sel = (p.sel + 2) % 3; Snd.play("pop")
	if hit(["ArrowRight", "KeyD"]): p.sel = (p.sel + 1) % 3; Snd.play("pop")
	if p.t < .5: return
	for i in 3:
		if hit(["Digit%d" % (i + 1)]):
			choose_perk(i); return
	if hit(["Space", "Enter"]):
		choose_perk(p.sel); return
	if ptr.tap:
		for i in 3:
			var x := pick_x(i)
			if ptr.x > x and ptr.x < x + 210 and ptr.y > 150 and ptr.y < 400:
				choose_perk(i); return

func change_zone(z: int) -> void:
	set_zone(z); flash = .9; Snd.play("dash"); Snd.play("whistle")
	banner("ÇARŞIYA DALDIN!" if z == 1 else "İSKELEYE KAÇTIN!", "Tezgâhlara dikkat, berber de peşinde!" if z == 1 else "Son durak: deniz kenarı. Ulak yakında!")
	P.x = 90.0; P.vx = abs(P.vx); P.inv = max(P.inv, 1.2); P.dance = 0.0
	for v in C.vill:
		v.x = -40 - randf_range(0, 260); v.y = clamp(v.y, 170, 500); v.entered = false; v.z = 0.0; v.vz = 0.0; v.stun = 0.0; v.dance = 0.0; v.eat = 0.0; v.eatTarget = null; v.wind = 0.0
	C.proj = []; C.haz = []; C.cart = null; C.halay = null; C.items = []; C.cats = []; C.eventT = 4.0; C.mini = null; rain_puddles()
	news("Uçan adam çarşıya girdi! Esnaf kepenk indirdi... sonra kovalamaya katıldı." if z == 1 else "Uçan adam iskelede! Balıkçılar oltaları bırakıp koştu.")
	start_pick()

func spawn_boss() -> void:
	Snd.music("boss")
	var d: Dictionary = {"speed": 88.0, "r": 24.0, "s": 1.3, "wide": 1.35}
	d.merge(R.boss, true)
	var v := spawn_villager("boss", "right", d)
	v.x = W + 40; v.y = clamp(P.y, 200, 460); v["boss"] = {"st": "walk", "t": 2.5, "ax": 0.0, "ay": 0.0}; C.boss = v
	banner("%s GELDİ!" % R.boss.n, R.boss.sub); Snd.play("rumble"); shake = 10.0; say(v, R.boss.lines[0], 2.2, -122, 3); news("%s olay yerinde: \"%s\"" % [R.boss.n, R.boss.lines[1]])

func start_mini() -> void:
	C.miniDone = 1; C.mini = {"x": 740.0 if P.x < 480 else 200.0, "y": 205.0, "t": 0.0, "vo": "ressam", "done": 0}
	say(C.mini, "Kıpırdama! Minyatürünü yapıyorum!", 2.4, -92, 2); news("Saray minyatürcüsü olay yerinde: \"Kanatları biraz büyük çizeceğim.\"")

func spawn_kinci() -> void:
	var t: String = C.kinci
	C.kinciDone = 1
	var v := spawn_villager(t, "right")
	var line: String = D.GL.get(D.save_data.gh.get(t, "kafa"), D.GL.kafa)
	v["kinci"] = true
	var d: Dictionary = v.d.duplicate()
	d.speed = d.speed * 1.25; d["lines"] = [line, "Bugün hesaplaşma günü!", "Seni bekliyordum, kuş adam!", "Kin tutmam ama seni tutarım!"]
	v.d = d
	banner("KİNCİ GELDİ!", "%s seni unutmadı!" % D.NAMES[t]); say(v, line, 2.6, -88, 3); news("%s: \"%s\"" % [D.NAMES[t], line]); Snd.play("yellHigh")

# ---------------------------------------------------------------- güncelleme
func upd_other(dt: float) -> void:
	match state:
		"chase": upd_chase(dt)
		"saray": upd_saray(dt)
		"end": upd_end(dt)

func upd_chase(dt: float) -> void:
	if C.pick != null:
		upd_pick(dt); return
	var busy: bool = C.win or C.lose
	if not busy: C.t += dt
	C.yellCd -= dt
	if C.banner != null:
		C.banner.t += dt
		if C.banner.t > 2.4: C.banner = null
	upd_player_c(dt, busy)
	upd_villagers(dt)
	upd_proj(dt); upd_hazards(dt); upd_items(dt)
	if not busy:
		C.spawnT -= dt
		var cap: int = mini(16, 4 + int(C.t / 5))
		if C.spawnT <= 0:
			C.spawnT = max(1.3, 4 - C.t * .05)
			if C.vill.size() < cap:
				var v := spawn_villager(C.pool.pop_front() if C.pool.size() > 0 else rand_type())
				if randf() < .35: say(v, choice(["Ben de geliyorum!", "Nerede o kuş adam?!", "Bekleyin beni!", "Dayak var dediler?"]), 1.6, -88)
		C.eventT -= dt
		if C.eventT <= 0:
			start_event(); C.eventT = randf_range(7, 10)
		C.featherT -= dt
		if C.featherT <= 0:
			C.featherT = randf_range(13, 18)
			var it := {}
			for tries in 20:
				it = {"k": "tuy", "x": randf_range(80, 880), "y": randf_range(190, 500), "t": 0.0, "got": false}
				if not obst_near(it.x, it.y, 24) and dst(it, P) >= 150: break
			C.items.append(it); pop_text(it.x, it.y - 50, "SİHİRLİ TÜY!", "#fff", 20)
		C.talkT -= dt
		if C.talkT <= 0:
			C.talkT = randf_range(5, 9)
			if not has_bubble(P): say(P, choice(D.L_RUN), 1.8, -100)
		if C.zone == 0 and C.t >= 20: change_zone(1)
		elif C.zone == 1 and C.t >= 40: change_zone(2)
		if C.pick != null: return
		if C.boss == null and C.t >= 44: spawn_boss()
		if not C.miniDone and C.zone == 1 and C.t >= 25: start_mini()
		if C.t >= SURV: start_win()
	if C.mini != null:
		var m: Dictionary = C.mini
		m.t += dt
		if m.t >= 5 and not m.done:
			m.done = 1
			var ok: bool = dst(P, m) < 330 and not C.lose
			C.portrait = {"t": 3.6, "ok": ok}; Snd.play("fanfare")
			if ok:
				stats.mini = 1; stats.score += 150; pop_text(m.x, m.y - 105, "MİNYATÜR HAZIR! +150", "#ffe066", 24); say(m, "Muhteşem! Saraya asılacak!", 2, -92, 2); news("Minyatürcü: \"Eserimin adı: Kaçan Adam ve Şalvar.\"")
			else:
				say(m, "Kıpırdadın! At gibi çıktın!", 2, -92, 2); news("Minyatürcü: \"Model kaçtı, ben de at çizdim.\"")
		if not m.done:
			for v in C.vill:
				if v.stun <= 0 and v.z < 5 and v.entered and Vector2(v.x - (m.x + 28), v.y - m.y).length() < v.r + 16: stun_v(v, 1.2, "Tuvale çarptım!", 40, "tuval")
		if m.t > 8: C.mini = null
	if C.portrait != null:
		C.portrait.t -= dt
		if C.portrait.t <= 0: C.portrait = null
	if C.tk == null:
		var t: String = C.news.pop_front() if C.news.size() > 0 else choice(D.NEWS)
		C.tk = {"t": t, "x": W - 48, "w": c.measure(t, 15)}
	C.tk.x -= 135 * dt
	if C.tk.x + C.tk.w < 128: C.tk = null
	chase_extras(dt, busy)
	if C.win: upd_win(dt)
	if C.lose: upd_lose(dt)

func upd_player_c(dt: float, busy: bool) -> void:
	P.dashCd -= dt; P.inv -= dt; P.wet -= dt; P.foam -= dt; P.trip -= dt; P.flyT -= dt; P.dance -= dt
	if P.z > 0 or P.vz > 0:
		P.vz -= 1100 * dt; P.z += P.vz * dt
		if P.z <= 0:
			P.z = 0.0; P.vz = 0.0; dust(P.x, P.y, 6)
	P.fz = lerp(float(P.fz), (42 + sin(T * 6) * 6) if P.flyT > 0 else 0.0, min(1.0, dt * 6))
	if C.lose:
		P.vx = 0.0; P.vy = 0.0; return
	var ix: float = (1.0 if held("ArrowRight") or held("KeyD") else 0.0) - (1.0 if held("ArrowLeft") or held("KeyA") else 0.0)
	var iy: float = (1.0 if held("ArrowDown") or held("KeyS") else 0.0) - (1.0 if held("ArrowUp") or held("KeyW") else 0.0)
	if ptr.down and ix == 0 and iy == 0:
		var dx: float = ptr.x - P.x
		var dy: float = ptr.y - (P.y - 20)
		var d := sqrt(dx * dx + dy * dy)
		if d > 14:
			ix = dx / d; iy = dy / d
	if C.win:
		ix = 0; iy = 0
	var il := sqrt(ix * ix + iy * iy)
	if il > 0:
		ix /= il; iy /= il; P.dx = ix; P.dy = iy
	var sp := 215.0
	if P.wet > 0: sp = 140
	if P.trip > 0: sp = 70
	if P.flyT > 0: sp = 290
	sp *= C.spMul
	if P.dance > 0: sp = 0
	if not busy and (hit(["Space", "ShiftLeft", "KeyJ"]) or ptr.dbl) and P.dashCd <= 0 and P.knock <= 0 and P.dance <= 0:
		P.dashT = .2; P.dashCd = 1.25 * C.dashMul; Snd.play("dash"); dust(P.x, P.y, 5)
	if P.knock > 0:
		P.knock -= dt
		var fr: float = max(0.0, 1 - dt * 6)
		P.vx *= fr; P.vy *= fr
	elif P.dashT > 0:
		P.dashT -= dt; P.vx = P.dx * 640; P.vy = P.dy * 640
		add_p({"type": "ghost", "x": P.x, "y": P.y, "life": .22, "o": D.hez_opts({"s": .95, "f": P.f, "wa": -1.05, "wl": 42.0, "salvar": true, "run": 1.0, "ph": P.ph})})
	else:
		var k: float = min(1.0, dt * (3.5 if WX == "kar" else 14.0))
		P.vx += (ix * sp - P.vx) * k; P.vy += (iy * sp - P.vy) * k
	P.x += P.vx * dt; P.y += P.vy * dt
	if P.flyT <= 0: obst_push(P)
	bounds(P)
	if abs(P.vx) > 8: P.f = 1.0 if P.vx > 0 else -1.0
	P.ph += dt * Vector2(P.vx, P.vy).length() * .06
	if P.wet > 0 and randf() < .3:
		add_p({"type": "dot", "x": P.x + randf_range(-8, 8), "y": P.y - 40, "vy": 60.0, "g": 300.0, "life": .4, "size": 2.0, "color": "#7fc4ef"})

func upd_villagers(dt: float) -> void:
	var V: Array = C.vill
	for v in V:
		v.ph += dt * 10; v.imm -= dt; v.slipImm -= dt; v.cool -= dt; v.shoutT -= dt
		if v.pend != null:
			v.pend.t -= dt
			if v.pend.t <= 0:
				say(v, v.pend.text, 1.5, -88); v.pend = null
		if v.z > 0 or v.vz > 0:
			v.vz -= 1100 * dt; v.z += v.vz * dt; v.rotA += dt * 14
			if v.z <= 0:
				v.z = 0.0; v.vz = 0.0; v.rotA = 0.0; dust(v.x, v.y, 8); Snd.play("thud")
		var tvx := 0.0
		var tvy := 0.0
		var k: float = min(1.0, dt * (1.4 if WX == "kar" else 3.2))
		var act := false
		if C.win:
			if C.ulak != null: v.f = 1.0 if C.ulak.x > v.x else -1.0
			k = min(1.0, dt * 5)
		elif C.lose:
			var d := dst(v, C.cloud)
			if d < 230 and d > 26:
				tvx = (C.cloud.x - v.x) / d * 200; tvy = (C.cloud.y - v.y) / d * 200
			if d <= 30: v.inCloud = true
		elif v.stun > 0:
			v.stun -= dt; k = min(1.0, dt * 4)
			if v.stun <= 0: v.flat = false
		elif v.dance > 0:
			v.dance -= dt; tvx = C.halay.dir * 110 if C.halay != null else 0.0
		elif v.eat > 0:
			v.eat -= dt
			if randf() < .1: add_p({"type": "dot", "x": v.x + v.f * 8, "y": v.y - 45, "vx": randf_range(-30, 30), "vy": -40.0, "g": 300.0, "life": .5, "size": 1.6, "color": "#c47a35"})
		elif v.gloat > 0:
			v.gloat -= dt; k = min(1.0, dt * 6)
		else:
			act = true
		if act:
			var tx: float = P.x + P.vx * .25
			var ty: float = P.y + P.vy * .25
			if not v.entered:
				tx = clamp(tx, AR.x0 + 40, AR.x1 - 40); ty = clamp(ty, AR.y0 + 30, AR.y1 - 30)
			if v.eatTarget != null:
				if v.eatTarget.got:
					v.eatTarget = null
				else:
					tx = v.eatTarget.x; ty = v.eatTarget.y
					if dst(v, v.eatTarget) < 18:
						v.eatTarget.got = true; v.eat = 2.5; say(v, choice(["Mmm susamlı!", "Simit bedava mı?", "Bir çay olsa...", "Dayak sonra, simit önce!"]), 2, -88); Snd.play("eat"); v.eatTarget = null
			var dx: float = tx - v.x
			var dy: float = ty - v.y
			var dd := sqrt(dx * dx + dy * dy)
			if dd == 0: dd = 1
			dx /= dd; dy /= dd
			if v.type == "cocuk":
				var zz := sin(C.t * 4 + v.zig) * .6
				var nx := dx - dy * zz
				var ny := dy + dx * zz
				dx = nx; dy = ny
			var sp: float = v.d.speed * (1 + min(.45, C.t / 120.0)) * C.villMul
			if P.flyT > 0 and v.eatTarget == null: sp *= .55
			tvx = dx * sp; tvy = dy * sp
			var thr = v.d.get("throws", 0)
			if (thr is int and thr == 0) and WX == "kar" and v.type == "cocuk": thr = "kartopu"
			if not (thr is int and thr == 0) and v.cool <= 0 and dd > 110 and dd < 420 and P.flyT <= 0 and v.entered:
				v.cool = randf_range(2.6, 4.2); throw_proj(v, thr)
			if v.d.get("melee", 0):
				if v.wind > 0:
					v.wind -= dt; tvx *= .2; tvy *= .2
					if v.wind <= 0:
						var ok: bool = dst(v, P) < v.r + P.r + 50 and P.inv <= 0 and P.flyT <= 0 and P.dashT <= 0 and P.z < 5
						pop_text(v.x + v.f * 30, v.y - 75, "ŞAAAK!" if ok else "ŞAK!", "#ff6b6b" if ok else "#fff", 30 if ok else 22); Snd.play("whip")
						if ok: hurt_player(v, "havlu")
				elif v.cool <= 0 and dd < 95 and v.entered and P.flyT <= 0:
					v.wind = .42; v.cool = 2.4; say(v, "Havlu geliyooor!", .8, -88)
			if v.has("boss"):
				var b: Dictionary = v.boss
				b.t -= dt
				if b.st == "walk" and b.t <= 0 and v.entered and dd < 560:
					b.st = "aim"; b.t = .8; say(v, choice(["MÜHÜR!", "Dur orada!", "Hücuuum!"]), .9, -122, 2); Snd.play("whistle")
				if b.st == "aim":
					var a := atan2(P.y - v.y, P.x - v.x)
					b.ax = cos(a); b.ay = sin(a); tvx = 0; tvy = 0; k = 1
					if b.t <= 0:
						b.st = "charge"; b.t = .7; Snd.play("dash"); shake = max(shake, 4.0)
				elif b.st == "charge":
					tvx = b.ax * 600; tvy = b.ay * 600; k = 1
					if randf() < .5: dust(v.x, v.y, 1)
					if b.t <= 0:
						b.st = "rest"; b.t = .8
				elif b.st == "rest":
					tvx = 0; tvy = 0
					if b.t <= 0:
						b.st = "walk"; b.t = randf_range(1.8, 3)
			if v.shoutT <= 0:
				v.shoutT = randf_range(4, 9)
				if bubbles.size() < 4: say(v, choice(v.d.get("lines", D.SH.get(v.type, ["Dur!"]))), 2, -88)
				if C.yellCd <= 0 and randf() < .4:
					Snd.play("yell" if randf() < .5 else "yellHigh"); C.yellCd = 2.5
		v.vx += (tvx - v.vx) * k; v.vy += (tvy - v.vy) * k
		v.x += v.vx * dt; v.y += v.vy * dt
		if v.has("boss") and v.boss.st == "aim": v.f = 1.0 if v.boss.ax > 0 else -1.0
		elif abs(v.vx) > 10 and not C.win: v.f = 1.0 if v.vx > 0 else -1.0
		if not v.entered:
			if v.x > AR.x0 and v.x < AR.x1 and v.y > AR.y0 and v.y < AR.y1: v.entered = true
		else:
			obst_push(v); bounds(v)
		if v.has("boss") and v.boss.st == "charge" and v.entered and act:
			var hit_o := obst_near(v.x, v.y, v.r * .7 + 4)
			var hit_b: bool = v.x <= AR.x0 + 1 or v.x >= AR.x1 - 1 or v.y <= AR.y0 + 1 or v.y >= AR.y1 - 1
			if hit_o or hit_b:
				v.boss.st = "walk"; v.boss.t = 3.2; v.stun = 2.4; v.imm = 1.0; v.vx *= -.3; v.vy *= -.3; shake = 14.0; Snd.play("crash"); Snd.play("bonk"); stars_fx(v.x, v.y - 80, 10); pop_text(v.x, v.y - 115, "GÜÜÜM!", "#ff6b6b", 40)
				stats.bossStun += 1; stats.stuns += 1; stats.score += 300
				say(v, choice(["Kim koydu bunu buraya?!", "Mührüm kırıldı!", "Ay belim!", "Bu sayılmaz!"]), 1.6, -122, 2); news("%s bir engele toslarken görüntülendi. Açıklama yapmadı." % R.boss.n)
			else:
				for u in V:
					if not is_same(u, v) and u.z < 5 and u.stun <= 0 and u.entered and dst(u, v) < u.r + v.r:
						u.vz = 420.0; u.z = 1.0; u.flat = true; u.vx = v.vx * .5; u.vy = v.vy * .5
						stun_v(u, 2, choice(["Beni de mi ezdin?!", "Ben senin tarafındayım!", "Ayy!"]), 60, "patron"); Snd.play("bonk")
		if not C.win and not C.lose and act and v.z < 5 and P.z < 5 and dst(v, P) < v.r + P.r:
			if P.dashT > 0:
				if v.imm <= 0:
					v.stun = .8; v.imm = 1.0; say(v, choice(["Nereye gitti?!", "Hızlı bu!", "Gözüm döndü!", "Hayalet mi bu?!"]), 1.3, -88); stats.dodges += 1; stats.score += 25; pop_text(v.x, v.y - 80, "KIL PAYI!", "#7bed9f", 20)
			elif P.inv <= 0 and P.flyT <= 0:
				hurt_player(v)
	if not C.win and not C.lose:
		for i in V.size():
			for j in range(i + 1, V.size()):
				var a: Dictionary = V[i]
				var b: Dictionary = V[j]
				if a.z > 5 or b.z > 5: continue
				var dx: float = b.x - a.x
				var dy: float = b.y - a.y
				var d := sqrt(dx * dx + dy * dy)
				if d == 0: d = .01
				var m: float = a.r + b.r
				if d < m:
					var nx := dx / d
					var ny := dy / d
					var close: float = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny
					if close > 150 and a.stun <= 0 and b.stun <= 0 and a.imm <= 0 and b.imm <= 0 and a.dance <= 0 and b.dance <= 0 and a.entered and b.entered and not a.has("boss") and not b.has("boss"):
						bump(a, b, nx, ny)
					var push := (m - d) / 2
					a.x -= nx * push; a.y -= ny * push; b.x += nx * push; b.y += ny * push

func upd_proj(dt: float) -> void:
	for p in C.proj:
		if p.homing:
			var a := atan2(P.y - p.y, P.x - p.x)
			var cur := atan2(p.vy, p.vx)
			var da := wrapf(a - cur, -PI, PI)
			var na: float = cur + clamp(da, -2.6 * dt, 2.6 * dt)
			p.vx = cos(na) * p.sp; p.vy = sin(na) * p.sp
		p.x += p.vx * dt; p.y += p.vy * dt; p.rot += dt * 18; p.life -= dt
		if not C.win and not C.lose and Vector2(p.x - P.x, p.y - P.y).length() < 18 and P.z < 20:
			if P.inv <= 0 and P.flyT <= 0 and P.dashT <= 0:
				p.life = 0.0
				match p.k:
					"terlik":
						stats.terlik += 1; hurt_player(p, "terlik"); pop_text(P.x, P.y - 100, "TERLİK!", "#ff6b6b", 26)
					"kopuk":
						P.wet = 2.4; P.foam = 2.4; pop_text(P.x, P.y - 100, "KÖPÜK!", "#fff", 26); say(P, "Tıraş olmak istemiyorum!", 1.3, -100); Snd.play("splat")
					"kartopu":
						P.trip = .5; pop_text(P.x, P.y - 100, "KARTOPU!", "#fff", 26); say(P, "Ensemden soğuk girdi!", 1.2, -100); Snd.play("splat")
					_:
						P.trip = 1.0; pop_text(P.x, P.y - 100, "TESPİH DOLANDI!", "#1abc9c", 22); say(P, "Ayağıma dolandı!", 1.2, -100); Snd.play("slip")
		for v in C.vill:
			if p.life > 0 and not is_same(v, p.owner) and v.stun <= 0 and v.z < 5 and Vector2(p.x - v.x, p.y - v.y).length() < v.r + 8:
				p.life = 0.0; stats.ff += 1
				stun_v(v, 1.3, choice(["Kime attın onu?!", "Anne?!", "Yanlış kafa!"]), 50, "terlik"); Snd.play("bonk"); stars_fx(v.x, v.y - 50, 5); pop_text(v.x, v.y - 80, "DOST ATEŞİ!", "#ffa502", 20)
		if p.life <= 0 and not p.landed:
			p.landed = true
			if p.k == "terlik": add_p({"type": "terlik", "x": p.x, "y": p.y, "life": 2.0, "rot": p.rot})
			else:
				for i in 5: add_p({"type": "dot", "x": p.x, "y": p.y - p.z, "vx": randf_range(-80, 80), "vy": randf_range(-80, 20), "g": 300.0, "life": .5, "size": 3.0, "color": "#16a085" if p.k == "tespih" else "#fff"})
	C.proj = C.proj.filter(func(p): return p.life > 0 and p.x > -60 and p.x < W + 60 and p.y > 60 and p.y < H + 60)

func upd_hazards(dt: float) -> void:
	for h in C.haz:
		h.t += dt
		if not h.done and h.t >= h.warn:
			h.done = true; h.puddle = 6.0; Snd.play("splash"); splash_fx(h.x, h.y, 26)
			for v in C.vill:
				if v.z < 5 and in_ell(v, h, h.r): stun_v(v, 1.6, choice(["Sırılsıklam oldum!", "Bu su mu, çorba mı?!", "Glu!"]), 40, "kova")
			if in_ell(P, h, h.r) and P.flyT <= 0 and not C.lose:
				P.wet = 2.5; say(P, "Banyo yapmıştım zaten!", 1.5, -100); pop_text(P.x, P.y - 90, "ŞAAAP!", "#74b9ff", 30)
		if h.done:
			h.puddle -= dt
			for v in C.vill:
				if v.slipImm <= 0 and v.stun <= 0 and v.z < 5 and in_ell(v, h, h.r * .8) and Vector2(v.vx, v.vy).length() > 60:
					v.slipImm = 2.5; v.flat = true; stun_v(v, 1.3, "Kaydııım!", 40, "kova"); Snd.play("slip"); pop_text(v.x, v.y - 80, "VIIIZT!", "#74b9ff", 22)
	C.haz = C.haz.filter(func(h): return not h.done or h.puddle > 0)
	for ct in C.cats:
		ct.x += ct.vx * dt; ct.ph += dt * 16
		for v in C.vill:
			if v.stun <= 0 and v.z < 5 and v.entered and Vector2(v.x - ct.x, v.y - ct.y).length() < v.r + 10:
				v.flat = true; stun_v(v, 1.5, choice(["Kediye bastım!", "Pisi pisi... AH!", "Miyav dedi, düştüm!"]), 40, "kedi")
				if randf() < .5: Snd.play("meow")
		if P.trip <= 0 and P.flyT <= 0 and P.dashT <= 0 and Vector2(P.x - ct.x, P.y - ct.y).length() < P.r + 10:
			P.trip = .6; say(P, "Pardon pisi!", 1, -100); Snd.play("meow")
	C.cats = C.cats.filter(func(ct): return not ((ct.vx > 0 and ct.x > W + 60) or (ct.vx < 0 and ct.x < -60)))
	var cr = C.cart
	if cr != null:
		if cr.warn > 0:
			cr.warn -= dt
		else:
			if not cr.go:
				cr.go = 1; Snd.play("crash"); say(cr.owner, "Karpuzlarıııım!", 2.2, -88)
			cr.x += cr.dir * 720 * dt; cr.owner.x = cr.x - cr.dir * 130; cr.owner.y = cr.y + 4
			if randf() < .15: add_p({"type": "melon", "x": cr.x, "y": cr.y - 50, "vx": randf_range(-100, 100), "vy": randf_range(-200, -95), "g": 500.0, "life": 1.0, "size": 8.0, "vr": randf_range(-8, 8)})
			for v in C.vill:
				if not cr.hits.has(v) and abs(v.x - cr.x) < 60 and abs(v.y - cr.y) < 30:
					cr.hits.append(v); v.flat = true; stats.cart += 1
					if v.has("boss"):
						stats.bossStun += 1; news("%s karpuz arabasının altında kaldı. Karpuzlar iyi." % R.boss.n)
					stun_v(v, 3, choice(["Karpuzu hak ettim mi?!", "Uçuyorum anne!", "Ben de uçtum!"]), 80, "karpuz")
					v.vz = 420.0; v.z = 1.0; v.vx = cr.dir * 300; v.vy = randf_range(-60, 60); Snd.play("bonk"); pop_text(v.x, v.y - 60, choice(["ÇAT!", "GÜM!", "KARPUZ!"]), "#ff6b6b", 30)
					for i in 4: add_p({"type": "melon", "x": v.x, "y": v.y - 30, "vx": randf_range(-150, 150), "vy": randf_range(-250, -100), "g": 600.0, "life": 1.0, "size": 7.0, "vr": randf_range(-8, 8)})
			if not cr.hits.has(P) and abs(P.x - cr.x) < 60 and abs(P.y - cr.y) < 28 and P.flyT <= 0 and P.dashT <= 0 and P.inv <= 0 and not C.lose and not C.win:
				cr.hits.append(P); P.vz = 380.0; P.z = 1.0; hurt_player(cr)
			if (cr.dir > 0 and cr.x > W + 300) or (cr.dir < 0 and cr.x < -300): C.cart = null
	var h = C.halay
	if h != null:
		h.x += h.dir * 110 * dt; h.beat -= dt
		if h.beat <= 0:
			h.beat = .45; Snd.play("drum")
		var front: float = h.x
		var back: float = h.x - h.dir * 4 * 34
		var lo: float = min(front, back) - 14
		var hi: float = max(front, back) + 14
		for v in C.vill:
			if v.dance <= 0 and v.stun <= 0 and v.z < 5 and abs(v.y - h.y) < 26 and v.x > lo and v.x < hi:
				v.dance = 3.0; say(v, choice(["Bu benim şarkım!", "Halaaay!", "Dayak sonra, halay önce!", "Omuz omuza!"]), 1.6, -88); stats.stuns += 1; stats.dance += 1; stats.score += 50; grudge(v, "halay")
		if P.dance <= 0 and P.flyT <= 0 and not C.lose and abs(P.y - h.y) < 24 and P.x > lo and P.x < hi:
			P.dance = 1.0; say(P, "Ayaklarım kendiliğinden...!", 1.2, -100)
		if (h.dir > 0 and back > W + 40) or (h.dir < 0 and back < -40): C.halay = null

func upd_items(dt: float) -> void:
	for it in C.items:
		it.t += dt
		if not C.lose and dst(it, P) < 24 and P.z < 20:
			it.got = true; Snd.play("pickup")
			if it.k == "simit":
				var full: bool = P.hp >= C.hpMax
				P.hp = mini(C.hpMax, P.hp + 1); stats.simits += 1; stats.score += 60; pop_text(it.x, it.y - 40, "ÇITIR! +60" if full else "+1 CAN", "#ffe066", 24)
			else:
				P.flyT = 3.0; Snd.play("flap"); Snd.play("fanfare"); say(P, "Kanatlar şarj oldu! UÇUYORUM!", 1.6, -125); feathers(P.x, P.y - 30, 10); stats.score += 100
				for v in C.vill:
					if randf() < .3: v.pend = {"t": randf_range(.2, .8), "text": choice(["Yine uçuyor!!", "Aşağı in korkak!", "Haksızlık bu!"])}
		if it.k == "simit" and not it.got:
			for v in C.vill:
				if not is_same(v.lastItem, it) and v.eatTarget == null and v.stun <= 0 and dst(v, it) < 150:
					v.lastItem = it
					if randf() < .55: v.eatTarget = it
	C.items = C.items.filter(func(it): return not it.got and it.t < (11 if it.k == "simit" else 8))

func chase_extras(dt: float, busy: bool) -> void:
	if not busy:
		if WX == "lodos":
			C.gustT -= dt
			if C.gustT <= 0:
				C.gustT = randf_range(8, 12); C.gust = {"t": 1.4, "dir": -1.0 if randf() < .5 else 1.0}; pop_text(W / 2, 120, "LODOS ESTİ!", "#dfe6e9", 34); Snd.play("rumble"); news("Lodos mahalleyi savurdu. Bir kavuk Kadıköy'e kadar uçtu.")
		if C.kinci != null and not C.kinciDone and C.t > 9: spawn_kinci()
		C.winT -= dt
		if C.winT <= 0 and ARENA.wins.size() > 0:
			C.winT = randf_range(5, 9)
			var w: Dictionary = choice(ARENA.wins)
			say({"x": w.x, "y": w.y - 14, "vo": choice(["teyze", "amca", "hanim"])}, choice(D.WIN_L), 1.6, -14)
		if C.zone == 0:
			for o in OBST:
				if o.k == "kahve":
					if not o.has("m1"):
						o["m1"] = {"x": o.x - 24, "y": o.y - 4, "vo": "amca"}; o["m2"] = {"x": o.x + 26, "y": o.y - 4, "vo": "balikci"}
					C.kahveT -= dt
					if C.kahveT <= 0:
						C.kahveT = randf_range(6, 10); say(choice([o.m1, o.m2]), choice(D.KAHVE_L), 2, -78)
		if C.zone < 2 and randf() < dt * .12:
			Snd.play("squawk"); pop_text(C.gullX, 70, "GAK! İMDAT!", "#fff", 15, .8)
	C.kahveCheer -= dt
	if C.gust != null:
		var g: Dictionary = C.gust
		g.t -= dt
		var f: float = g.dir * 150 * dt
		if P.flyT <= 0 and not C.lose: P.x += f * .8
		for v in C.vill: v.x += f
		for it in C.items: it.x = clamp(it.x + f * .6, 40, 920)
		if randf() < .4: add_p({"type": "dust", "x": 0.0 if g.dir > 0 else W, "y": randf_range(150, 520), "vx": g.dir * 520, "vy": 0.0, "life": .9, "size": 4.0, "color": "rgba(255,255,255,.6)"})
		if g.t <= 0: C.gust = null

func upd_win(dt: float) -> void:
	var e: Dictionary = C.e
	var u: Dictionary = C.ulak
	e.t += dt
	if not u.arrived:
		u.y += 170 * dt
		if u.y >= u.ty:
			u.y = u.ty; u.arrived = true
	once(e, .6, func():
		say(u, "DURUUUUUN!", 1.6, -95, 3); Snd.play("yell")
		for v in C.vill:
			v.vx *= .2; v.vy *= .2)
	once(e, 2.0, func(): say(u, "Padişah'tan FERMAN var!", 2, -95, 3); Snd.play("fanfare"))
	once(e, 3.6, func():
		var near: Array = C.vill.duplicate()
		near.sort_custom(func(a, b): return dst(a, P) < dst(b, P))
		if near.size() > 0: say(near[0], "Ferman mı?!", 1.6, -88, 3)
		if near.size() > 1: near[1].pend = {"t": .4, "text": "Kimin için?!"}
		say(P, "Oh be!", 1.6, -100))
	if e.t > 5.6: start_saray()

func upd_lose(dt: float) -> void:
	var e: Dictionary = C.e
	var cl: Dictionary = C.cloud
	e.t += dt; cl.pt -= dt
	if cl.pt <= 0 and e.t < 3.2:
		cl.pt = .12; Snd.play("bonk" if randf() < .8 else "yell")
		pop_text(cl.x + randf_range(-60, 60), cl.y - randf_range(40, 110), choice(["PAT!", "KÜT!", "ŞAP!", "TAK!", "ÇAT!", "BAM!", "ŞIRAK!"]), choice(["#ffdd33", "#ff6b6b", "#7bed9f", "#74b9ff"]), randf_range(24, 38), .6)
		dust(cl.x + randf_range(-50, 50), cl.y, 2); shake = max(shake, 5.0)
	if e.t < 3.2:
		if C.cause == "terlik" and randf() < .35: add_p({"type": "terlik", "x": cl.x + randf_range(-90, 90), "y": cl.y - 260, "vy": 520.0, "g": 300.0, "life": .55, "rot": randf_range(0, 6), "vr": 10.0})
		elif C.cause == "karpuz" and randf() < .25: add_p({"type": "melon", "x": cl.x + randf_range(-40, 40), "y": cl.y - 60, "vx": randf_range(-200, 200), "vy": randf_range(-380, -200), "g": 700.0, "life": 1.0, "size": 9.0, "vr": randf_range(-8, 8)})
		elif C.cause == "havlu" and randf() < .3: add_p({"type": "dot", "x": cl.x + randf_range(-60, 60), "y": cl.y - randf_range(30, 90), "vx": randf_range(-200, 200), "vy": randf_range(-100, 50), "life": .5, "size": 4.0, "color": "#fff"})
	once(e, 1.6, func():
		if C.cause == "boss":
			C.stamp = 1; Snd.play("stamp"); shake = 20.0)
	once(e, 3.3, func(): Snd.play("sad"))
	if e.t > 4.6: start_end(false)

# ---------------------------------------------------------------- saray
func start_saray() -> void:
	state = "saray"; Snd.music("saray"); bubbles = []; texts = []; parts = []; flash = 1.0
	var qs: Array = D.SQ.duplicate()
	qs.shuffle()
	var sel: Array = []
	for q in qs.slice(0, 3):
		var a: Array = q.a.duplicate()
		a.shuffle()
		sel.append({"q": q.q, "a": a})
	SR = {"t": 0.0, "pt": 0.0, "qi": 0, "qs": sel, "phase": "intro", "score": 0, "sel": 0, "ans": -1, "val": -1, "reacted": 0, "laugh": 0.0, "ok": false,
		"pad": {"x": 700.0, "y": 352.0, "vo": "padisah"}, "vez": {"x": 830.0, "y": 352.0, "vo": "ulak"}, "hz": {"x": 250.0, "y": 352.0, "vo": "hez"}}
	say(SR.pad, "Demek uçan adam sensin! Anlat bakalım...", 2.6, -180, 3)

func opt_box(i: int) -> Rect2:
	return Rect2(90, 404 + i * 42, 780, 36)

func saray_ask() -> void:
	SR.sel = 0; SR.ans = -1; SR.val = -1; SR.reacted = 0; SR.phase = "q"; SR.pt = 0.0
	say(SR.pad, SR.qs[SR.qi].q, 2.6, -180, 3)

func saray_answer(a: int) -> void:
	var q: Dictionary = SR.qs[SR.qi]
	SR.ans = a; SR.phase = "react"; SR.pt = 0.0; Snd.play("pop")
	if a >= 0:
		SR.val = q.a[a][1]; SR.score += SR.val; say(SR.hz, q.a[a][0], 1.8, -180, 3)
	else:
		SR.val = 0; say(SR.hz, "Eee... bilim?", 1.6, -180, 3)

func upd_saray(dt: float) -> void:
	var S := SR
	S.t += dt; S.pt += dt; S.laugh -= dt
	match S.phase:
		"intro":
			if S.pt > 2.8 or (S.pt > .5 and (hit(["Space", "Enter"]) or ptr.tap)): saray_ask()
		"q":
			if hit(["ArrowUp", "KeyW"]): S.sel = (S.sel + 2) % 3; Snd.play("pop")
			if hit(["ArrowDown", "KeyS"]): S.sel = (S.sel + 1) % 3; Snd.play("pop")
			var a := -1
			for i in 3:
				if hit(["Digit%d" % (i + 1)]): a = i
			if hit(["Space", "Enter"]): a = S.sel
			if ptr.tap:
				for i in 3:
					if opt_box(i).has_point(Vector2(ptr.x, ptr.y)): a = i
			if a >= 0: saray_answer(a)
			elif S.pt > 12: saray_answer(-1)
		"react":
			if S.pt > 1.3 and not S.reacted:
				S.reacted = 1
				var q: Dictionary = S.qs[S.qi]
				say(S.pad, "Cevap yok mu? Hıh." if S.ans < 0 else q.a[S.ans][2], 2.2, -180, 3)
				if S.val == 2:
					S.laugh = 2.2; Snd.play("laugh"); shake = 6.0
					for i in 5: pop_text(S.pad.x + randf_range(-90, 60), S.pad.y - randf_range(160, 230), choice(["HA HA!", "HA HA HA!", "KAH KAH!"]), "#ffd166", randf_range(20, 30), 1.3)
				elif S.val == 0: Snd.play("gasp")
			if S.pt > 3.9:
				S.qi += 1
				if S.qi >= S.qs.size():
					S.phase = "verdict"; S.pt = 0.0; S.ok = S.score >= 4; stats.saray = 1 if S.ok else 0
					say(S.pad, "HA HA! Bu adam beni çok güldürdü! Bir kese altın daha verin!" if S.ok else "Hmm... Bilim güzel ama... Cezayir de güzeldir!", 3.2, -180, 3)
					Snd.play("fanfare" if S.ok else "sad")
					if S.ok: S.laugh = 3.0
				else:
					saray_ask()
		"verdict":
			if S.pt > 3.6 or (S.pt > 1.2 and (hit(["Space", "Enter"]) or ptr.tap)):
				C.saray = {"ok": S.ok, "score": S.score}; start_end(true)

# ---------------------------------------------------------------- son ekranı
func saray_story() -> Array:
	var s = C.saray
	if s == null: return R.win
	if s.ok:
		if D.save_data.route == 0:
			return ["Sultan IV. Murad kahkahayı bastı ve bir kese altın verdi...", "...sürgünü de \"şimdilik\" erteledi.", "(Cezayir rotası yine de açık. Ne olur ne olmaz.)"]
		return [R.win[0], "Huzurdaki konuşman padişahı öyle güldürdü ki bir kese altın daha geldi!"]
	return [R.win[0], R.win[1], "Huzurdaki konuşman pek beğenilmedi. Hediye olarak bir terlik verildi."]

func start_end(win: bool) -> void:
	state = "end"; Snd.music("end")
	var surv: float = min(SURV, C.t)
	stats.surv = surv
	var win_bonus := 0
	if win:
		win_bonus = 2000 + ((1500 if C.saray.ok else 300) if C.saray != null else 0)
	var mult: float = D.wing().mult
	var total := int(round(max(0.0, stats.score + round(stats.dist * .3) + round(surv * 30) + win_bonus) * mult))
	var prev := int(D.save_data.best)
	var is_best := total > prev
	if is_best: D.save_data.best = total
	if win: D.save_data.wins[str(D.save_data.route)] = 1
	var akce := award(total)
	var cause: String = C.cause
	var lose_story: String = {"terlik": "Son terlik tam ensene geldi. Teyze o gün mahallenin keskin nişancısı ilan edildi.", "karpuz": "Bir karpuz arabası tarafından devrildin. Karpuzcu hâlâ arabasını arıyor.",
		"boss": "%s dilekçeni reddetti ve üstüne kocaman bir mühür bastı." % R.boss.n, "havlu": "Hamamcının ıslak havlusu o gün tarihe \"Islak Kırbaç\" olarak geçti."}.get(cause,
		choice(["Hezarfen o gün bir kez daha uçtu: mahallenin bir ucundan öbür ucuna.", "Hezarfen bir hafta kanatla değil, sedyeyle taşındı.", "Mahallelinin dayak tekniği o gün tarihe geçti."]))
	var rank := ""
	for r in D.RANKS:
		if total < r[0]:
			rank = r[1]; break
	E = {"win": win, "t": 0.0, "total": total, "akce": akce, "mult": mult, "best": max(prev, total), "isBest": is_best, "rank": rank,
		"title": "FERMAN GELDİ!" if win else LOSE_T.get(cause, LOSE_T.dayak), "story": saray_story() if win else [lose_story, "Ama tarih onu yine de yazdı. Şalvar sahibine iade edildi."]}
	D.save()
	if win: Snd.play("fanfare")

func upd_end(dt: float) -> void:
	E.t += dt
	if E.t > 1.6 and (hit(["Space", "Enter"]) or ptr.tap): start_flight()

# ---------------------------------------------------------------- çizim
func draw_other() -> void:
	match state:
		"chase": draw_chase(); draw_chase_hud()
		"end": draw_chase(); draw_end_ui()
		"saray": draw_saray()

func draw_vill(v: Dictionary) -> void:
	if v.inCloud: return
	var d: Dictionary = v.d
	var s: float = .95 * float(d.get("s", 1.0))
	var arm: float = -2.4 + sin(v.ph * .8) * .5
	var mood := "angry"
	var shout: float = (.5 + sin(T * 20) * .5) if has_bubble(v) else 0.0
	var rot := 0.0
	var run: float = min(1.0, Vector2(v.vx, v.vy).length() / 80)
	var z: float = v.z
	var item = d.get("item", null)
	if C.win:
		mood = "surprised"; arm = 0; shout = .7 if has_bubble(v) else 0.0
	elif v.stun > 0:
		mood = "dizzy"; arm = .4; run = 0; rot = v.rotA if v.z > 0 else (1.45 if v.flat else sin(T * 18) * .2)
	elif v.dance > 0:
		mood = "happy"; arm = -2.9 + sin(T * 10) * .2; z += abs(sin(T * 10)) * 6; run = .6
	elif v.eat > 0:
		mood = "happy"; arm = -1.4 + sin(T * 14) * .2; item = null; run = 0
	elif v.gloat > 0:
		mood = "happy"; arm = -2.9 + sin(T * 30) * .3
	elif v.wind > 0:
		arm = -3.1
	if v.has("boss") and not C.win and not C.lose and v.stun <= 0:
		if v.boss.st == "aim":
			c.save(); c.set_stroke("rgba(231,76,60,.85)"); c.lw = 6; c.begin_path(); c.move_to(v.x, v.y - 8); c.line_to(v.x + v.boss.ax * 280, v.y - 8 + v.boss.ay * 280); c.stroke_dashed(14, 9); c.restore()
			c.txt("!", v.x, v.y - 165, 44, "#ff4757"); arm = -2.9
		elif v.boss.st == "charge":
			rot = .25 * v.f; run = 1
	var o := d.duplicate()
	o.merge({"s": s, "f": v.f, "ph": v.ph, "run": run, "arm": arm, "mood": mood, "shout": shout, "rot": rot, "z": z, "item": item}, true)
	art.draw_person(v.x, v.y, o)
	if v.has("boss") and not C.lose: c.txt(R.boss.n, v.x, v.y - z - 152, 12, "#ffd166", "center", OL, 3)
	if v.get("kinci", false) and not C.lose and not C.win:
		c.txt("KİNCİ " + str(D.NAMES[v.type]).to_upper(), v.x, v.y - z - 108 * s, 11, "#ff6b6b", "center", OL, 3)
		var hx: float = v.x + v.f * 4
		var hy: float = v.y - z - 66 * s
		c.set_stroke("#e74c3c"); c.lw = 2.5
		for e in [[-4, -2, -1, -5], [1, -5, 4, -2], [-4, 2, -1, 5], [1, 5, 4, 2]]: c.ln(hx + e[0], hy + e[1], hx + e[2], hy + e[3])
	if v.eat > 0: art.draw_simit(v.x + v.f * 12, v.y - z - 44, .45)
	if v.stun > 0 and not C.win:
		for kk in 3:
			var a := T * 6 + kk * TAU_ / 3
			c.star(v.x + cos(a) * 14, v.y - z - (22 if v.flat else 66) * s + sin(a) * 4, 5, a, "#ffe066")

func draw_player_c() -> void:
	if C.cloud != null: return
	c.save()
	if P.inv > 0 and P.flyT <= 0 and int(floor(T * 16)) % 2 == 0: c.alpha = .4
	var sp := Vector2(P.vx, P.vy).length()
	var run: float = min(1.0, sp / 120)
	var wa := -1.05 + sin(T * 18) * .15 * run
	var wl := 42.0
	var mood := "scared" if P.inv > 0 else "normal"
	var o := {"s": .95, "f": P.f, "ph": P.ph, "run": run, "salvar": P.salvar, "shout": .6 if has_bubble(P) else 0.0}
	var rot := 0.0
	if P.flyT > 0:
		wa = .3 + sin(T * 22) * .8; wl = 56; mood = "happy"
	if P.dashT > 0: rot = .3
	if P.trip > 0: rot = -.3
	if P.dance > 0:
		o["arm"] = -2.9; mood = "happy"
	if P.z > 0: rot = P.z * .03
	o.merge({"wa": wa, "wl": wl, "mood": mood, "rot": rot, "z": P.z + P.fz}, true)
	art.draw_person(P.x, P.y, D.hez_opts(o))
	c.restore()
	if P.foam > 0:
		var hx: float = P.x + P.f * 8
		var hy: float = P.y - P.z - P.fz - 50
		for e in [[0, 0, 7], [6 * P.f, 4, 6], [-5 * P.f, 5, 5], [3 * P.f, -6, 5], [9 * P.f, -2, 4]]: c.circ(hx + e[0], hy + e[1], e[2], "#fff")
	elif P.wet > 0:
		c.set_fill("rgba(116,185,255,.5)")
		for i in 3: c.circ(P.x - 8 + i * 8, P.y - P.fz - 70 + fmod(T * 80 + i * 13, 30), 2)

func draw_cat(ct: Dictionary) -> void:
	c.save(); c.translate(ct.x, ct.y); c.scale(1 if ct.vx > 0 else -1, 1)
	var l: float = sin(ct.ph) * 4
	c.set_stroke(ct.col); c.lw = 3; c.ln(-6, -6, -6 + l, 0); c.ln(6, -6, 6 - l, 0)
	c.set_stroke(OL); c.lw = 1.5; c.ell(0, -9, 11, 6, ct.col); c.stroke(); c.circ(11, -14, 6, ct.col); c.stroke()
	c.begin_path(); c.move_to(7, -18); c.line_to(8, -25); c.line_to(11, -19); c.close_path(); c.fill(ct.col); c.stroke()
	c.begin_path(); c.move_to(12, -19); c.line_to(15, -25); c.line_to(16, -17); c.close_path(); c.fill(); c.stroke()
	c.set_stroke(ct.col); c.lw = 3; c.begin_path(); c.move_to(-10, -10); c.quad_to(-20, -14, -17, -24 + sin(ct.ph * .5) * 3); c.stroke()
	c.circ(13, -15, 1.6, "#2ecc71")
	c.restore()

func draw_cart(cr: Dictionary) -> void:
	c.save(); c.translate(cr.x, cr.y); c.scale(cr.dir, 1)
	c.set_stroke("#7a5230"); c.lw = 4; c.ln(-50, -30, -80, -36); c.set_stroke(OL); c.lw = 2
	for wx in [-30, 30]:
		c.circ(wx, -12, 13, "#7a5230"); c.stroke(); c.save(); c.translate(wx, -12); c.rotate(T * 20); c.ln(-12, 0, 12, 0); c.ln(0, -12, 0, 12); c.restore()
	c.fill_rect(-50, -40, 100, 20, "#a0703a"); c.stroke_rect(-50, -40, 100, 20)
	for e in [[-32, -48], [-10, -50], [12, -48], [34, -47], [-21, -62], [1, -64], [23, -61], [-8, -76], [12, -76]]:
		var mx: float = e[0]
		var my: float = e[1]
		c.ell(mx, my, 12, 10, "#2e8b57"); c.set_stroke(OL); c.lw = 1.5; c.stroke(); c.set_stroke("#1e5e3a"); c.lw = 2; c.ln(mx - 6, my - 7, mx - 6, my + 7); c.ln(mx + 2, my - 9, mx + 2, my + 9)
	c.restore()
	art.draw_person(cr.owner.x, cr.owner.y, {"body": "#27ae60", "sleeve": "#1e8449", "hat": "fes", "must": "#222", "s": .95, "f": cr.dir, "run": 1.0, "ph": T * 16, "arm": -2.7 + sin(T * 14) * .3, "mood": "scared", "shout": 1.0})

func draw_mini(m: Dictionary) -> void:
	art.shadow(m.x, m.y, 13)
	art.draw_person(m.x, m.y, {"body": "#8e44ad", "sleeve": "#6c3483", "hat": "cap", "capc": "#c0392b", "must": "#222", "s": .95, "f": 1.0, "arm": -1.4 + sin(T * 10) * .3, "mood": "happy" if m.done else "smile", "shout": .6 if has_bubble(m) else 0.0})
	var ex: float = m.x + 30
	c.set_stroke("#6e4b2a"); c.lw = 3; c.ln(ex - 12, m.y, ex, m.y - 70); c.ln(ex + 12, m.y, ex, m.y - 70); c.ln(ex, m.y - 70, ex + 4, m.y + 2)
	c.set_stroke(OL); c.lw = 2; c.fill_rect(ex - 18, m.y - 74, 36, 30, "#fdf6e3"); c.stroke_rect(ex - 18, m.y - 74, 36, 30)
	var n := int(floor(clamp(m.t / 5, 0, 1) * 6))
	var cols := ["#c0392b", "#2980b9", "#f1c40f", "#27ae60", "#e67e22", "#8e44ad"]
	for i in n: c.circ(ex - 12 + (i % 3) * 12, m.y - 66 + int(i / 3) * 12, 4, cols[i])
	if not m.done: art.bar(m.x - 30, m.y - 118, 60, 8, clamp(m.t / 5, 0, 1), "#e3b23c")

func draw_portrait(p: Dictionary) -> void:
	var x := 20.0
	var y := 60.0
	var w := 120.0
	var h := 140.0
	var k: float = min(1.0, (3.6 - p.t) * 5)
	c.save(); c.translate(x + w / 2, y + h / 2); c.scale(k, k); c.translate(-x - w / 2, -y - h / 2)
	c.rr(x - 6, y - 6, w + 12, h + 12, 6); c.fill("#d4ac0d"); c.set_stroke(OL); c.lw = 2; c.stroke(); c.fill_rect(x, y, w, h - 24, "#f6e7c8"); c.stroke_rect(x, y, w, h - 24)
	c.save(); c.begin_path(); c.rect(x, y, w, h - 24); c.clip()
	if p.ok:
		art.draw_person(x + w / 2 + 8, y + h - 34, D.hez_opts({"s": .82, "f": 1.0, "wa": .4, "wl": 56.0, "mood": "happy", "salvar": true, "arm": -2.7}))
	else:
		c.set_stroke("#6e4b2a"); c.lw = 3; c.ell(x + w / 2, y + 60, 32, 16, "#a0522d"); c.stroke()
		c.ln(x + w / 2 - 24, y + 70, x + w / 2 - 26, y + 100); c.ln(x + w / 2 - 10, y + 72, x + w / 2 - 10, y + 100); c.ln(x + w / 2 + 12, y + 72, x + w / 2 + 12, y + 100); c.ln(x + w / 2 + 24, y + 70, x + w / 2 + 26, y + 100)
		c.ell(x + w / 2 + 38, y + 42, 12, 9, "#a0522d"); c.stroke(); c.ln(x + w / 2 - 32, y + 56, x + w / 2 - 46, y + 74)
	c.restore()
	c.txt("Başyapıt!" if p.ok else "At gibi...", x + w / 2, y + h - 11, 14, "#4a2c17", "center", null)
	c.restore()

func draw_ticker() -> void:
	var y := H - 24
	c.fill_rect(0, y, W, 24, "rgba(20,10,5,.8)")
	if C.tk != null: c.txt(C.tk.t, C.tk.x, y + 13, 15, "#ffe066", "left", null)
	c.fill_rect(0, y, 124, 24, "#c0392b"); c.fill_rect(124, y, 4, 24, "#1a0e06"); c.fill_rect(W - 48, y, 48, 24, "#1a0e06")
	c.txt("SON DAKİKA", 62, y + 12, 13, "#fff", "center", null)

func draw_stamp() -> void:
	var k: float = 2.2 - 1.2 * min(1.0, (C.e.t - 1.6) * 6)
	c.save(); c.translate(W / 2, H / 2 - 30); c.rotate(-.18); c.scale(k, k); c.alpha = .9
	c.set_stroke("#c0392b"); c.lw = 8; c.rr(-200, -50, 400, 100, 12); c.stroke(); c.lw = 3; c.rr(-188, -38, 376, 76, 8); c.stroke(); c.txt("MÜHÜRLENDİ", 0, 4, 56, "#c0392b", "center", null)
	c.restore()

func draw_cloud_fight(cl: Dictionary) -> void:
	var t := T
	c.save(); c.translate(cl.x, cl.y - 35)
	for i in 8:
		var a := i * TAU_ / 8 + sin(t * 9 + i) * .6
		var L := 60 + sin(t * 13 + i * 3) * 14
		c.set_stroke("#f1c27d" if i % 2 else "#5a3b22"); c.lw = 7; c.ln(0, 0, cos(a) * L, sin(a) * L * .7)
		c.save(); c.translate(cos(a) * L, sin(a) * L * .7); c.rotate(a + PI / 2)
		if i % 3 == 0: art.draw_terlik_shape()
		elif i % 3 == 1:
			c.set_stroke("#e2c08d"); c.lw = 5; c.ln(0, -12, 0, 12)
		else: c.circ(0, 0, 6, "#6b2d14")
		c.restore()
	for i in 10:
		var a := i * TAU_ / 10 + t * 3
		var r := 28 + sin(t * 7 + i) * 6
		c.circ(cos(a) * r * 1.4, sin(a) * r * .6, 32 + sin(t * 11 + i * 2) * 6, "#f2ece0" if i % 2 else "#d9d1c3")
	if sin(t * 5) > .3:
		c.ell(sin(t * 3) * 20, -34, 15, 10, "#fbf6e9"); c.set_stroke(OL); c.lw = 2; c.stroke(); c.ell(sin(t * 3) * 20, -44, 6, 4, "#c0392b")
	for kk in 4:
		var a := t * 7 + kk * TAU_ / 4
		c.star(cos(a) * 70, -50 + sin(a) * 20, 7, a, "#ffe066")
	c.restore()

func draw_chase_deco() -> void:
	if C.zone < 2:
		var y0 := 58.0
		var ly := func(x: float) -> float:
			var t := (x - 40) / (W - 80)
			return (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * (y0 + 26) + t * t * y0
		c.set_stroke("#ddd"); c.lw = 1.5; c.begin_path(); c.move_to(40, y0); c.quad_to(W / 2, y0 + 52, W - 40, y0); c.stroke()
		var cl := ["#e74c3c", "#3498db", "#f1c40f", "#ecf0f1", "#9b59b6", "#ff8cc6", "#2ecc71"]
		for i in 9:
			var x := 110.0 + i * 88
			if abs(x - C.gullX) < 34: continue
			var y: float = ly.call(x)
			var sw := sin(T * 3 + i) * (.45 if WX == "lodos" else .12)
			c.save(); c.translate(x, y); c.rotate(sw); c.set_fill(cl[i % cl.size()]); c.set_stroke(OL); c.lw = 1.2
			if i % 3 == 0:
				c.fill_rect(-8, 0, 16, 20); c.stroke_rect(-8, 0, 16, 20)
			elif i % 3 == 1:
				c.begin_path(); c.move_to(-10, 0); c.line_to(10, 0); c.line_to(13, 8); c.line_to(7, 8); c.line_to(7, 22); c.line_to(-7, 22); c.line_to(-7, 8); c.line_to(-13, 8); c.close_path(); c.fill(); c.stroke()
			else:
				c.ell(-5, 10, 5, 10); c.stroke(); c.ell(5, 10, 5, 10); c.stroke()
			c.restore()
		var gx: float = C.gullX
		c.save(); c.translate(gx, ly.call(gx) + 14); c.rotate(PI + sin(T * 5) * .25); art.draw_gull(0, 0, 1, T * 1.6, 0); c.restore()
	var wins: Array = ARENA.wins
	for i in wins.size():
		var w: Dictionary = wins[i]
		var ph := fmod(T * .22 + i * .37, 1.0)
		if ph > .3: continue
		var k := sin(ph / .3 * PI)
		var hy: float = w.y - 2 - k * 16
		c.save(); c.begin_path(); c.rect(w.x - 11, w.y - 26, 22, 26); c.clip()
		c.circ(w.x, hy, 8, "#f3c9a0"); c.set_stroke(OL); c.lw = 1.2; c.stroke()
		if i % 2:
			c.set_stroke(["#e74c3c", "#16a085", "#f1c40f"][i % 3]); c.lw = 4; c.begin_path(); c.arc(w.x, hy, 8.5, PI * 1.05, PI * 1.95); c.stroke()
		else:
			c.fill_rect(w.x - 5, hy - 15, 10, 8, "#c0392b")
		var lx: float = clamp((P.x - w.x) / 200, -1, 1) * 2
		c.circ(w.x - 3 + lx, hy - 1, 1.3, "#111"); c.circ(w.x + 3 + lx, hy - 1, 1.3, "#111")
		c.restore()

func draw_chase() -> void:
	if ARENA.has("tex"):
		c.image(ARENA.tex, 0, 0, W, H)
	if WX == "kar": c.fill_rect(0, 124, W, H - 124, "rgba(255,255,255,.28)")
	draw_chase_deco()
	for h in C.haz:
		if not h.done and h.get("win") != null:
			var w: Dictionary = h.win
			c.circ(w.x, w.y - 12, 8, "#f3c9a0"); c.set_stroke(OL); c.lw = 1.5; c.stroke(); c.set_stroke("#e74c3c"); c.lw = 4; c.begin_path(); c.arc(w.x, w.y - 12, 9, PI * 1.05, PI * 1.95); c.stroke()
			c.save(); c.translate(w.x + 10, w.y - 4); c.rotate(1.6 if h.t > h.warn - .6 else .3); c.fill_rect(-6, -8, 12, 12, "#95a5a6"); c.set_stroke(OL); c.lw = 1.5; c.stroke_rect(-6, -8, 12, 12); c.restore()
	for h in C.haz:
		if h.done:
			c.save(); c.alpha = clamp(h.puddle / 2, 0, 1) * .55; c.ell(h.x, h.y, h.r * .85, h.r * .45, "#5dade2"); c.restore()
		else:
			var k: float = h.t / h.warn
			c.save(); c.alpha = .25 + k * .35; c.ell(h.x, h.y, h.r, h.r * .55, "#e74c3c"); c.restore()
			c.set_stroke("#c0392b"); c.lw = 3; c.begin_path(); c.ellipse(h.x, h.y, h.r, h.r * .55, 0, 0, TAU_); c.stroke_dashed(8, 6)
			c.begin_path(); c.ellipse(h.x, h.y, h.r * (1 - k) + 2, h.r * .55 * (1 - k) + 1, 0, 0, TAU_); c.stroke(); c.txt("!", h.x, h.y, 22, "#fff")
	if C.cart != null and C.cart.warn > 0 and int(floor(T * 8)) % 2 == 0:
		c.fill_rect(0, C.cart.y - 30, W, 60, "rgba(231,76,60,.3)")
		for i in 6: c.txt("»" if C.cart.dir > 0 else "«", 80 + i * 160, C.cart.y, 30, "#fff")
	for it in C.items:
		var blink: bool = it.t > (9 if it.k == "simit" else 6) and int(floor(T * 8)) % 2 == 0
		if blink: continue
		if it.k == "simit":
			art.shadow(it.x, it.y, 10); art.draw_simit(it.x, it.y - 6, .8)
		else:
			c.circ(it.x, it.y - 26, 20 + sin(T * 6) * 4, "rgba(255,255,200,.45)"); art.shadow(it.x, it.y, 9); art.draw_feather(it.x, it.y - 26 + sin(T * 3) * 5, .9)
	for v in C.vill:
		if not v.inCloud: art.shadow(v.x, v.y, v.r, v.z)
	if C.cloud == null: art.shadow(P.x, P.y, P.r, P.z + P.fz)
	for ct in C.cats: art.shadow(ct.x, ct.y, 9)
	var list: Array = []
	for o in OBST: list.append([o.y, draw_obst.bind(o)])
	for v in C.vill: list.append([v.y, draw_vill.bind(v)])
	list.append([P.y, draw_player_c])
	for ct in C.cats: list.append([ct.y, draw_cat.bind(ct)])
	if C.cart != null and C.cart.warn <= 0: list.append([C.cart.y, draw_cart.bind(C.cart)])
	if C.halay != null:
		var h: Dictionary = C.halay
		for i in 5:
			list.append([h.y + i * .01, draw_halay_member.bind(h, i)])
	if C.ulak != null: list.append([C.ulak.y, draw_ulak.bind(C.ulak)])
	if C.cloud != null: list.append([C.cloud.y, draw_cloud_fight.bind(C.cloud)])
	if C.mini != null: list.append([C.mini.y, draw_mini.bind(C.mini)])
	list.sort_custom(func(a, b): return a[0] < b[0])
	for e in list: e[1].call()
	for p in C.proj:
		art.shadow(p.x, p.y, 6)
		c.save(); c.translate(p.x, p.y - p.z); c.rotate(p.rot)
		match p.k:
			"kopuk":
				c.rotate(-p.rot)
				for e in [[0, 0, 8], [7, 3, 6], [-6, 4, 6], [2, -6, 6]]: c.circ(e[0], e[1], e[2], "#fff")
				c.set_stroke("rgba(0,0,0,.25)"); c.lw = 1; c.begin_path(); c.arc(0, 0, 9, 0, TAU_); c.stroke()
			"kartopu":
				c.circ(0, 0, 7, "#fff"); c.set_stroke("#9fb3c8"); c.lw = 1.5; c.stroke()
			"tespih":
				for i in 10:
					var a := i / 10.0 * TAU_
					c.circ(cos(a) * 9, sin(a) * 9, 2.6, "#16a085")
				c.circ(9, 0, 3.5, "#d4ac0d")
			_:
				if p.homing: c.circ(0, 0, 14, "rgba(255,80,80,.4)")
				art.draw_terlik_shape()
		c.restore()
	draw_parts(0); draw_texts(0); draw_bubbles(0)
	draw_weather()
	if C.stamp: draw_stamp()

func draw_halay_member(h: Dictionary, i: int) -> void:
	var x: float = h.x - h.dir * i * 34
	art.shadow(x, h.y, 12)
	art.draw_person(x, h.y, {"body": ["#e74c3c", "#f1c40f", "#9b59b6", "#1abc9c", "#e67e22"][i], "sleeve": "#444", "hat": "scarf" if i % 2 else "fes", "scarf": "#fff", "must": null if i % 2 else "#222", "s": .95, "f": h.dir, "run": .8, "ph": T * 8 + i,
		"arm": -2.6 + sin(T * 8 + i) * .15, "item": "mendil" if i == 0 else null, "mood": "happy", "z": abs(sin(T * 8 + i)) * 5})

func draw_ulak(u: Dictionary) -> void:
	art.shadow(u.x, u.y, 13)
	var o := {"body": "#c0392b", "sleeve": "#922b21", "sash": "#f1c40f", "hat": "ulak", "item": "ferman", "must": "#222", "s": 1.0, "f": 1.0, "run": 0.0 if u.arrived else 1.0, "ph": T * 14, "shout": .8 if has_bubble(u) else 0.0, "mood": "angry"}
	if u.arrived: o["arm"] = -2.7
	art.draw_person(u.x, u.y, o)

func draw_pick() -> void:
	var p: Dictionary = C.pick
	c.fill_rect(0, 0, W, H, "rgba(20,10,5,.7)")
	var k: float = min(1.0, p.t * 4)
	c.txt("GÜÇLENDİRME SEÇ!", W / 2, 100, 40, "#ffd166", "center", OL, 7); c.txt("Mahalle seni bekliyor... ama önce cebine bir şey koy.", W / 2, 135, 16, "#fff", "center", OL, 3)
	for i in p.o.size():
		var o: Dictionary = p.o[i]
		var x := pick_x(i)
		var sel: bool = i == p.sel
		var y := 165 - (10 if sel else 0) + (1 - k) * 60
		c.save(); c.alpha = k
		c.rr(x, y, 210, 230, 16); c.fill("#fff3d6" if sel else "#e9d6ad"); c.lw = 5 if sel else 3; c.set_stroke("#e3b23c" if sel else OL); c.stroke()
		c.txt(o.ic, x + 105, y + 62, 54, "#fff", "center", null)
		c.txt(o.n, x + 105, y + 118, 20, "#8a3b12", "center", null)
		var ls := c.wrap(o.d, 180, 15)
		for j in ls.size(): c.txt(ls[j], x + 105, y + 150 + j * 20, 15, "#4a2c17", "center", null)
		c.txt("[%d]" % (i + 1), x + 105, y + 212, 14, "#8a5a2b", "center", null)
		c.restore()
	c.txt("A/D veya ←→: seç  •  SPACE/ENTER veya 1-2-3: al  •  karta tıkla", W / 2, H - 60, 15, "#fff", "center", OL, 3)

func draw_chase_hud() -> void:
	c.rr(12, 10, 24 + C.hpMax * 36, 40, 12); c.fill("rgba(30,20,10,.55)")
	for i in C.hpMax: art.kavuk_icon(38 + i * 36, 34, i < P.hp, .9)
	if C.perks.size() > 0 or C.shield:
		c.txt(" ".join(C.perks), 16, 68, 20, "#fff", "left", null)
		if C.shield: c.txt("Sini: %d" % C.shield, 22 + C.perks.size() * 28, 68, 13, "#ffd166", "left", OL, 3)
	var left: float = max(0.0, SURV - C.t)
	c.rr(W / 2 - 150, 10, 300, 44, 12); c.fill("rgba(30,20,10,.55)")
	c.txt("ULAK GELDİ!" if C.win else "ULAK GELİYOR: %d sn  •  %s" % [int(ceil(left)), ZN[C.zone]], W / 2, 24, 16, "#ffe066" if (left < 10 and not C.win) else "#fff")
	c.rr(W / 2 - 130, 36, 260, 9, 4); c.fill("rgba(0,0,0,.4)"); c.rr(W / 2 - 130, 36, max(1.0, 260 * clamp(C.t / SURV, 0, 1)), 9, 4); c.fill("#e3b23c")
	var live: int = stats.score + int(round(stats.dist * .3)) + int(round(min(C.t, SURV) * 30))
	c.txt("PUAN: %d" % live, W - 60, 26, 18, "#ffe066", "right")
	var k: float = 1.0 if P.dashCd <= 0 else 1.0 - P.dashCd / (1.25 * C.dashMul)
	art.bar(16, H - 56, 160, 20, k, "#2ecc71" if k >= 1 else "#95a5a6", "SPACE: KAÇ HAMLESİ!" if k >= 1 else "...")
	if D.save_data.hat == "tencere": c.txt("Tencere: ezildi" if C.potUsed else "Tencere: hazır", 186, H - 46, 12, "#aaa" if C.potUsed else "#dfe6e9", "left", OL, 3)
	if P.flyT > 0: c.txt("UÇUŞ: %.1f" % P.flyT, W / 2, 80, 22, "#fff3b0")
	if C.t < 8 and C.banner == null: c.txt("Ok tuşları/WASD: koş  •  SPACE: hızlı kaçış  •  Mahalleliyi birbirine çarptır!", W / 2, H - 38, 14, "#fff", "center", OL, 4)
	if C.portrait != null: draw_portrait(C.portrait)
	draw_ticker()
	if C.banner != null:
		var b: Dictionary = C.banner
		var t: float = b.t
		var x: float = lerp(-400.0, W / 2, t / .25) if t < .25 else (lerp(W / 2, W + 400, (t - 2.1) / .3) if t > 2.1 else W / 2)
		c.save(); c.translate(x, 190); c.rotate(-.03); c.txt(b.text, 0, 0, 46, "#ffd166", "center", OL, 8)
		if b.sub != "": c.txt(b.sub, 0, 40, 18, "#fff", "center", OL, 5)
		c.restore()
	if C.pick != null: draw_pick()

func draw_saray() -> void:
	var S := SR
	c.fill_rect(0, 0, W, H, "#f1e2bf")
	var x := 0
	while x < W:
		var y := 0
		while y < 96:
			var a := int((x + y) / 32) % 2
			c.fill_rect(x, y, 32, 32, "#1f6fa8" if a else "#f6f3ea"); c.circ(x + 16, y + 16, 7, "#f6f3ea" if a else "#1f6fa8"); c.circ(x + 16, y + 16, 2.5, "#c0392b")
			y += 32
		x += 32
	c.fill_rect(0, 96, W, 6, "#d4ac0d")
	for i in 4:
		var ax := 120.0 + i * 240
		c.begin_path(); c.move_to(ax - 38, 250); c.line_to(ax - 38, 160); c.arc(ax, 160, 38, PI, 0); c.line_to(ax + 38, 250); c.close_path(); c.fill("#7fb3d5"); c.set_stroke("#b9770e"); c.lw = 5; c.stroke()
		c.set_stroke("rgba(255,255,255,.5)"); c.lw = 2; c.ln(ax, 124, ax, 250); c.ln(ax - 38, 200, ax + 38, 200)
	c.fill_rect(0, 300, W, H - 300, "#a04000"); c.fill_rect(140, 300, W - 280, H - 300, "#c0392b"); c.set_stroke("#f1c40f"); c.lw = 3; c.stroke_rect(150, 306, W - 300, H - 312)
	c.set_stroke(OL); c.lw = 2; c.rr(640, 180, 120, 140, 14); c.fill("#d4ac0d"); c.stroke(); c.rr(655, 198, 90, 100, 10); c.fill("#8e44ad")
	c.begin_path(); c.arc(700, 180, 42, PI, 0); c.close_path(); c.fill("#d4ac0d"); c.stroke(); c.circ(700, 152, 8, "#c0392b"); c.stroke()
	for gx in [40, 920]: art.draw_person(gx, 336, {"s": 1.2, "f": 1.0 if gx < 480 else -1.0, "body": "#922b21", "sleeve": "#7b241c", "hat": "yenicer", "must": "#222", "item": "cop", "arm": -.2})
	var lg: bool = S.laugh > 0
	var bad: bool = (S.phase == "verdict" and not S.ok) or (S.val == 0 and S.reacted and S.phase == "react")
	art.draw_person(S.vez.x, S.vez.y, {"s": 1.3, "f": -1.0, "body": "#117a65", "sleeve": "#0e6655", "hat": "sarik", "sarikc": "#e8f8f5", "beard": "#ccc", "must": "#ccc", "item": "ferman", "mood": "happy" if lg else "smile", "arm": -.4, "shout": .6 if has_bubble(S.vez) else 0.0})
	art.draw_person(S.pad.x, S.pad.y, {"s": 1.55, "f": -1.0, "body": "#6c3483", "sleeve": "#5b2c6f", "sash": "#f1c40f", "hat": "sarik", "sarikc": "#fdfefe", "beard": "#3b2a1e", "must": "#3b2a1e", "mood": "happy" if lg else ("angry" if bad else "smile"),
		"shout": (.6 + sin(T * 20) * .3) if has_bubble(S.pad) else 0.0, "arm": (-2.6 + sin(T * 25) * .3) if lg else -.8, "rot": sin(T * 18) * .06 if lg else 0.0})
	var ho := {"s": 1.55, "f": 1.0, "mood": "scared" if bad else "smile", "salvar": true, "wa": -1.05, "wl": 46.0, "shout": .6 if has_bubble(S.hz) else 0.0}
	if has_bubble(S.hz): ho["arm"] = -2.2 + sin(T * 12) * .3
	art.draw_person(S.hz.x, S.hz.y, D.hez_opts(ho))
	draw_parts(0); draw_texts(0); draw_bubbles(0)
	c.txt("PADİŞAHIN HUZURUNDA", W / 2, 26, 28, "#ffd166", "center", OL, 6)
	c.rr(W / 2 - 150, 46, 300, 34, 14); c.fill("rgba(30,20,10,.65)"); c.txt("Padişahın keyfi:", W / 2 - 78, 63, 14, "#fff")
	for i in 6:
		var cx := W / 2 + 10 + i * 22
		c.circ(cx, 63, 8, "#f1c40f" if i < S.score else "rgba(255,255,255,.2)"); c.set_stroke(OL); c.lw = 1.5; c.stroke()
		if i < S.score:
			c.begin_path(); c.arc(cx, 64, 4, .2, PI - .2); c.stroke()
	if S.phase == "q" or S.phase == "react":
		var q: Dictionary = S.qs[S.qi]
		c.rr(70, 366, 820, 166, 14); c.fill("rgba(243,226,184,.96)"); c.set_stroke("#8a5a2b"); c.lw = 4; c.stroke()
		c.txt("Soru %d/3: %s" % [S.qi + 1, q.q], W / 2, 386, 18, "#4a2c17", "center", null)
		for i in 3:
			var b := opt_box(i)
			var chosen: bool = S.ans == i
			var sel: bool = S.phase == "q" and S.sel == i
			c.rr(b.position.x, b.position.y, b.size.x, b.size.y, 10)
			var fc := "rgba(255,255,255,.5)"
			if chosen: fc = ("#f9e79f" if S.val == 2 else ("#d5f5e3" if S.val == 1 else "#fadbd8")) if S.reacted else "#fff6dc"
			elif sel: fc = "#fff6dc"
			c.fill(fc); c.set_stroke("#e74c3c" if (sel or chosen) else "rgba(138,90,43,.6)"); c.lw = 3 if (sel or chosen) else 1.5; c.stroke()
			c.txt("%d)  %s" % [i + 1, q.a[i][0]], b.position.x + 18, b.position.y + 19, 16, "#4a2c17", "left", null)
			if chosen and S.reacted:
				c.txt("KAHKAHA!" if S.val == 2 else ("Fena değil" if S.val == 1 else "Hıh..."), b.position.x + b.size.x - 14, b.position.y + 19, 14, "#d35400" if S.val == 2 else ("#27ae60" if S.val == 1 else "#c0392b"), "right", null)
		if S.phase == "q":
			var k: float = max(0.0, 1 - S.pt / 12)
			c.rr(90, 396, max(1.0, 780 * k), 4, 2); c.fill("#e67e22")
	elif S.phase == "verdict" and S.pt > .6:
		var k: float = min(1.0, (S.pt - .6) * 4)
		c.save(); c.translate(W / 2, 445); c.scale(k, k); c.rotate(-.04); c.txt("SÜRGÜN İPTAL! +1500" if S.ok else "CEZAYİR'E SÜRGÜN! (+300)", 0, 0, 46, "#f1c40f" if S.ok else "#e74c3c", "center", OL, 8); c.restore()

func draw_end_ui() -> void:
	c.fill_rect(0, 0, W, H, "rgba(20,10,5,.55)")
	var k: float = min(1.0, E.t * 2.5)
	var oy: float = lerp(-520.0, 0.0, 1 - pow(1 - k, 3))
	c.save(); c.translate(0, oy)
	var x := 150.0
	var w := 660.0
	var y := 24.0
	var h := 492.0
	c.rr(x, y, w, h, 18); c.fill("#f3e2b8"); c.set_stroke("#8a5a2b"); c.lw = 6; c.stroke()
	c.rr(x + 12, y + 12, w - 24, h - 24, 12); c.set_stroke("rgba(138,90,43,.4)"); c.lw = 2; c.stroke()
	c.txt(E.title, W / 2, y + 50, 44, "#e3b23c" if E.win else "#e74c3c", "center", OL, 8)
	var sy := y + 92
	for i in E.story.size():
		var ls := c.wrap(E.story[i], 560, 16)
		if E.t > .5 + i * 1.1:
			c.save(); c.alpha = min(1.0, (E.t - .5 - i * 1.1) * 3)
			for j in ls.size(): c.txt(ls[j], W / 2, sy + j * 20, 16, "#4a2c17", "center", null)
			c.restore()
		sy += ls.size() * 20 + 4
	var rows := [["Rota", R.n], ["Uçuş mesafesi", "%d m" % stats.dist + (("  (yüz üstü iniş)" if stats.hard else "  (kusursuz iniş)") if stats.landed else "")], ["Hayatta kalma", "%.1f sn" % stats.surv], ["Sersemletilen mahalleli", str(stats.stuns)], ["Yenen dayak", str(stats.hits)], ["Yenen simit", str(stats.simits)]]
	for i in rows.size():
		var yy := y + 196 + i * 27
		c.fill_rect(x + 60, yy - 12, w - 120, 25, "rgba(138,90,43,.08)" if i % 2 else "rgba(138,90,43,.16)")
		c.txt(rows[i][0], x + 76, yy + 1, 16, "#4a2c17", "left", null); c.txt(rows[i][1], x + w - 76, yy + 1, 16, "#8a3b12", "right", null)
	c.txt("TOPLAM PUAN: %d" % E.total + ("  (x%s)" % E.mult if E.mult > 1 else ""), W / 2, y + 372, 32, "#ffd166", "center", OL, 6)
	c.txt("★ YENİ REKOR! ★" if E.isBest else "En iyi: %d" % E.best, W / 2, y + 404, 16, "#e74c3c" if E.isBest else "#8a5a2b", "center", null)
	c.txt("Unvanın: %s   •   +%d akçe (kese: %d)" % [E.rank, E.akce, D.save_data.akce], W / 2, y + 428, 17, "#4a2c17", "center", null)
	if E.t > 1.6: c.txt("SPACE / TIKLA: Tekrar Uç   •   ESC: Menü", W / 2, y + 462, 16, "#2b1a10" if int(floor(T * 3)) % 2 else "#c0392b", "center", null)
	c.restore()

# ---------------------------------------------------------------- test botu
func _bot() -> void:
	if state == "chase":
		if C.pick != null:
			if C.pick.t > .6: pressed["Space"] = true
			return
		var fx := 0.0
		var fy := 0.0
		for v in C.vill:
			var dx: float = P.x - v.x
			var dy: float = P.y - v.y
			var d2: float = max(dx * dx + dy * dy, 100.0)
			if d2 < 250 * 250:
				fx += dx / d2; fy += dy / d2
		fx += (480 - P.x) * .00002; fy += (330 - P.y) * .00002
		keys["ArrowRight"] = fx > .0005; keys["ArrowLeft"] = fx < -.0005
		keys["ArrowDown"] = fy > .0005; keys["ArrowUp"] = fy < -.0005
		for v in C.vill:
			if dst(v, P) < 55 and v.stun <= 0: pressed["Space"] = true
	elif state == "saray":
		if randf() < .05: pressed["Space"] = true
	else:
		super._bot()
