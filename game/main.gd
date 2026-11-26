extends Node2D
## Hezarfen – Godot sürümü: başlık + uçuş (ilk dilim).
## Web sürümündeki index.html'nin oyun mantığının aktarımı.
##
## Test modu (komut satırı, `--` sonrası):
##   --scene=title|flight   --frames=N   --shot=C:/yol/resim.png   --bot   --route=0..3

const W := 960.0
const H := 540.0
const OL := "#2b1a10"
const TAU_ := PI * 2.0
const WATER_Y := 468.0
const GAL_G := 430.0
const TOWER_X := 160.0
const GALLERY_Y := 192.0
const GROUND_U := 440.0
const WXN := {"acik": "Açık", "lodos": "LODOS", "yagmur": "YAĞMUR", "kar": "KAR"}

var c: Ctx
var art: Art

# küresel durum
var T := 0.0
var state := "title"
var R: Dictionary
var WX := "acik"
var cam := 0.0
var shake := 0.0
var slow := 0.0
var flash := 0.0
var title_t := 0.0

var SHORE_X := 7000.0
var KK_X := 5950.0
var P: Dictionary
var obs: Array = []
var winds: Array = []
var ferries: Array = []
var pickups: Array = []
var shore: Array = []
var laundry: Array = []
var usk_h: Array = []
var next_spawn := 0.0
var stats: Dictionary
var F: Dictionary
var LD: Dictionary # iniş (şimdilik basit)

var parts: Array = []
var texts: Array = []
var bubbles: Array = []
var toasts: Array = []

var STARS: Array = []
var CLOUDS: Array = []
var SKYL: Array = []
var GAL_H: Array = []

var menu_sel := 0
const MX := W / 2 + 70

# girdi
var keys := {}
var pressed := {}
var ptr := {"x": 0.0, "y": 0.0, "down": false, "tap": false, "last": 0, "dbl": false}

# test modu
var args := {}
var frame_n := 0

const KEYMAP := {KEY_SPACE: "Space", KEY_ENTER: "Enter", KEY_KP_ENTER: "Enter", KEY_ESCAPE: "Escape", KEY_UP: "ArrowUp", KEY_DOWN: "ArrowDown", KEY_LEFT: "ArrowLeft", KEY_RIGHT: "ArrowRight",
	KEY_W: "KeyW", KEY_A: "KeyA", KEY_S: "KeyS", KEY_D: "KeyD", KEY_R: "KeyR", KEY_M: "KeyM", KEY_V: "KeyV", KEY_I: "KeyI", KEY_J: "KeyJ", KEY_SHIFT: "ShiftLeft", KEY_TAB: "Tab", KEY_1: "Digit1", KEY_2: "Digit2", KEY_3: "Digit3", KEY_KP_1: "Digit1", KEY_KP_2: "Digit2", KEY_KP_3: "Digit3"}

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("route"):
		D.save_data["route"] = clampi(int(args["route"]), 0, D.ROUTES.size() - 1)
	if args.has("seed"):
		seed(int(args["seed"]))
	c = Ctx.new(self)
	art = Art.new(c, self)
	R = D.route()
	for i in 70: STARS.append({"x": randf_range(0, W), "y": randf_range(0, 330), "r": randf_range(.6, 1.8), "p": randf_range(0, 6)})
	for i in 9: CLOUDS.append({"x": randf_range(0, 1400), "y": randf_range(25, 240), "s": randf_range(.6, 1.5)})
	var x := -300.0
	while x < 4800:
		if randf() < .1:
			SKYL.append({"t": "m", "x": x, "w": 110.0}); x += 140
		else:
			var w := randf_range(26, 55)
			SKYL.append({"t": "h", "x": x, "w": w, "h": randf_range(16, 42)}); x += w + randf_range(-4, 10)
	x = -700.0
	while x < 330:
		var w := randf_range(45, 75)
		GAL_H.append({"x": x, "w": w, "h": randf_range(35, 85)}); x += w - 4
	if args.get("scene", "title") == "flight":
		start_flight()
	else:
		start_title()

# ---------------------------------------------------------------- yardımcılar
static func choice(a: Array):
	return a[randi() % a.size()]

func hit(codes: Array) -> bool:
	for k in codes:
		if pressed.get(k, false):
			return true
	return false

func held(code: String) -> bool:
	return keys.get(code, false)

func add_p(o: Dictionary) -> void:
	if parts.size() > 700:
		return
	var p := {"x": 0.0, "y": 0.0, "vx": 0.0, "vy": 0.0, "g": 0.0, "life": 1.0, "size": 4.0, "rot": 0.0, "vr": 0.0, "color": "#fff", "type": "dot", "drag": 0.0, "grow": 0.0}
	p.merge(o, true)
	p["max"] = p["life"]
	parts.append(p)

func pop_text(x: float, y: float, text: String, color := "#fff", size := 30.0, life := 1.0) -> void:
	texts.append({"x": x, "y": y, "text": text, "color": color, "size": size, "life": life, "max": life, "r": randf_range(-.12, .12)})

func say(tg: Dictionary, text: String, life := 2.0, oy := -60.0, pri := -1) -> void:
	if tg.has("boss") and oy > -110: oy = -122
	bubbles = bubbles.filter(func(b): return not is_same(b.tg, tg))
	bubbles.append({"tg": tg, "text": text, "life": life, "max": life, "oy": oy})
	var who: String = "hez" if is_same(tg, P) else str(tg.get("vo", tg.get("type", "anlatici")))
	Snd.speak(who, text, pri if pri >= 0 else (2 if is_same(tg, P) else 1))

func has_bubble(tg: Dictionary) -> bool:
	for b in bubbles:
		if is_same(b.tg, tg):
			return true
	return false

func toast(t: String) -> void:
	toasts.append({"t": t, "life": 3.4})
	if toasts.size() > 5:
		toasts.pop_front()

func once(o: Dictionary, tt: float, fn: Callable) -> void:
	if o.t >= tt and not o.ev.has(tt):
		o.ev[tt] = 1
		fn.call()

func splash_fx(x: float, y: float, n: int) -> void:
	for i in n:
		add_p({"type": "dot", "x": x + randf_range(-10, 10), "y": y, "vx": randf_range(-130, 130), "vy": randf_range(-380, -120), "g": 900.0, "life": randf_range(.5, 1), "size": randf_range(2, 5), "color": choice(["#bfe6ff", "#ffffff", "#7fc4ef"])})

func feathers(x: float, y: float, n: int) -> void:
	for i in n:
		add_p({"type": "feather", "x": x, "y": y, "vx": randf_range(-150, 150), "vy": randf_range(-150, 80), "g": 80.0, "life": 1.5, "size": randf_range(3, 6), "vr": randf_range(-6, 6), "color": choice(["#fff", "#dfe5ea", "#f6ecd4"]), "drag": 1.5})

func stars_fx(x: float, y: float, n: int) -> void:
	for i in n:
		var a := randf_range(0, TAU_)
		add_p({"type": "star", "x": x, "y": y, "vx": cos(a) * randf_range(80, 200), "vy": sin(a) * randf_range(80, 200) - 60, "g": 300.0, "life": .8, "size": randf_range(5, 9), "vr": randf_range(-8, 8), "color": choice(["#ffe066", "#fff3b0", "#ffb142"])})

func dust(x: float, y: float, n: int, col := "rgba(200,180,150,.7)") -> void:
	for i in n:
		add_p({"type": "dust", "x": x + randf_range(-10, 10), "y": y + randf_range(-4, 4), "vx": randf_range(-60, 60), "vy": randf_range(-50, -10), "life": randf_range(.4, .8), "size": randf_range(4, 8), "grow": 14.0, "color": col, "drag": 2.0})

# ---------------------------------------------------------------- dünya
func pick_weather() -> String:
	var r := randf()
	if r < .46: return "acik"
	if r < .64: return "lodos"
	if r < .82: return "yagmur"
	return "lodos" if R.mid == "korsan" else "kar"

