extends Node
## Ses: Suno müzikleri, ElevenLabs karakter sesleriyle replikler ve kodla üretilen efektler.
## Efektler web sürümündeki WebAudio formüllerinin aynısıyla açılışta üretilir.

const SR := 22050
const BGM_MAP := {"title": "baslik", "flight": "ucus", "sunset": "ucus", "gece": "ucus", "cezayir": "ucus", "chase": "kovala", "boss": "kovala", "saray": "saray", "win": "final", "end": "rap"}
const VRATE := {"teyze": 1.25, "hanim": 1.18, "cocuk": 1.35, "kiz": 1.3, "kasap": 0.85, "amca": 0.9, "bekci": 1.08, "balikci": 0.95, "berber": 1.12, "hamamci": 0.88, "imam": 0.9, "boss": 0.82, "ulak": 1.05}
const MUS_VOL := 0.42

var muted := false
var sfx := {}           # ad -> AudioStreamWAV
var sfx_players: Array[AudioStreamPlayer] = []
var mus_a: AudioStreamPlayer
var mus_b: AudioStreamPlayer
var mus_cur := ""
var duck := 1.0
var voice: AudioStreamPlayer
var voice_pri := 0
var intro: AudioStreamPlayer
var intro_done := false
var manifest := {}
var vo_mode := 2 # 0 kapalı, 2 karakter sesleri

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	mus_a = AudioStreamPlayer.new(); add_child(mus_a)
	mus_b = AudioStreamPlayer.new(); add_child(mus_b)
	voice = AudioStreamPlayer.new(); add_child(voice)
	intro = AudioStreamPlayer.new(); add_child(intro)
	intro.finished.connect(func(): duck = 1.0)
	var t := FileAccess.get_file_as_string("res://voices/manifest.json")
	var j = JSON.parse_string(t) if t != "" else null
	if j is Dictionary:
		manifest = j
	muted = bool(D.save_data.get("muted", false))
	vo_mode = int(D.save_data.get("vo", 2))
	var t0 := Time.get_ticks_msec()
	_build_sfx()
	print("[snd] efektler hazır: ", sfx.size(), " ses, ", Time.get_ticks_msec() - t0, " ms")

func _process(dt: float) -> void:
	var target := MUS_VOL * duck * (0.0 if muted else 1.0)
	var cur := _cur_player()
	if cur:
		var v := db_to_linear(cur.volume_db)
		v = lerp(v, target, min(1.0, dt * 3.0))
		cur.volume_db = linear_to_db(max(v, 0.0001))
	var other := mus_b if cur == mus_a else mus_a
	if other.playing:
		var v2 := db_to_linear(other.volume_db) - dt * 1.5
		if v2 <= 0.001:
			other.stop()
		else:
			other.volume_db = linear_to_db(v2)

func _cur_player() -> AudioStreamPlayer:
	return mus_a if mus_a.has_meta("cur") else mus_b

# ---------------------------------------------------------------- müzik
func music(n: String) -> void:
	var k: String = BGM_MAP.get(n, "")
	if k == mus_cur and _cur_player().playing:
		return
	mus_cur = k
	var old := _cur_player()
	var nw := mus_b if old == mus_a else mus_a
	old.remove_meta("cur")
	nw.set_meta("cur", true)
	if k == "":
		nw.stop()
		return
	var st: AudioStream = load("res://muzik/suno/%s.mp3" % k)
	if st is AudioStreamMP3:
		st.loop = true
	nw.stream = st
	nw.volume_db = -60
	nw.play()

func music_stop() -> void:
	mus_cur = ""
	var cur := _cur_player()
	cur.remove_meta("cur")
	(mus_b if cur == mus_a else mus_a).set_meta("cur", true)

func play_intro() -> void:
	if muted or intro.playing:
		return
	intro.stream = load("res://muzik/suno/giris.mp3")
	intro.play()
	duck = 0.25
	intro_done = true

func stop_intro() -> void:
	if intro.playing:
		intro.stop()
	duck = 1.0

func toggle_mute() -> void:
	muted = not muted
	D.save_data["muted"] = muted
	D.save()
	if muted:
		voice.stop(); stop_intro()
		for p in sfx_players:
			p.stop()

# ---------------------------------------------------------------- seslendirme
func speak(who: String, text: String, pri := 1) -> void:
	if muted or vo_mode == 0 or not manifest.has(text):
		return
	var busy := voice.playing
	if busy and pri <= voice_pri:
		return
	var e: Array = manifest[text]
	var fid: String = e[2] if (e[1] == null and e.size() > 2 and who in ["teyze", "hanim", "kiz"]) else e[0]
	var st: AudioStream = load("res://voices/%s.mp3" % fid)
	if st == null:
		return
	voice.stream = st
	voice.pitch_scale = 1.0
	voice.play()
	voice_pri = pri