func init_world() -> void:
	R = D.route()
	P = {"x": TOWER_X + 34, "y": GALLERY_Y - 30, "vx": 0.0, "vy": 0.0, "st": 100.0, "onTower": true, "flapA": 0.0, "hitT": 0.0, "boost": 0.0, "rot": 0.0, "ph": 0.0, "salvar": false, "warnedTop": false, "talkT": 5.0, "tiredSaid": 0.0, "forced": false, "gust": 0.0}
	SHORE_X = R.len
	KK_X = SHORE_X - 1050
	usk_h = []
	var x := SHORE_X + 30
	while x < SHORE_X + 3000:
		var w := randf_range(60, 100)
		usk_h.append({"x": x, "w": w, "h": randf_range(60, 115), "c": choice(R.hs)}); x += w + randf_range(-6, 4)
	cam = 0.0; obs = []; winds = []; ferries = []; pickups = []; parts = []; texts = []; bubbles = []; next_spawn = TOWER_X + 650
	if randf() < R.evliya:
		obs.append({"type": "evliya", "vo": "evliya", "x": R.len * randf_range(.35, .55), "by": randf_range(235, 280), "y": 250.0, "vx": -25.0, "r": 0.0, "noted": 0, "sq": 0.0})
	spawn_rivals()
	var types := ["teyze", "amca", "cocuk", "kasap", "bekci", "balikci", "hanim"]
	types.shuffle()
	shore = []
	for i in types.size():
		shore.append({"type": types[i], "x": SHORE_X + 150 + i * 125 + randf_range(-20, 20), "y": GROUND_U, "f": -1.0, "ph": randf_range(0, 6), "mood": "normal"})
	laundry = []
	x = SHORE_X + 90
	while x < SHORE_X + 1000:
		laundry.append({"x": x, "taken": 0}); x += 170

func reset_stats() -> void:
	stats = {"dist": 0, "landed": false, "hard": false, "gull": 0, "score": 0, "simits": 0, "fsimit": 0, "ferry": 0, "evliya": 0, "rivals": 0}

func spawn_rivals() -> void:
	var ks := D.RIV.keys()
	ks.shuffle()
	var n := 2 if randf() < .7 else 1
	for i in n:
		obs.append({"type": "rival", "k": ks[i], "vo": "carpet", "x": R.len * (randf_range(.6, .7) if i else randf_range(.24, .36)), "by": randf_range(190, 300), "y": 240.0, "vx": 0.0, "vy": 0.0, "st": "idle", "t": 0.0, "ft": 0.0, "said": 0, "r": 24.0, "rot": 0.0})

func start_title() -> void:
	state = "title"; WX = "acik"; init_world(); reset_stats(); title_t = 0.0
	Snd.music("title")

func start_flight() -> void:
	state = "flight"; init_world(); reset_stats(); Snd.music(R.mus); WX = pick_weather()
	var line: String
	match WX:
		"lodos": line = "Lodos var... kavuğumu sıkı bağlasam iyi olur."
		"yagmur": line = "Yağmur mu? Kanatlar ıslanmasın!"
		"kar": line = "Kar yağıyor! Kanatlarım donacak!"
		_: line = choice(["Hedef %s! Ne olabilir ki?" % R.to, "%s şuracıkta zaten!" % R.to, "Bu sefer kesin olacak!"])
	say(P, line, 3, -55)

func spawn_chunk(x: float) -> void:
	var pr := x / SHORE_X
	var r := randf()
	if abs(x - KK_X) < 320:
		pickups.append({"k": "simit", "x": x, "y": randf_range(110, 200), "ph": randf_range(0, 6)}); return
	var gT: float = .36 * R.gull
	var fT := gT + .14
	var cT: float = fT + .1 * R.carpet
	var wT: float = cT + .18 * R.wind
	var feT := wT + .12
	if r < gT:
		var n := (3 + randi() % 3) if (pr > .35 and randf() < .55) else (1 + (1 if randf() < .3 else 0))
		var by := randf_range(70, 370)
		for i in n:
			obs.append({"type": "gull", "x": x + 200 + i * 45, "by": by + (1 if i % 2 else -1) * i * 14, "y": by, "vx": -randf_range(50, 110), "ph": randf_range(0, 6), "amp": randf_range(10, 35), "r": 16.0, "dead": false, "sq": 0, "spin": 0.0, "vy": 0.0})
	elif r < fT:
		obs.append({"type": "fish", "x": x + 120, "y": WATER_Y + 30, "st": "wait", "r": 16.0, "rot": 0.0, "vx": 0.0, "vy": 0.0})
	elif r < cT and pr > .2:
		obs.append({"type": "carpet", "x": x + 700, "by": randf_range(90, 330), "y": 200.0, "vx": -240.0, "ph": randf_range(0, 6), "r": 34.0})
	elif r < wT:
		winds.append({"x": x, "w": randf_range(220, 330), "k": "up" if pr < .15 else choice(["up", "up", "down", "back"])})
	elif r < feT:
		ferries.append({"x": x + 300, "vx": -30.0, "cap": {"x": 0.0, "y": 0.0, "vo": "kaptan"}, "said": 0, "smk": 0.0})
	if randf() < .42 * R.len / 7000.0:
		pickups.append({"k": "simit" if randf() < .75 else "cay", "x": x + randf_range(80, 200), "y": randf_range(110, 380), "ph": randf_range(0, 6)})

func mid_top() -> float:
	return WATER_Y - 262 if R.mid == "kk" else WATER_Y - 218

func mid_hit() -> bool:
	var dx: float = P.x - KK_X
	if R.mid == "kk":
		return (abs(dx) < 20 and P.y > WATER_Y - 232) or (abs(dx) < 50 and P.y > WATER_Y - 52)
	return (dx > -68 and dx < 76 and P.y > WATER_Y - 212) or (abs(dx - 5) < 110 and P.y > WATER_Y - 48)

# ---------------------------------------------------------------- girdi
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey:
		var code: String = KEYMAP.get(e.physical_keycode, "")
		if code == "":
			return
		if e.pressed and not e.echo:
			if not keys.get(code, false):
				pressed[code] = true
			keys[code] = true
		elif not e.pressed:
			keys[code] = false
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = make_input_local(e).position
		ptr.x = p.x; ptr.y = p.y
		if e.pressed:
			ptr.down = true; ptr.tap = true
			var n := Time.get_ticks_msec()
			if n - int(ptr.last) < 320: ptr.dbl = true
			ptr.last = n
		else:
			ptr.down = false
	elif e is InputEventMouseMotion:
		var p: Vector2 = make_input_local(e).position
		ptr.x = p.x; ptr.y = p.y

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		keys.clear()

# ---------------------------------------------------------------- döngü
func _process(delta: float) -> void:
	var dt: float = min(.033, delta)
	if args.has("frames"):
		dt = 1.0 / 60.0
	T += dt
	if args.has("bot"):
		_bot()
	update(dt)
	pressed = {}
	ptr.tap = false
	ptr.dbl = false
	queue_redraw()
	frame_n += 1
	if args.has("frames") and frame_n == int(args["frames"]):
		await RenderingServer.frame_post_draw
		if args.has("shot"):
			get_viewport().get_texture().get_image().save_png(args["shot"])
		print("[test] state=%s x=%.0f y=%.0f dist=%d score=%d hp=%s" % [state, P.x, P.y, stats.dist, stats.score, str(P.get("hp", "-"))])
		get_tree().quit()

## test botu: alçalınca kanat çırpar, Kız Kulesi'nin üstünden geçer
func _bot() -> void:
	if state == "title" and title_t > .5:
		pressed["Space"] = true
	elif state == "flight":
		var target := 300.0
		if abs(P.x + 250 - KK_X) < 400: target = 170.0
		if P.x > SHORE_X - 300: target = 999.0
		if P.onTower or P.y > target and P.vy > -40:
			pressed["Space"] = true

func update(dt: float) -> void:
	if hit(["KeyM"]): Snd.toggle_mute(); toast("Ses: " + ("kapalı" if Snd.muted else "açık"))
	if hit(["KeyV"]):
		Snd.vo_mode = 0 if Snd.vo_mode == 2 else 2
		D.save_data["vo"] = Snd.vo_mode; D.save()
		toast("Seslendirme: " + ("Karakter sesleri" if Snd.vo_mode == 2 else "Kapalı"))
		if Snd.vo_mode: Snd.speak("hez", "Ses kontrol! Bir, iki!", 3)
	if ptr.tap and ptr.x > W - 50 and ptr.y > H - 50:
		Snd.toggle_mute(); ptr.tap = false; ptr.dbl = false
	for t in toasts: t.life -= dt
	toasts = toasts.filter(func(t): return t.life > 0)
	if hit(["Escape"]) and state != "title":
		start_title(); return
	if slow > 0:
		slow -= dt; dt *= .3
	if state == "title":
		if not Snd.intro_done and (not keys.is_empty() or ptr.down): Snd.play_intro()
		if hit(["KeyI"]): Snd.play_intro()
	else:
		Snd.stop_intro()
	match state:
		"title": upd_title(dt)
		"flight": upd_flight(dt)
		"fail": upd_fail(dt)
		"landing": upd_landing(dt)
		_: upd_other(dt)
	upd_fx(dt)

func upd_fx(dt: float) -> void:
	for p in parts:
		p.vx *= 1 - min(1.0, p.drag * dt); p.vy += p.g * dt; p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt; p.size = max(.1, p.size + p.grow * dt); p.life -= dt
	parts = parts.filter(func(p): return p.life > 0)
	for t in texts:
		t.life -= dt; t.y -= 30 * dt
	texts = texts.filter(func(t): return t.life > 0)
	for b in bubbles: b.life -= dt
	bubbles = bubbles.filter(func(b): return b.life > 0)
	shake = max(0.0, shake - dt * 40); flash = max(0.0, flash - dt * 2.5)

# ---------------------------------------------------------------- başlık
func menu_items() -> Array:
	var lock: bool = D.save_data.route >= D.save_data.unl
	return [{"t": "🔒 ROTA KİLİTLİ" if lock else "▶ UÇ!", "y": 282.0, "w": 300.0}, {"t": "◀  %s  ▶" % R.n, "y": 338.0, "w": 400.0},
		{"t": "DÜKKÂN  •  %d akçe" % D.save_data.akce, "y": 402.0, "w": 320.0}, {"t": "GÖREVLER  •  yakında", "y": 454.0, "w": 320.0}]

func change_route(d: int) -> void:
	var n := D.ROUTES.size()
	D.save_data.route = (D.save_data.route + d + n) % n
	R = D.route(); D.save(); init_world(); Snd.play("pop")

func upd_title(dt: float) -> void:
	title_t += dt; P.ph += dt
	var its := menu_items()
	if hit(["ArrowUp", "KeyW"]): menu_sel = (menu_sel + 3) % 4; Snd.play("pop")
	if hit(["ArrowDown", "KeyS"]): menu_sel = (menu_sel + 1) % 4; Snd.play("pop")
	if hit(["ArrowLeft", "KeyA"]): change_route(-1)
	if hit(["ArrowRight", "KeyD"]): change_route(1)
	var act := menu_sel if hit(["Space", "Enter"]) else -1
	if ptr.tap:
		for i in its.size():
			var it: Dictionary = its[i]
			if abs(ptr.x - MX) < it.w / 2 and abs(ptr.y - it.y) < 23:
				menu_sel = i
				if i == 1: change_route(-1 if ptr.x < MX else 1)
				else: act = i
	if act == 0:
		if D.save_data.route < D.save_data.unl:
			start_flight(); return
		Snd.play("bonk"); toast("Önce bir önceki rotada karaya in!")
	elif act == 1: change_route(1)
	elif act >= 2: Snd.play("bonk"); toast("Bu bölüm Godot'ya henüz taşınmadı.")
	if title_t > 3 and not has_bubble(P) and randf() < dt * .4:
		say(P, choice(["Hmm... uçsam mı?", "Bugün hava tam uçmalık!", "Kanatlar hazır, cesaret yükleniyor...", "Üsküdar şuracıkta zaten!"]), 2.4, -55)

# ---------------------------------------------------------------- uçuş
func upd_flight(dt: float) -> void:
	var flap: bool = hit(["Space", "ArrowUp", "KeyW", "Enter"]) or ptr.tap
	var dive := held("ArrowDown") or held("KeyS")
	P.hitT -= dt; P.boost -= dt; P.flapA = max(0.0, P.flapA - dt * 3.2); P.talkT -= dt; P.tiredSaid -= dt
	if P.onTower:
		if flap:
			P.onTower = false; P.vx = 210.0; P.vy = -230.0; P.flapA = 1.0; Snd.play("jump"); Snd.play("yell"); say(P, "Bismillaaaah!", 1.6, -55)
		upd_flight_objects(dt); return
	while next_spawn < cam + W + 300 and next_spawn < SHORE_X - 450:
		spawn_chunk(next_spawn); next_spawn += randf_range(270, 400) - (next_spawn / SHORE_X) * 90
	var over: bool = P.x > SHORE_X + 620
	if over and not P.forced:
		P.forced = true; say(P, "Kanatlar grev yaptı! İniyoruuum!", 2, -55)
	var WG := D.wing()
	if flap and not over:
		if P.st >= WG.cost:
			P.st -= WG.cost; P.vy = min(P.vy * .35, 0.0) - WG.lift; P.flapA = 1.0; Snd.play("flap")
			for i in 2:
				add_p({"type": "feather", "x": P.x - 22, "y": P.y + randf_range(-5, 10), "vx": randf_range(-80, -20), "vy": randf_range(-20, 40), "g": 60.0, "life": 1.2, "size": 4.0, "vr": randf_range(-4, 4), "color": WG.c[1], "drag": 1.0})
			if WG.has("crumbs"):
				for i in 5:
					add_p({"type": "dot", "x": P.x - 20 + randf_range(-10, 10), "y": P.y + randf_range(-5, 10), "vx": randf_range(-90, 10), "vy": randf_range(0, 60), "g": 300.0, "life": 1.0, "size": randf_range(1.5, 3), "color": choice(["#f3cf7a", "#d9a441", "#8bc34a"])})
		else:
			P.vy -= 35; P.flapA = .4; Snd.play("flap")
			if P.tiredSaid <= 0:
				say(P, choice(D.L_TIRED), 1.6, -55); P.tiredSaid = 3.0
	P.st = min(100.0, P.st + WG.regen * (.78 if WX == "kar" else 1.0) * dt)
	if WX == "lodos":
		P.gust -= dt
		if P.gust < -3.5:
			P.gust = 1.0; pop_text(P.x, P.y - 50, "LODOS!", "#dfe6e9", 22)
			if not has_bubble(P): say(P, choice(["Kavuğumu tutun!", "Lodos, lodos!", "Rüzgâr beni geri itiyor!"]), 1.3, -55)
	if WG.has("spark") and randf() < .5:
		add_p({"type": "star", "x": P.x - 30 + randf_range(-8, 8), "y": P.y + randf_range(-12, 12), "vx": randf_range(-120, -40), "vy": randf_range(-30, 30), "life": .5, "size": randf_range(3, 5), "vr": 6.0, "color": choice(["#f39c12", "#e74c3c", "#ffe066"])})
	var tvx: float = WG.spd + (120.0 if dive else 0.0) + (170.0 if P.boost > 0 else 0.0)
	if over: tvx = 140
	var ax: float = (tvx - P.vx) * 1.6
	var ay: float = (950.0 if over else 380.0) * (1.7 if dive else 1.0)
	var term: float = 520.0 if dive else (420.0 if over else float(WG.term))
	P.wind = null
	if P.gust > 0:
		ax -= 380; ay += sin(T * 9) * 500
	for w in winds:
		if P.x > w.x and P.x < w.x + w.w:
			P.wind = w.k
			if w.k == "up": ay -= 740
			elif w.k == "down": ay += 480; term += 240
			else: ax -= (P.vx - 50) * 3.5
	P.vx += ax * dt; P.vy += ay * dt
	if P.vy > term: P.vy = lerp(P.vy, term, min(1.0, dt * 8))
	P.vy = max(P.vy, -430.0)
	P.x += P.vx * dt; P.y += P.vy * dt
	if P.boost > 0 and randf() < .6:
		add_p({"type": "dust", "x": P.x - 30, "y": P.y + randf_range(-15, 15), "vx": -200.0, "vy": 0.0, "life": .3, "size": 3.0, "color": "rgba(255,255,255,.8)"})
	if P.y < 24:
		P.y = 24.0; P.vy = max(P.vy, 30.0)
		if not P.warnedTop:
			P.warnedTop = true; say(P, "Dur! Güneşe yaklaşma, İkarus'u biliyoruz!", 2.4, -55)
	P.rot = clamp(atan2(P.vy, max(60.0, P.vx)) * .6, -.6, .9)
	cam = max(0.0, P.x - 260)
	if P.talkT <= 0:
		P.talkT = randf_range(6, 10)
		if not has_bubble(P): say(P, choice(D.L_FLY), 2.2, -55)
	if P.st < 20 and P.tiredSaid <= 0 and not has_bubble(P):
		say(P, choice(D.L_TIRED), 1.6, -55); P.tiredSaid = 5.0
	stats.dist = int(round(clamp((P.x - TOWER_X) / (SHORE_X - TOWER_X), 0, 1) * R.m))
	upd_flight_objects(dt)
	if state != "flight": return
	if P.x < 340 and P.y + 22 > GAL_G: fail_flight("galata")
	elif P.x < SHORE_X and P.y + 16 > WATER_Y: fail_flight("water")
	elif P.x >= SHORE_X and P.y + 26 >= GROUND_U: start_landing()