func hush() -> void:
	voice.stop()

# ---------------------------------------------------------------- efektler
func play(n: String) -> void:
	if muted or not sfx.has(n):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx[n]
			p.play()
			return
	sfx_players[0].stream = sfx[n]
	sfx_players[0].play()

var _buf := PackedFloat32Array()

func _ensure(n: int) -> void:
	if _buf.size() < n:
		var o := _buf.size()
		_buf.resize(n)
		for i in range(o, n):
			_buf[i] = 0.0

static func _wave(type: String, ph: float) -> float:
	var f: float = ph - floor(ph)
	match type:
		"square":
			return 1.0 if f < 0.5 else -1.0
		"sawtooth":
			return 2.0 * f - 1.0
		"triangle":
			return 4.0 * abs(f - 0.5) - 1.0
	return sin(ph * TAU)

static func _env(t: float, dur: float, vol: float, att: float) -> float:
	# .0001'den vol'e üstel çıkış, sonra .0001'e üstel iniş (WebAudio exponentialRamp)
	if t < 0.0 or t > dur:
		return 0.0
	if t < att:
		return 0.0001 * pow(vol / 0.0001, t / att)
	return vol * pow(0.0001 / vol, (t - att) / max(0.0001, dur - att))

func tone(type: String, f0: float, f1: float, dur: float, vol := 0.3, delay := 0.0, vib := Vector2.ZERO) -> void:
	var s0 := int(delay * SR)
	var n := int(dur * SR)
	_ensure(s0 + n + 1)
	var ph := 0.0
	var att: float = min(0.02, dur / 3.0)
	for i in n:
		var t := float(i) / SR
		var f := f0
		if f1 > 0.0 and f1 != f0:
			f = f0 * pow(f1 / f0, t / dur)
		if vib.x > 0.0:
			f += sin(TAU * vib.x * t) * vib.y
		ph += f / SR
		_buf[s0 + i] += _wave(type, ph) * _env(t, dur, vol, att)

## RBJ biquad filtreli gürültü
func noise(dur: float, vol: float, ft: String, f0: float, f1 := 0.0, delay := 0.0, q := 1.0) -> void:
	var s0 := int(delay * SR)
	var n := int(dur * SR)
	_ensure(s0 + n + 1)
	var x1 := 0.0; var x2 := 0.0; var y1 := 0.0; var y2 := 0.0
	var b0 := 0.0; var b1 := 0.0; var b2 := 0.0; var a1 := 0.0; var a2 := 0.0
	for i in n:
		var t := float(i) / SR
		if i % 32 == 0:
			var f := f0
			if f1 > 0.0:
				f = f0 * pow(f1 / f0, t / dur)
			f = clamp(f, 20.0, SR * 0.45)
			var w := TAU * f / SR
			var al := sin(w) / (2.0 * q)
			var cw := cos(w)
			var a0 := 1.0 + al
			match ft:
				"lowpass":
					b0 = (1.0 - cw) / 2.0; b1 = 1.0 - cw; b2 = b0
				"highpass":
					b0 = (1.0 + cw) / 2.0; b1 = -(1.0 + cw); b2 = b0
				_:
					b0 = al; b1 = 0.0; b2 = -al
			a1 = -2.0 * cw; a2 = 1.0 - al
			b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
		var x := randf() * 2.0 - 1.0
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1; x1 = x; y2 = y1; y1 = y
		_buf[s0 + i] += y * _env(t, dur, vol, 0.015)

func voice_fx(dur: float, pitch: float) -> void:
	var n := int(dur * SR)
	_ensure(n + 1)
	var base := 170.0 * pitch
	var ph := 0.0
	var x1 := 0.0; var x2 := 0.0; var y1 := 0.0; var y2 := 0.0
	for i in n:
		var t := float(i) / SR
		var k := t / dur
		var f: float
		if k < 0.3: f = lerp(base, base * 1.8, k / 0.3)
		elif k < 0.7: f = lerp(base * 1.8, base * 1.5, (k - 0.3) / 0.4)
		else: f = lerp(base * 1.5, base * 0.9, (k - 0.7) / 0.3)
		f += sin(TAU * 7.0 * t) * base * 0.07
		ph += f / SR
		var x := _wave("sawtooth", ph)
		var fc: float = lerp(700.0, 1300.0, k / 0.4) if k < 0.4 else lerp(1300.0, 600.0, (k - 0.4) / 0.6)
		var w := TAU * fc / SR
		var al := sin(w) / 8.0
		var cw := cos(w)
		var a0 := 1.0 + al
		var y := (al * x - al * x2 + 2.0 * cw * y1 - (1.0 - al) * y2) / a0
		x2 = x1; x1 = x; y2 = y1; y1 = y
		var g := 0.4
		if t < 0.03: g = 0.0001 * pow(0.4 / 0.0001, t / 0.03)
		elif k > 0.8: g = 0.4 * pow(0.0001 / 0.4, (k - 0.8) / 0.2)
		_buf[i] += y * g * 3.0