func upd_flight_objects(dt: float) -> void:
	var live: bool = not P.onTower and state == "flight"
	for o in obs:
		if o.type == "rival":
			upd_rival(o, dt, live); continue
		if o.type == "evliya":
			o.x += o.vx * dt; o.y = o.by + sin(T * 1.2) * 15; o.sq = max(0.0, o.sq - dt * 2)
			if live and not o.noted and abs(o.x - P.x) < 230:
				o.noted = 1; stats.evliya = 1; stats.score += 200
				say(o, choice(["Not ettim: \"Bir adam uçtu, kavuğu yamuktu.\"", "Bunu Seyahatname'ye yazacağım, kimse inanmayacak!", "Dur! Adın ne? Kitaba yazıyorum!"]), 3, -125, 3)
				pop_text(o.x, o.y - 30, "SEYAHATNAME'YE GİRDİN! +200", "#ffe066", 22)
			if live and P.hitT <= 0 and Vector2(P.x - o.x, P.y - (o.y - 80)).length() < 62:
				var above: bool = P.y < o.y - 80
				P.vy = -480.0 if above else 260.0; P.hitT = .35; o.sq = 1.0; Snd.play("boing"); pop_text(P.x, P.y - 40, "PUF!", "#fff", 30)
				if not has_bubble(o): say(o, "Balonuma basma!" if above else "Altımdan geçme, kalem düşer!", 1.6, -125)
			continue
		if o.type == "gull":
			if not o.dead:
				o.x += o.vx * dt
				if live and abs(o.x - P.x) < 380: o.by += sign(P.y - o.by) * (60.0 if D.wing().has("crumbs") else 32.0) * dt
				o.y = o.by + sin(T * 3 + o.ph) * o.amp
				if not o.sq and o.x - P.x < 320 and o.x > P.x:
					o.sq = 1
					if randf() < .6: Snd.play("squawk")
			else:
				o.x += o.vx * dt; o.y += o.vy * dt; o.vy -= 150 * dt; o.spin += dt * 9
		elif o.type == "fish":
			if o.st == "wait":
				if live and o.x - P.x < 250:
					o.st = "jump"; o.y = WATER_Y; o.vy = -randf_range(520, 640); o.vx = -90.0; splash_fx(o.x, WATER_Y, 10)
			elif o.st == "jump":
				o.x += o.vx * dt; o.y += o.vy * dt; o.vy += 760 * dt; o.rot = atan2(o.vy, o.vx)
				if o.vy > 0 and o.y > WATER_Y + 8:
					o.st = "done"; splash_fx(o.x, WATER_Y, 8)
		elif o.type == "carpet":
			o.x += o.vx * dt; o.y = o.by + sin(T * 2 + o.ph) * 22
		var active: bool = not o.get("dead", false) and (o.type != "fish" or o.st == "jump")
		if active and live and P.hitT <= 0 and Vector2(o.x - P.x, o.y - P.y).length() < o.r + 15:
			hit_flight(o)
	obs = obs.filter(func(o): return o.x > cam - 300 and o.y > -200 and o.get("st", "") != "done")
	for f in ferries:
		f.x += f.vx * dt; f.smk -= dt
		if f.smk <= 0:
			f.smk = .25; add_p({"type": "dust", "x": f.x + 19, "y": WATER_Y - 95, "vx": randf_range(-30, -10), "vy": randf_range(-40, -25), "life": 2.0, "size": 6.0, "grow": 6.0, "color": "rgba(80,80,80,.45)"})
		if live and P.vy > -50 and abs(P.x - f.x) < 106 and P.y + 16 > WATER_Y - 52 and P.y < WATER_Y:
			P.y = WATER_Y - 68; P.vy = -560.0; P.st = min(100.0, P.st + 10); P.flapA = 1.0; Snd.play("boing"); pop_text(P.x, P.y - 40, "BOİİİNG!", "#ffe066", 32)
			if not f.said:
				f.said = 1; say(f.cap, choice(D.L_FERRY), 1.8, -22)
			stats.ferry += 1; stats.score += 100; shake = 4.0
	ferries = ferries.filter(func(f): return f.x > cam - 300)
	for k in pickups:
		if live and not k.get("got", false) and Vector2(k.x - P.x, k.y + sin(T * 3 + k.ph) * 6 - P.y).length() < 32:
			k.got = true; Snd.play("pickup"); stats.score += 50
			if k.k == "simit":
				var wet := WX == "yagmur"
				P.st = min(100.0, P.st + (18 if wet else 30))
				pop_text(k.x, k.y - 20, "ISLAK SİMİT! +AZ GÜÇ" if wet else "SİMİT! +GÜÇ", "#9fd3ff" if wet else "#ffe066", 24)
				if wet and randf() < .5: say(P, "Islak simit de simittir.", 1.3, -55)
				stats.simits += 1; stats.fsimit += 1
			else:
				P.boost = 2.5; P.st = min(100.0, P.st + 15); pop_text(k.x, k.y - 20, "TAVŞAN KANI ÇAY!", "#ff7675", 24); say(P, "Turbo çay! Vınnnn!", 1.4, -55)
			for i in 8:
				add_p({"type": "star", "x": k.x, "y": k.y, "vx": randf_range(-120, 120), "vy": randf_range(-120, 120), "life": .5, "size": 5.0, "color": "#ffe066"})
	pickups = pickups.filter(func(k): return not k.get("got", false) and k.x > cam - 100)
	if live and mid_hit():
		fail_flight("mid")

func upd_rival(o: Dictionary, dt: float, live: bool) -> void:
	var dx: float = o.x - P.x
	if o.st == "idle":
		o.y = o.by + sin(T * 2 + o.by) * 10
		if live and dx < 650:
			o.st = "fly"; o.vx = 150.0
	elif o.st == "fly":
		o.t += dt; o.x += o.vx * dt; o.y = o.by + sin(T * 2.5 + o.by) * 14
		if o.k == "kazan" and randf() < .5:
			add_p({"type": "dust", "x": o.x + randf_range(-6, 6), "y": o.y + 20, "vx": randf_range(-30, 30), "vy": randf_range(60, 120), "life": .5, "size": 5.0, "grow": 12.0, "color": "rgba(255,255,255,.75)"})
		if not o.said and dx < 480:
			o.said = 1; say(o, choice(D.RIV[o.k].l), 2.2, -72, 2)
		if live and P.hitT <= 0 and Vector2(P.x - o.x, P.y - o.y).length() < o.r + 16:
			P.hitT = 1.0; P.vx *= .55; P.vy = max(P.vy, 0.0) + 150; P.st = max(0.0, P.st - 12 * D.wing().dmg); Snd.play("bonk"); pop_text(P.x, P.y - 30, "TOS!", "#fff", 30); say(o, "Sağdan geç, sağdan!", 1.4, -72, 2)
		if o.t > 2.5 and (dx < -70 or o.t > 10):
			o.st = "fail"; o.vy = -140.0; say(o, D.RIV[o.k].f, 1.8, -72, 2)
			if o.k == "kazan":
				Snd.play("crash"); pop_text(o.x, o.y - 40, "PÜÜÜF!", "#fff", 30)
				for i in 16:
					add_p({"type": "dust", "x": o.x, "y": o.y, "vx": randf_range(-160, 160), "vy": randf_range(-160, 60), "life": .9, "size": 8.0, "grow": 16.0, "color": "rgba(255,255,255,.8)", "drag": 2.0})
			elif o.k == "fici":
				Snd.play("bonk"); pop_text(o.x, o.y - 40, "KRAK!", "#fff", 28)
			else:
				Snd.play("throw"); pop_text(o.x, o.y - 60, "ÇAT!", "#fff", 26)
	elif o.st == "fail":
		o.ft += dt * 1.5; o.x += 60 * dt; o.vy += 520 * dt; o.y += o.vy * dt; o.rot += dt * 5
		if o.y > WATER_Y:
			splash_fx(o.x, WATER_Y, 20); Snd.play("splash"); pop_text(o.x, WATER_Y - 50, "RAKİP ELENDİ! +150", "#7bed9f", 22); stats.score += 150; stats.rivals += 1; o.st = "done"

func hit_flight(o: Dictionary) -> void:
	P.hitT = 1.1; shake = 10.0; slow = .12
	if o.type == "gull":
		P.vy = max(P.vy, 0.0) + 170; P.vx *= .6; P.st = max(0.0, P.st - 18 * D.wing().dmg); o.dead = true; o.vy = -200.0; o.vx = 150.0; o.spin = 0.0
		Snd.play("squawk"); Snd.play("bonk"); feathers(o.x, o.y, 12); pop_text(o.x, o.y - 20, "GAAAK!", "#fff", 30); say(o, choice(D.L_GULL), 1.6, -25); stats.gull += 1; stats.score -= 30
	elif o.type == "fish":
		P.vx *= .5; P.vy = max(P.vy, 0.0) + 140; P.st = max(0.0, P.st - 12); Snd.play("bonk"); pop_text(o.x, o.y - 20, "ŞLAP!", "#ffb35c", 32); say(o, choice(D.L_FISH), 1.6, -25); splash_fx(P.x, P.y, 6)
	elif o.type == "carpet":
		P.vx = -40.0; P.vy = 220.0; P.st = max(0.0, P.st - 15); Snd.play("bonk"); pop_text(P.x, P.y - 30, "PATENT İHLALİ!", "#f1c40f", 28); say(o, choice(D.L_CARPET), 1.8, -55)

func award(total: float) -> int:
	var a := int(floor(max(0.0, total) / 40.0))
	D.save_data.akce += a
	D.save()
	return a

func fail_flight(kind: String) -> void:
	state = "fail"; Snd.music_stop(); shake = 12.0
	var kk: bool = R.mid == "kk"
	var msg: String
	if kind == "water":
		msg = choice(["Glu glu glu... Boğaz'ın balıkları bu hikâyeyi nesiller boyu anlatacak.", "Hezarfen yüzmeyi de uçmak kadar biliyordu. Yani pek değil.", "Bir martı güldü. Sonra bir tane daha. Sonra hepsi.", "Kavuk yüzüyor, Hezarfen düşünüyor."])
	elif kind == "mid":
		if kk: msg = choice(["Kız Kulesi'ne yapıştın. Kuledeki kız pencereden baktı: \"Yine mi sen?!\"", "Kız Kulesi 1. Hezarfen 0. Kule kılını bile kıpırdatmadı."])
		elif R.mid == "korsan": msg = "Korsan gemisinin yelkenine yapıştın. Korsanlar seni bayrak yapmayı düşündü."
		else: msg = "Kalyonun direğine çarptın. Tayfalar seni yeni bir yelken sandı."
	else:
		msg = choice(["Daha denize varmadan çakıldın!", "Komşunun damına indin. Komşu hiç memnun değil."])
	F = {"kind": kind, "t": 0.0, "ev": {}, "kx": P.x, "ws": 0.0, "panel": 1e9 if kind == "mid" else .7, "msg": msg, "vy": 0.0, "sad": false}
	if kind == "water":
		Snd.play("splash"); splash_fx(P.x, WATER_Y, 40)
	elif kind == "mid":
		Snd.play("bonk"); Snd.play("crash"); shake = 18.0; slow = .2; P.x = KK_X - (24 if kk else 72); stars_fx(P.x + 10, P.y, 12); pop_text(P.x, P.y - 40, "BONK!!", "#fff", 46)
	else:
		Snd.play("thud"); Snd.play("bonk"); dust(P.x, GAL_G, 14); stars_fx(P.x, P.y, 8)
	P.vx = 0.0; P.vy = 0.0
	F.akce = award((stats.score + stats.dist * .3) * D.wing().mult)

func upd_fail(dt: float) -> void:
	F.t += dt
	if F.t > .9 and not F.sad and F.kind != "mid":
		F.sad = true; Snd.play("sad")
	if F.kind == "mid" and not F.ws:
		if F.t > .6:
			F.vy += 320 * dt; P.y += F.vy * dt
		if P.y + 16 > WATER_Y:
			F.ws = F.t; F.kx = P.x; F.panel = F.t + .7; Snd.play("splash"); splash_fx(P.x, WATER_Y, 30); Snd.play("sad")
	once(F, .8, func():
		if F.kind == "mid":
			var tg := {"x": KK_X + 3, "y": WATER_Y - 150, "vo": "kiz"} if R.mid == "kk" else {"x": KK_X + 70, "y": WATER_Y - 80, "vo": "kaptan"}
			say(tg, "Burası özel mülk! ...Yine mi sen?!" if R.mid == "kk" else ("Arrr! Kanatlı martı yakaladık!" if R.mid == "korsan" else "Reis! Direğe tüy yapıştı!"), 2.2, -30, 3)
		elif F.kind == "galata":
			say({"x": P.x + 30, "y": GAL_G - 40, "vo": "teyze"}, "Damımı deldin! Bu ay kirayı sen ödüyorsun!", 2.4, -20, 3))
	once(F, 1.9, func():
		if F.kind == "water": say({"x": F.kx + 18, "y": WATER_Y - 30, "vo": "fish"}, "Teşekkürler, tam benim boyum!", 2, -10, 3))
	var floating: bool = F.kind == "water" or (F.kind == "mid" and F.ws)
	if floating and randf() < .25:
		add_p({"type": "bubble", "x": F.kx + randf_range(-10, 10), "y": WATER_Y + 30, "vy": -40.0, "life": .8, "size": randf_range(2, 5)})
	if F.t > F.panel + .5 and (hit(["Space", "Enter", "KeyR"]) or ptr.tap):
		start_flight()