func _bake(n: String) -> void:
	var cnt := 0
	for i in range(_buf.size() - 1, -1, -1):
		if abs(_buf[i]) > 0.0005:
			cnt = i + 1
			break
	var data := PackedByteArray()
	data.resize(cnt * 2)
	for i in cnt:
		var v: float = clamp(tanh(_buf[i] * 0.55) , -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	sfx[n] = w
	_buf = PackedFloat32Array()

func _build_sfx() -> void:
	var R := func(): return randf()
	tone("sine", 0, 0, 0) # ısınma
	_buf = PackedFloat32Array()
	noise(.16, .35, "bandpass", 600, 1800, 0, 1.5); _bake("flap")
	tone("square", 300, 600, .15, .12); noise(.2, .3, "bandpass", 500, 2000); _bake("jump")
	tone("sawtooth", 1400 + R.call() * 300, 700, .16, .12); tone("sawtooth", 1300, 600, .14, .09, .18); _bake("squawk")
	noise(.9, .6, "lowpass", 4000, 150); tone("sine", 500, 80, .4, .3); _bake("splash")
	tone("sine", 560, 70, .2, .5); noise(.07, .35, "lowpass", 2500, 400); _bake("bonk")
	tone("sine", 160, 640, .38, .45); tone("triangle", 320, 1280, .3, .08); _bake("boing")
	for i in 3: tone("square", [660, 880, 1320][i], 0, .08, .1, i * .06)
	_bake("pickup")
	noise(.28, .4, "bandpass", 300, 3500, 0, 2); _bake("dash")
	tone("square", 2300, 0, .6, .05, 0, Vector2(28, 180)); _bake("whistle")
	tone("sine", 1000, 140, .45, .25); _bake("slip")
	noise(.6, .6, "lowpass", 1800, 100); tone("square", 120, 40, .4, .2); _bake("crash")
	tone("sine", 500, 1300, .09, .3); _bake("pop")
	noise(.15, .25, "highpass", 1500, 4000); _bake("throw")
	voice_fx(.7, 1.0); _bake("yell")
	voice_fx(.6, 1.6); _bake("yellHigh")
	voice_fx(.25, 1.3); _bake("gasp")
	for i in 6: tone("sine", 4400, 0, .04, .05, i * .09 + (.4 if i > 2 else 0.0))
	_bake("cricket")
	var ff := [523, 659, 784, 1046, 784, 1046]
	for i in 6: tone("square", ff[i], 0, .6 if i == 5 else .14, .12, i * .13)
	_bake("fanfare")
	var sd := [392, 370, 349, 330]
	for i in 4: tone("sawtooth", sd[i], sd[i] * .94 if i == 3 else 0.0, 1.1 if i == 3 else .38, .13, i * .42)
	_bake("sad")
	tone("sine", 140, 40, .3, .6); noise(.3, .4, "lowpass", 800, 100); _bake("thud")
	noise(1.6, .3, "lowpass", 300, 200); _bake("rumble")
	tone("square", 1250, 1180, .5, .1); tone("sine", 2500, 2380, .7, .12); noise(.1, .3, "highpass", 3000, 6000); _bake("clang")
	for i in 7:
		tone("sawtooth", 300 - i * 14, 240 - i * 14, .09, .2, i * .12); noise(.06, .15, "bandpass", 900, 1200, i * .12, 3)
	_bake("laugh")
	tone("triangle", 750, 1100, .1, .12); tone("triangle", 1100, 500, .25, .12, .1); _bake("meow")
	for i in 3: noise(.05, .2, "highpass", 2000, 3000, i * .1)
	_bake("eat")
	tone("sine", 110, 45, .25, .5); noise(.08, .2, "lowpass", 1200, 300); _bake("drum")
	tone("sine", 90, 40, .35, .8); noise(.18, .5, "lowpass", 1500, 200); _bake("stamp")
	noise(.12, .5, "highpass", 2500, 6000); tone("square", 900, 200, .08, .1, .05); _bake("whip")
	noise(.25, .45, "lowpass", 2500, 300); tone("sine", 300, 120, .15, .2); _bake("splat")