# ---------------------------------------------------------------- iniş (geçici)
func start_landing() -> void:
	state = "landing"
	var hard: bool = P.vy > 170 or P.rot > .5
	LD = {"t": 0.0, "ev": {}, "hard": hard, "slide": true}
	P.y = GROUND_U - 30; P.vy = 0.0; P.vx = clamp(P.vx, 240.0, 330.0); P.rot = 1.3 if hard else 0.0; P.hitT = 0.0
	Snd.play("thud"); shake = 14.0; slow = .15; pop_text(P.x, P.y - 40, "GÜÜÜM!" if hard else "TAK!", "#ffe066", 42); dust(P.x, GROUND_U, 16)
	stats.landed = true; stats.score += 1000 + (0 if hard else 400)
	Snd.music_stop()
	if D.save_data.route + 1 < D.ROUTES.size() and D.save_data.unl < D.save_data.route + 2:
		D.save_data.unl = D.save_data.route + 2; D.save(); toast("🔓 YENİ ROTA: %s" % D.ROUTES[D.save_data.route + 1].n)
	award(stats.score + stats.dist * .3)
	if stats.score > int(D.save_data.best):
		D.save_data.best = stats.score; D.save()

func upd_landing(dt: float) -> void:
	LD.t += dt
	if LD.slide:
		P.vx -= 330 * dt
		if P.vx <= 0:
			P.vx = 0.0; LD.slide = false
		P.x += P.vx * dt
		if randf() < .6: dust(P.x, GROUND_U, 1)
	elif P.rot > 0:
		P.rot = max(0.0, P.rot - dt * 1.5)
	once(LD, 1.0, func():
		say(P, "Yüz üstü ama... İNDİM!" if LD.hard else "İNDİM! TARİH YAZDIM!", 1.8, -58, 3); Snd.play("fanfare"))
	cam = lerp(cam, P.x - 420, min(1.0, dt * 3))
	if LD.t > 2.5 and (hit(["Space", "Enter"]) or ptr.tap):
		start_title()

# alt sınıfın (chase.gd) dolduracağı kancalar
func upd_other(_dt: float) -> void:
	pass

func draw_other() -> void:
	pass

func draw_flight_extra() -> void:
	pass

# ---------------------------------------------------------------- çizim
func _draw() -> void:
	var sx := (randf() - .5) * shake
	var sy := (randf() - .5) * shake
	c.reset(Transform2D(0.0, Vector2(sx, sy)))
	c.fill_rect(-20, -20, W + 40, H + 40, "#000")
	match state:
		"title": draw_flight_scene(); draw_title_ui()
		"flight": draw_flight_scene(); draw_flight_hud()
		"fail": draw_flight_scene(); draw_fail_ui()
		"landing":
			var z: float = 1 + .6 * clamp(LD.t / 1.2, 0, 1)
			var fx: float = P.x - cam
			var fy := GROUND_U - 20
			c.translate(fx, fy); c.scale(z, z); c.translate(-fx, -fy)
			draw_flight_scene()
			c.reset()
			draw_landing_ui()
		_: draw_other()
	c.reset()
	if flash > 0:
		c.fill_rect(0, 0, W, H, Color(1, 1, 1, flash))
	draw_toasts()
	c.save(); c.txt("🔇" if Snd.muted else "🔊", W - 24, H - 24, 22, "#fff", "center", null); c.restore()
	draw_set_transform_matrix(Transform2D.IDENTITY)

func draw_hez_flight() -> void:
	if state == "fail" and F.kind == "mid" and not F.ws:
		art.draw_person(P.x + 8, P.y + 30, D.hez_opts({"s": .82, "f": .42, "mood": "dizzy", "wa": -.3, "wl": 64.0, "salvar": P.salvar}))
		for k in 3:
			var a := T * 6 + k * TAU_ / 3
			c.star(P.x + cos(a) * 18, P.y - 28 + sin(a) * 5, 6, a, "#ffe066")
		return
	if state == "fail" and (F.kind == "water" or F.kind == "mid"):
		var ft: float = F.t - F.ws if F.kind == "mid" else F.t
		var kx: float = F.kx + min(ft, 1.5) * 12
		var ky := WATER_Y - 2 + sin(T * 3) * 2
		if F.kind == "water" and ft > 1.5:
			var k: float = clamp((ft - 1.5) / .5, 0, 1)
			var fy := WATER_Y + 20 - sin(k * PI * .5) * 34 + sin(T * 3) * 2
			c.save(); c.translate(kx, fy); c.rotate(-PI / 2); art.draw_fish(0, 0, 0); c.restore(); art.kavuk_icon(kx, fy - 24, true, 1.1)
		else:
			c.save(); c.translate(kx, ky); c.rotate(sin(T * 2) * .2); art.kavuk_icon(0, 0, true, 1.3); c.restore()
		if ft < .3:
			art.draw_person(P.x, P.y + 30 + ft * 200, D.hez_opts({"s": .82, "mood": "scared", "wa": .9, "wl": 64.0, "salvar": P.salvar}))
		return
	var dive := held("ArrowDown") or held("KeyS")
	var wa: float
	if P.onTower: wa = .25 + sin(T * 3) * .12
	elif P.flapA > 0: wa = .25 + sin(P.flapA * TAU_) * .95
	elif dive and state == "flight": wa = -.55
	else: wa = .3 + sin(T * 2) * .06
	if state == "landing": wa = .6 if LD.slide else (-.9 + sin(T * 2) * .05)
	var mood := "scared" if (P.hitT > 0 or P.st < 20) else "smile"
	if state == "landing": mood = "scared" if LD.t > 3.7 else "happy"
	c.save()
	if state == "flight" and P.hitT > 0 and int(floor(T * 14)) % 2 == 0: c.alpha = .5
	art.draw_person(P.x, P.y + 30, D.hez_opts({"s": .82, "f": 1.0, "rot": P.rot, "wa": wa, "wl": 64.0, "run": 0.0 if (P.onTower or state == "landing") else .35, "ph": T * 5, "mood": mood,
		"shout": .7 if (P.flapA > .3 or (state == "landing" and has_bubble(P))) else 0.0, "salvar": P.salvar}))
	c.restore()

func draw_shore_people() -> void:
	for s in shore:
		var o: Dictionary = D.VT[s.type].duplicate()
		var arm := .2
		var mood := "normal"
		if P.x > SHORE_X - 900 and state == "flight":
			mood = "surprised"; arm = -2.3; s.f = -1.0 if P.x < s.x else 1.0
		if state == "landing":
			mood = "surprised" if LD.t < 1.5 else "angry"; arm = -2.6 + sin(T * 20 + s.ph) * .15 if LD.t > 1.5 else -2.3
		o.merge({"s": .8 * float(o.get("s", 1.0)), "f": s.f, "ph": s.ph, "run": 0.0, "arm": arm, "mood": mood, "shout": .7 if has_bubble(s) else 0.0}, true)
		art.draw_person(s.x, GROUND_U, o)

func draw_flight_scene() -> void:
	c.vgrad_rect(0, 0, W, WATER_Y, [[0, R.sky[0]], [.65, R.sky[1]], [1, R.sky[2]]])
	var sn: Array = R.sun
	if R.get("night", 0):
		for s in STARS:
			c.save(); c.alpha = .35 + .65 * abs(sin(T * 1.3 + s.p)); c.circ(s.x, s.y, s.r, "#fff"); c.restore()
		c.set_fill("rgba(245,243,208,.15)"); c.circ(sn[0], sn[1], sn[3] * 2); c.circ(sn[0], sn[1], sn[3], sn[2])
		c.set_fill("rgba(180,180,150,.5)"); c.circ(sn[0] - 10, sn[1] - 6, 6); c.circ(sn[0] + 9, sn[1] + 9, 4); c.circ(sn[0] + 6, sn[1] - 12, 3)
	else:
		c.set_fill("rgba(255,240,170,.35)"); c.circ(sn[0], sn[1], sn[3] * 1.6); c.circ(sn[0], sn[1], sn[3], sn[2])
	c.save()
	if R.get("night", 0): c.alpha = .22
	for cl in CLOUDS:
		art.draw_cloud(fposmod(cl.x - cam * .12, W + 300) - 150, cl.y, cl.s)
	c.restore()
	art.draw_skyline(cam * .18 + 400, R.sk[0], -14, SKYL)
	art.draw_skyline(cam * .35, R.sk[1], 0, SKYL)
	art.draw_water(cam)
	for w in winds:
		if w.x + w.w > cam and w.x < cam + W: art.draw_wind(w, cam)
	c.save(); c.translate(-cam, 0)
	if cam < 800:
		c.fill_rect(-800, GAL_G, 1140, H - GAL_G, "#8a7a62"); c.fill_rect(-800, GAL_G, 1140, 7, "#a8977c"); c.set_stroke(OL); c.lw = 2; c.ln(340, GAL_G, 340, H)
		for i in GAL_H.size():
			var h: Dictionary = GAL_H[i]
			art.draw_house(h.x, GAL_G, h.w, h.h, R.hs[i % R.hs.size()], R.roof)
		art.draw_start(TOWER_X)
	if abs(KK_X - cam - W / 2) < W: art.draw_mid(KK_X)
	if cam > SHORE_X - W - 300:
		art.draw_mosque(SHORE_X + 640, GROUND_U)
		for h in usk_h:
			if h.x < cam + W + 50 and h.x + h.w > cam - 50: art.draw_house(h.x, GROUND_U, h.w, h.h, h.c, R.roof)
		c.fill_rect(SHORE_X, GROUND_U, 3200, H - GROUND_U, "#9c8a6e"); c.fill_rect(SHORE_X, GROUND_U, 3200, 6, "#bfae8e"); c.set_stroke(OL); c.lw = 2; c.ln(SHORE_X, GROUND_U, SHORE_X, H)
		c.set_stroke("rgba(60,40,20,.3)")
		var x := SHORE_X
		while x < SHORE_X + 3200:
			c.ln(x, GROUND_U + 6, x, H); x += 40
		c.txt(R.to, SHORE_X + 260, GROUND_U + 50, 22, "#fff3c4")
		for l in laundry: art.draw_laundry(l)
		draw_shore_people()
	for f in ferries: art.draw_ferry(f)
	for k in pickups:
		var y: float = k.y + sin(T * 3 + k.ph) * 6
		c.circ(k.x, y, 20 + sin(T * 6) * 3, "rgba(255,240,150,.35)")
		if k.k == "simit": art.draw_simit(k.x, y)
		else: art.draw_cay(k.x, y)
	for o in obs:
		match o.type:
			"rival":
				if abs(o.x - cam - W / 2) < W: art.draw_rival(o, has_bubble(o))
			"evliya":
				if abs(o.x - cam - W / 2) < W: art.draw_evliya(o)
			"gull": art.draw_gull(o.x, o.y, -1, T + o.ph, o.spin if o.dead else 0.0)
			"fish":
				if o.st == "jump": art.draw_fish(o.x, o.y, o.rot)
			"carpet": art.draw_carpet(o.x, o.y)
	draw_hez_flight()
	draw_flight_extra()
	if cam < 800: art.draw_galata_rail(TOWER_X)
	draw_parts(0)
	c.restore()
	draw_texts(cam); draw_bubbles(cam); draw_weather()

func draw_weather() -> void:
	if WX == "yagmur":
		c.fill_rect(0, 0, W, H, "rgba(30,40,70,.18)"); c.set_stroke("rgba(200,220,255,.55)"); c.lw = 1.5
		for i in 90:
			var x: float = fmod(i * 137 + T * 260, W + 80) - 40
			var y: float = fmod(i * 89 + T * 820, H + 40) - 20
			c.ln(x, y, x - 6, y + 16)
	elif WX == "kar":
		c.fill_rect(0, 0, W, H, "rgba(220,235,255,.12)")
		for i in 90:
			var x: float = fposmod(i * 97 + sin(T * .8 + i) * 24 + T * 25, W + 20) - 10
			var y: float = fmod(i * 53 + T * (45 + i % 3 * 15), H + 20) - 10
			c.circ(x, y, 1.5 + (i % 3) * .8, "rgba(255,255,255,.9)")
	elif WX == "lodos":
		c.set_stroke("rgba(255,255,255,.35)"); c.lw = 2
		for i in 14:
			var x := W - fmod(i * 173 + T * 520, W + 200)
			var y := 40.0 + (i * 61) % int(H - 80)
			c.begin_path(); c.move_to(x, y); c.quad_to(x + 20, y - 6, x + 50, y); c.stroke()

func draw_parts(cx: float) -> void:
	for p in parts:
		c.save()
		c.alpha = clamp(p.life / p.max * 1.6, 0, 1)
		var x: float = p.x - cx
		var y: float = p.y
		match p.type:
			"dot", "dust": c.circ(x, y, p.size, p.color)
			"feather":
				c.translate(x, y); c.rotate(p.rot); c.ell(0, 0, p.size * 1.6, p.size * .5, p.color); c.set_stroke("rgba(80,60,40,.6)"); c.lw = 1; c.ln(-p.size * 1.6, 0, p.size * 1.6, 0)
			"star": c.star(x, y, p.size, p.rot, p.color)
			"bubble":
				c.set_stroke("rgba(255,255,255,.8)"); c.lw = 1.5; c.begin_path(); c.arc(x, y, p.size, 0, TAU_); c.stroke()
			"ring":
				c.set_stroke(p.color); c.lw = 3; c.begin_path(); c.arc(x, y, p.size, 0, TAU_); c.stroke()
			"terlik":
				c.translate(x, y); c.rotate(p.rot); art.draw_terlik_shape()
			"ghost":
				c.alpha *= .3; art.draw_person(x, y, p.o)
			"melon":
				c.translate(x, y); c.rotate(p.rot)
				c.begin_path(); c.arc(0, 0, p.size, 0, PI); c.close_path(); c.fill("#2e8b57")
				c.begin_path(); c.arc(0, 0, p.size * .78, 0, PI); c.close_path(); c.fill("#ff4d4d")
				c.circ(-p.size * .3, p.size * .25, 1, "#222"); c.circ(p.size * .3, p.size * .25, 1, "#222")
		c.restore()

func draw_texts(cx: float) -> void:
	for t in texts:
		var k: float = 1 - t.life / t.max
		var sc: float = lerp(.3, 1.3, k / .12) if k < .12 else (lerp(1.3, 1.0, (k - .12) / .1) if k < .22 else 1.0)
		c.save(); c.alpha = clamp(t.life / t.max * 3, 0, 1); c.translate(t.x - cx, t.y); c.rotate(t.r); c.scale(sc, sc); c.txt(t.text, 0, 0, t.size, t.color); c.restore()

func draw_bubbles(cx: float) -> void:
	for b in bubbles:
		var tg: Dictionary = b.tg
		var x: float = tg.x - cx
		var y: float = tg.y - float(tg.get("z", 0.0)) + b.oy
		var lines := c.wrap(b.text, 190, 15)
		var w := 0.0
		for l in lines: w = max(w, c.measure(l, 15))
		w += 18
		var h := lines.size() * 18 + 10.0
		var k: float = min(1.0, (b.max - b.life) * 9)
		var bx: float = clamp(x - w / 2, 6, W - w - 6)
		var by: float = clamp(y - h, 6, H - h - 24)
		c.save(); c.alpha = min(1.0, b.life * 4)
		c.translate(x, by + h); c.scale(k, k); c.translate(-x, -(by + h))
		c.rr(bx, by, w, h, 9); c.fill("#fffdf5"); c.set_stroke(OL); c.lw = 2; c.stroke()
		var tx: float = clamp(x, bx + 12, bx + w - 12)
		var tipx: float = clamp(x, tx - 10, tx + 10)
		c.begin_path(); c.move_to(tx - 6, by + h - 1); c.line_to(tx + 6, by + h - 1); c.line_to(tipx, by + h + 10); c.close_path(); c.fill("#fffdf5")
		c.begin_path(); c.move_to(tx - 6, by + h); c.line_to(tipx, by + h + 10); c.line_to(tx + 6, by + h); c.stroke()
		for i in lines.size():
			c.txt(lines[i], bx + w / 2, by + 14 + i * 18, 15, "#2b1a10", "center", null)
		c.restore()

func draw_flight_hud() -> void:
	if P.onTower:
		var k := .5 + sin(T * 6) * .5
		c.rr(W / 2 - 230, 330, 460, 120, 16); c.fill("rgba(30,20,10,.6)")
		c.txt("SPACE / TIKLA: ATLA!", W / 2, 360, 30, Color(1, (220 + k * 35) / 255.0, (100 + k * 100) / 255.0))
		c.txt("Uçarken SPACE / TIKLA: kanat çırp   •   ↓ / S: dalış", W / 2, 395, 15, "#fff", "center", null)
		c.txt("Simit = kol gücü  •  Çay = turbo  •  Vapur = trambolin  •  Martılara dikkat!", W / 2, 420, 15, "#fff", "center", null)
		return
	var low: bool = P.st < 20 and int(floor(T * 6)) % 2 == 0
	art.bar(20, 18, 200, 22, P.st / 100.0, "#2ecc71" if P.st > 50 else ("#f1c40f" if P.st > 20 else "#e74c3c"), "KOL GÜCÜ BİTİYOR!" if low else "KOL GÜCÜ")
	var px := W / 2 - 170
	var pw := 340.0
	var pr: float = clamp((P.x - TOWER_X) / (SHORE_X - TOWER_X), 0, 1)
	c.rr(px, 22, pw, 10, 5); c.fill("rgba(0,0,0,.4)"); c.rr(px, 22, max(pw * pr, 1.0), 10, 5); c.fill("#74b9ff")
	var kk := (KK_X - TOWER_X) / (SHORE_X - TOWER_X)
	c.fill_rect(px + pw * kk - 1, 18, 2, 18, "#fff")
	c.txt(R.from, px - 8, 27, 12, "#fff", "right"); c.txt(R.to, px + pw + 8, 27, 12, "#fff", "left")
	art.kavuk_icon(px + pw * pr, 16, true, .8)
	c.txt("%d m / %d m" % [stats.dist, R.m], W / 2, 50, 14, "#fff")
	var md: float = KK_X - P.x
	if md > 120 and md < 900 and P.y > mid_top() - 30 and int(floor(T * 5)) % 2:
		c.txt("⚠ %s GELİYOR! YÜKSEL! ⚠" % ("KIZ KULESİ" if R.mid == "kk" else ("KORSAN GEMİSİ" if R.mid == "korsan" else "KALYON")), W / 2, 84, 22, "#ff6b6b")
	c.txt("PUAN: %d" % max(0, stats.score + int(round(stats.dist * .3))), W - 70, 22, 16, "#ffe066", "right")
	if P.boost > 0: c.txt("TURBO ÇAY!", 120, 62, 16, "#ff7675")
	if WX != "acik": c.txt("HAVA: " + WXN[WX], 20, 82, 14, "#dfe6e9", "left")
	if P.x > SHORE_X - 500 and P.x < SHORE_X + 700: c.txt("İN! ↓", W / 2, 110 + sin(T * 8) * 5, 34, "#ffe066")

func draw_fail_ui() -> void:
	if F.t < F.panel: return
	var k: float = min(1.0, (F.t - F.panel) * 4)
	c.save(); c.alpha = k
	c.fill_rect(0, 0, W, H, "rgba(10,10,30,.5)")
	c.rr(W / 2 - 260, 140, 520, 250, 18); c.fill("#f3e2b8"); c.set_stroke("#8a5a2b"); c.lw = 5; c.stroke()
	c.txt("ŞAPUR ŞUPUR!" if F.kind == "water" else ("DUVAR SEVDASI!" if F.kind == "mid" else "ÇAKILDIN!"), W / 2, 185, 42, "#e67e22" if F.kind == "mid" else "#3498db")
	var lines := c.wrap(F.msg, 440, 18)
	for i in lines.size(): c.txt(lines[i], W / 2, 236 + i * 24, 18, "#4a2c17", "center", null)
	c.txt("Uçulan mesafe: %d m   •   +%d akçe" % [stats.dist, F.akce], W / 2, 312, 18, "#8a5a2b", "center", null)
	if F.t > F.panel + .5: c.txt("SPACE / TIKLA: Tekrar dene   •   ESC: Menü", W / 2, 355, 16, "#2b1a10" if int(floor(T * 3)) % 2 else "#c0392b", "center", null)
	c.restore()

func draw_landing_ui() -> void:
	if LD.t < 1.6: return
	var k: float = min(1.0, (LD.t - 1.6) * 3)
	c.save(); c.alpha = k
	c.rr(W / 2 - 280, 120, 560, 200, 18); c.fill("#f3e2b8"); c.set_stroke("#8a5a2b"); c.lw = 5; c.stroke()
	c.txt("İNDİN!", W / 2, 165, 44, "#27ae60")
	c.txt("%s'a ulaştın! Puan: %d" % [R.to, stats.score + int(stats.dist * .3)], W / 2, 215, 20, "#4a2c17", "center", null)
	c.txt("Kovalamaca bölümü Godot'ya bir sonraki adımda taşınacak.", W / 2, 250, 16, "#8a5a2b", "center", null)
	if LD.t > 2.5: c.txt("SPACE / TIKLA: Menüye dön", W / 2, 290, 16, "#2b1a10" if int(floor(T * 3)) % 2 else "#c0392b", "center", null)
	c.restore()

func draw_title_ui() -> void:
	c.vgrad_rect(0, 0, W, H, [[0, "rgba(20,10,40,.15)"], [1, "rgba(20,10,40,.55)"]])
	c.save(); c.translate(W / 2 + 70, 120); c.rotate(sin(T * 1.5) * .03); c.txt("HEZARFEN", 0, 0, 84, "#ffd166", "center", OL, 10); c.restore()
	c.txt("– Uçtun da Ne Oldu? –", W / 2 + 70, 185, 30, "#fff", "center", OL, 6)
	c.txt(D.TAGS[int(floor(T / 3)) % D.TAGS.size()], W / 2 + 70, 228, 18, "#ffeaa7", "center", OL, 4)
	var its := menu_items()
	var lock: bool = D.save_data.route >= D.save_data.unl
	for i in its.size():
		var it: Dictionary = its[i]
		var sel := menu_sel == i
		var k := 1 + sin(T * 6) * .035 if sel else 1.0
		c.save(); c.translate(MX, it.y); c.scale(k, k); c.rr(-it.w / 2, -21, it.w, 42, 21)
		var fc = ("#7f8c8d" if lock else ("#e74c3c" if sel else "#a83a2e")) if i == 0 else ("#f39c12" if sel else "rgba(30,20,10,.62)")
		c.fill(fc); c.set_stroke("#fff" if sel else OL); c.lw = 4 if sel else 3; c.stroke(); c.txt(it.t, 0, 1, 24 if i == 0 else 18, "#fff")
		c.restore()
	c.txt("Önceki rotada karaya inince açılır" if lock else "Rota %d/%d   •   Kanat: %s" % [D.save_data.route + 1, D.ROUTES.size(), D.wing().n], MX, 369, 12, "#ffb3a7" if lock else "#ffeaa7", "center", OL, 3)
	if int(D.save_data.best) > 0: c.txt("EN İYİ PUAN: %d" % int(D.save_data.best), MX, 494, 15, "#ffd166")
	c.txt("↑↓ seç • ←→ rota • SPACE/ENTER   |   M: Ses   •   V: Seslendirme   •   I: Giriş", W / 2, H - 14, 12, "#fff", "center", OL, 3)

func draw_toasts() -> void:
	var n := toasts.size()
	for i in range(maxi(0, n - 4), n):
		var t: Dictionary = toasts[i]
		var j: int = i - maxi(0, n - 4)
		var age: float = 3.4 - t.life
		var k: float = min(1.0, age * 5)
		var y := 64.0 + j * 44
		c.save(); c.alpha = min(1.0, t.life * 3); c.translate(lerp(340.0, 0.0, k), 0)
		c.rr(W - 340, y, 326, 36, 12); c.fill("rgba(30,20,10,.85)"); c.set_stroke("#e3b23c"); c.lw = 2; c.stroke()
		c.txt(t.t, W - 326, y + 18, 14, "#ffe066", "left", null)
		c.restore()
