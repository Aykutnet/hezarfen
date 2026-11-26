extends Node
## Oyun verileri ve kayıt (web sürümündeki SAVE/ROUTES/WINGS/HATS/replikler).

const L_FLY := ["Aşağı bakma Ahmet, aşağı bakma...", "Wright kardeşlere selam olsun!", "Annem görse gurur duyardı. Ya da bayılırdı.", "Haritada bu kadar uzun görünmüyordu!", "Kanat garantisi 2 yıldı, değil mi?", "Boğaz'ın havası bir başka!", "Kimse alkışlamıyor mu?"]
const L_TIRED := ["Kollarım koptu!", "Bir simit lazım, acil!", "Kol değil makarna bunlar!", "Kaslarım grevde!"]
const L_GULL := ["SİMİT VER!", "Burası bizim hava sahası!", "Gak! Kaçak uçuş!", "Turist misin?", "Kanat kaç para?"]
const L_FISH := ["Ne bakıyon?", "Yukarısı nasıl?", "Blub! Ben de uçarım!", "Lüfer'e selam söyle!"]
const L_CARPET := ["Önce ben uçtum!", "Patent bende!", "Sağdan sollama!", "Bin bir gecedir uçuyorum!"]
const L_FERRY := ["Bilet!", "Akbil bas!", "Kadıköy değil burası!", "Çay alır mısın?", "Martıya simit atma!"]
const L_RUN := ["Bilim için koşuyorum!", "Bir dakika, açıklayabilirim!", "İmzalı tüy vereyim!", "Fizik bu, fizik!", "Padişahım yetiş!", "Bu bir aerodinamik deneyiydi!", "Şalvarı geri veririm!", "Kanatlarım çekte!"]
const L_HURT := ["Ah kavuğum!", "Bilime vurdunuz!", "Kanadım değil, kafam!", "Tamam, bir daha uçmam!", "Ay! Ay! Aaay!", "Ben bilim insanıyım!"]
const L_ARGUE := [["Önüne baksana!", "Sen baksana!"], ["Ayağıma bastın!", "Sıraya gir!"], ["Bu benim dayağım!", "Önce ben gördüm!"], ["Kör müsün?!", "Sen kör müsün?!"], ["Hep sen zaten!", "Ne hep ben?!"], ["Kafam!", "Benim kafam!"]]
const SH := {
	"teyze": ["Gel buraya kuş bozuntusu!", "O benim şalvarım!", "Terliğim güdümlüdür!", "Annen biliyor mu bunu?!"],
	"amca": ["Bizim zamanımızda yürürdük!", "Dur bakayım evladım!", "Fesim uçtu senin yüzünden!", "Ben de gençken uçardım!"],
	"cocuk": ["Abi bana da kanat yap!", "Sapanla vurcam!", "Uçan dede! Uçan dede!", "Okulu ektim, değdi!"],
	"kasap": ["Sucukla tanış!", "Kuşbaşı yaparım seni!", "Tavuk sandım, kovaladım!", "Gel gel, tartalım seni!"],
	"bekci": ["Uçuş ruhsatın var mı?!", "Düüüt! Hava sahası ihlali!", "Kanat plakan nerede?", "Karakola kadar uçacaksın!"],
	"balikci": ["Martılarımı ürküttün!", "Seni oltayla tutarım!", "Balık bile senden iyi uçar!", "Lüfer gibi kaçıyor!"],
	"hanim": ["Oklavayla tanış!", "Börek açıyordum, yarım kaldı!", "Kanatlarını yolarım!", "Çatımda tüy var!"],
	"berber": ["Bir tıraş yapalım!", "Sakal tıraşı bedava!", "Kolonya ister misin?!", "Sıradaki! SEN!"],
	"hamamci": ["Kese yapacağım seni!", "Hamam sefası yarım kaldı!", "Havlu kırbacı geliyor!", "Peştamalımı kaptım, geliyorum!"],
	"imam": ["Evladım bu ne hal?!", "Tövbe tövbe, adam uçuyor!", "Dur bir nasihat edeyim!", "Cemaati dağıttın!"],
}
const NEWS := ["Mahalle bakkalı: \"Kanat sattığım doğru değil, sadece çarşaf sattım.\"", "Martılar sendikası: \"Hava sahamız ihlal edildi.\"", "Uzmanlar uyarıyor: Terlik, bilinen en eski güdümlü füzedir.", "Şalvar sahibi teyze: \"Bilim umurumda değil, şalvarımı istiyorum!\"", "Hava durumu: Parçalı bulutlu, yer yer uçan adam.", "Simitçi: \"Bugün rekor kırdık, kovalayan acıkıyor.\"", "Kediler açıklama yaptı: \"Miyav.\"", "Vapur kaptanı: \"Akbil basmadan zıpladı, şikâyetçiyim.\"", "Kahvehane anketi: %83 \"Uçmasın\", %17 \"Bir daha uçsun da görelim\".", "Saray kaynakları: \"Padişahımız olaydan haberdar, gülmemeye çalışıyor.\"", "Mahalle muhtarlığı: \"Uçuş için dilekçe şart.\""]
const NAMES := {"teyze": "Ayşe Teyze", "amca": "Rıza Amca", "cocuk": "Haylaz Cemil", "kasap": "Kasap Hüsnü", "bekci": "Bekçi Cemal", "balikci": "Balıkçı Lütfü", "hanim": "Hatice Hanım", "berber": "Berber Sadık", "hamamci": "Hamamcı Rıfat", "imam": "İmam Efendi"}
const GL := {"karpuz": "Geçen sefer beni karpuzla devirdin!", "kedi": "Kedilere bastırdın beni, unutmadım!", "kova": "Beni ıslattın! Hâlâ kuruyorum!", "kafa": "Kafamdaki şişlik hâlâ geçmedi!", "terlik": "Kafama terlik yedirttin!", "halay": "Beni halaya kaptırdın, rezil oldum!", "patron": "Patron beni ezdi, senin yüzünden!", "tuval": "Tuvale çarptım, sen sebep oldun!"}
const WIN_L := ["Vurun!", "Kaçıyor, kaçıyor!", "Çay demledim, bekliyorum!", "Benim oğlan da uçmak istiyor!", "Ayyy, şalvar onda!", "Sessiz olun, bebek uyuyor!", "Bekçiii! Bekçi neredesin?!"]
const KAHVE_L := ["Bahse girerim kaçar!", "Yakalarlar, yakalarlar!", "Şeş beş! ...Pardon, kovalamaca.", "Bizim zamanımızda uçan adam yürürdü!", "Çaycı! İki çay, bir de dayak!", "Ben olsam fıçıyla uçardım.", "Oğlum otur, tavla bitmedi!"]
const SQ := [
	{"q": "Neden uçtun, Hezarfen?", "a": [["Bilim için, padişahım!", 1, "Bilim mi? Hmm... devam et."], ["Martılar kışkırttı.", 0, "Martılar mı?! Onlara da mı ferman yazalım?"], ["Üsküdar'da simit daha ucuz.", 2, "HA HA HA! Doğru söylüyor!"]]},
	{"q": "Kanatları neyden yaptın?", "a": [["Annemin çarşaflarından.", 2, "Annen biliyor mu? HA HA!"], ["Gizli formül, söyleyemem.", 0, "Padişahtan sır mı saklanır?!"], ["Kartal tüyü ve bolca dua.", 1, "Duası tuttu, belli."]]},
	{"q": "Bir daha uçacak mısın?", "a": [["Asla, padişahım!", 0, "Yalan söylüyor, gözünden belli."], ["Sadece cuma günleri.", 2, "HA HA! Cuma uçuşu, ne güzel!"], ["Siz emrederseniz saraya uçarım!", 1, "Saraya mı?! Dur bakalım..."]]},
	{"q": "Mahalleli seni neden kovaladı?", "a": [["Şalvar meselesi... uzun hikâye.", 2, "Şalvar mı?! HA HA HA!"], ["Kıskandılar, padişahım.", 1, "Kıskançlık, evet, olur."], ["Hiç kovalamadılar ki.", 0, "Kavuğun yamulmuş ama?"]]},
	{"q": "Uçarken sarayı gördün mü?", "a": [["Gördüm, çok güzeldi!", 1, "Tabii güzel, benim sarayım."], ["Göremedim, martıdan kaçıyordum.", 2, "HA HA! Martılar benim de başımın belası!"], ["Kubbeleri saydım, eksik yok!", 0, "Kubbe saymak senin işin mi?"]]},
	{"q": "Ödül olarak ne istersin?", "a": [["Bir kese altın yeter.", 1, "Mütevazı adam."], ["Bir ömür bedava simit.", 2, "HA HA! Simitçiye ferman yazın!"], ["Üsküdar'ın tapusu.", 0, "Çok istedin, çok!"]]},
]
const RANKS := [[2500, "Kanatlı Patates"], [4500, "Martı Stajyeri"], [6500, "Boğaz Akıncısı"], [9000, "Hezarfen-i Kebir"], [1000000000, "EFSANE: Uçtu da Ne Oldu?"]]
const TAGS := ["Wright kardeşlerden 270 yıl önce!", "Kanat garantisi yoktur.", "Mahalleli uyarısı: dayak içerir.", "Sertifikasız ilk Osmanlı pilotu.", "Galata → Üsküdar: 3358 metre saf cesaret."]

const WINGS := {
	"ev": {"n": "Ev Yapımı Kanat", "p": 0, "c": ["#d6c39b", "#f6ecd4"], "cost": 11, "regen": 3.4, "lift": 235, "spd": 215, "term": 105, "dmg": 1.0, "mult": 1.0},
	"yufka": {"n": "Baklava Yufkası", "p": 150, "c": ["#d9a441", "#f3cf7a"], "cost": 14, "regen": 3.0, "lift": 225, "spd": 205, "term": 120, "dmg": 1.2, "mult": 1.5, "crumbs": 1},
	"kartal": {"n": "Kartal Tüyü", "p": 400, "c": ["#6e4b2a", "#a8743f"], "cost": 8, "regen": 3.8, "lift": 240, "spd": 220, "term": 100, "dmg": 0.5, "mult": 1.0},
	"leylek": {"n": "Leylek Kanadı", "p": 650, "c": ["#2b2b2b", "#fafafa"], "cost": 10, "regen": 3.6, "lift": 235, "spd": 255, "term": 80, "dmg": 1.0, "mult": 1.0},
	"anka": {"n": "Zümrüdüanka", "p": 1500, "c": ["#c0392b", "#f39c12"], "cost": 8, "regen": 5.5, "lift": 250, "spd": 240, "term": 85, "dmg": 0.6, "mult": 1.2, "spark": 1},
}

const ROUTES := [
	{"n": "Galata → Üsküdar", "mus": "flight", "from": "GALATA", "to": "ÜSKÜDAR", "m": 3358, "len": 7000, "start": "galata", "mid": "kk",
		"sky": ["#4fa8e8", "#a9dcf5", "#ffe6b8"], "sun": [820, 90, "#fff1a8", 44], "sk": ["#b9cbe0", "#8ea7c6"], "wa": ["#3b8fc6", "#1c4f80", "#6fb6e3"],
		"hs": ["#e9b8a0", "#b8d4a8", "#f2dc96", "#b9c9e6", "#e7a9a9", "#d8c3e6"], "roof": "#8e3b24", "gull": 1.0, "carpet": 1.0, "wind": 1.0, "evliya": 0.6, "gr": ["#c6aa83", "#d4bc96", "#bfa27a", "#d9c39f"],
		"boss": {"n": "MAHALLE MUHTARI", "sub": "Mührü var, sabrı yok!", "body": "#5d4037", "sleeve": "#4e342e", "hat": "fes", "must": "#ddd", "item": "muhur", "lines": ["Bu uçuşa mühür basmam!", "İzin belgen nerede?!", "Mahallede uçmak yasak!", "Önce dilekçe, sonra uçuş!"]},
		"win": ["Sultan IV. Murad, Hezarfen'e bir kese altın verdi...", "...ve \"Bu adam çok tehlikeli, her istediğini yapabilir\" deyip onu Cezayir'e sürdü.", "(Cezayir'de de mahalleli var mıydı? Vardı.)"]},
	{"n": "Sarayburnu → Kadıköy", "mus": "sunset", "from": "SARAYBURNU", "to": "KADIKÖY", "m": 4120, "len": 7600, "start": "minare", "mid": "kk",
		"sky": ["#3b2a6b", "#e0607e", "#ffb86b"], "sun": [690, 350, "#ffcf6b", 90], "sk": ["#c98aa8", "#8e5d86"], "wa": ["#d0708a", "#4a2a5a", "#f0a0b0"],
		"hs": ["#f5c6a5", "#f7dc6f", "#e59866", "#f5b7b1", "#d7bde2", "#fad7a0"], "roof": "#7a2e1e", "gull": 1.25, "carpet": 1.7, "wind": 1.3, "evliya": 1.0, "gr": ["#c9a58a", "#d6b49a", "#bb977c", "#dcc0a8"],
		"boss": {"n": "KADI EFENDİ", "sub": "Hüküm hazır: DAYAK!", "body": "#1a237e", "sleeve": "#121858", "hat": "sarik", "beard": "#aaa", "must": "#aaa", "item": "tokmak", "lines": ["Hüküm veriyorum: DAYAK!", "Mahkeme seni çağırıyor!", "Uçmak kanuna aykırı!", "Tokmağı vuracağım, ama sana!"]},
		"win": ["Kadıköylüler Hezarfen'i çay bahçesine davet etti...", "...ve hesabı ona ödettiler. 47 çay, 12 simit.", "Hezarfen o gün, kaçmanın uçmaktan pahalı olduğunu öğrendi."]},
	{"n": "Galata → Eyüp (Gece)", "mus": "gece", "from": "GALATA", "to": "EYÜP", "m": 4800, "len": 8200, "start": "galata", "mid": "gemi", "night": 1,
		"sky": ["#0b1030", "#1f2a5c", "#4a4f86"], "sun": [800, 90, "#f5f3d0", 34], "sk": ["#2d3a6a", "#1c2448"], "wa": ["#1d3557", "#0b1a30", "#3a5f8a"],
		"hs": ["#7d6b8f", "#6b7f9b", "#8a7a6a", "#6f8f7f", "#9a7a8a", "#7a8aa0"], "roof": "#4a2a3a", "gull": 1.3, "carpet": 1.0, "wind": 1.5, "evliya": 0.5, "gr": ["#8a8292", "#958d9e", "#7e7787", "#a199a8"],
		"boss": {"n": "YENİÇERİ AĞASI", "sub": "Kazan kaldırdı, sıra sende!", "body": "#7b241c", "sleeve": "#641e16", "hat": "yenicer", "must": "#222", "item": "kepce", "lines": ["Kazan kaldırırım!", "Bu ne biçim nizam?!", "Kepçeyle tanış!", "Ocak seni bekliyor!"]},
		"win": ["Eyüp'te gece bekçisi fermanı fener ışığında okudu...", "...\"Uçan adamı rahat bırakın\" yazıyordu. Bekçi yine de bir düdük çaldı.", "Hezarfen sabaha kadar uyuyamadı. Düdük hâlâ kulağındaydı."]},
	{"n": "Cezayir: Liman → Kasbah", "mus": "cezayir", "from": "LİMAN", "to": "KASBAH", "m": 5500, "len": 9000, "start": "fener", "mid": "korsan",
		"sky": ["#2fa8f0", "#9fe3ff", "#fff3c4"], "sun": [820, 80, "#fffbe0", 44], "sk": ["#e8d3a8", "#cfb07a"], "wa": ["#1abc9c", "#0e6655", "#76e4cf"],
		"hs": ["#f7f7f2", "#f1ece0", "#e9f2f7", "#fff7e6", "#eaf5ea", "#f5eee0"], "roof": "#c8794a", "gull": 1.5, "carpet": 2.0, "wind": 1.4, "evliya": 0.4, "gr": ["#e0c9a0", "#ead6b0", "#d6bd90", "#efdcb8"],
		"boss": {"n": "CEZAYİR DAYISI", "sub": "Burada da mı uçuyorsun?!", "body": "#ecf0f1", "sleeve": "#bdc3c7", "hat": "sarik", "sarikc": "#e74c3c", "must": "#111", "beard": "#111", "item": "tokmak", "lines": ["Burada da mı uçuyorsun?!", "Dayı benim, dayak benden!", "İstanbul seni geri istemedi!", "Kasbah'ta uçmak yasak!"]},
		"win": ["Cezayir Dayısı fermanı okudu, güldü, bir daha okudu...", "...\"Bunu İstanbul'a geri yollayın, bizde zaten yeterince deli var\" dedi.", "Hezarfen eve vapurla döndü. Ve tabii ki çatıdan uçmayı planlıyordu."]},
]

const RIV := {
	"fici": {"n": "Fıçılı Fehmi", "l": ["Fıçıyla uçmak daha sağlam!", "Turşu fıçısı ama olsun!", "Önce ben uçtum!"], "f": "Fıçının dibi delikmiş!"},
	"ucurtma": {"n": "Uçurtmacı Nuri", "l": ["Rüzgâr benden yana!", "İpim sağlam, merak etme!", "Patent başvurum var!"], "f": "İp koptuuu!"},
	"kazan": {"n": "Kazancı Kemal", "l": ["Buhar gücü geleceğin enerjisi!", "Kazan kaynıyor, ben uçuyorum!", "Çorba da pişiyor bu arada!"], "f": "Kazan taştı!"},
}

## kıyıdaki mahalleli (web sürümündeki VT'nin uçuş için gereken kısmı)
const VT := {
	"teyze": {"body": "#8e44ad", "sleeve": "#6c3483", "hat": "scarf", "scarf": "#e74c3c", "item": "terlik", "speed": 120.0, "r": 16.0, "throws": 1, "shoe": "#333", "skin": "#f3c9a0", "wide": 1.15},
	"amca": {"body": "#6d7f3c", "sleeve": "#55632e", "hat": "fes", "item": "baston", "speed": 95.0, "r": 16.0, "beard": "#e6e6e6", "must": "#e6e6e6"},
	"cocuk": {"body": "#e67e22", "sleeve": "#ca6a17", "hat": "cap", "capc": "#2980b9", "item": "sapan", "speed": 185.0, "r": 13.0, "s": 0.78},
	"kasap": {"body": "#c0392b", "sleeve": "#a03024", "hat": "bald", "apron": 1, "item": "sucuk", "speed": 135.0, "r": 21.0, "must": "#3b2a1e", "wide": 1.3, "s": 1.12},
	"bekci": {"body": "#2c3e70", "sleeve": "#22305a", "hat": "bekci", "item": "cop", "speed": 158.0, "r": 16.0, "must": "#222"},
	"balikci": {"body": "#2e86c1", "sleeve": "#2471a3", "hat": "takke", "item": "balik", "speed": 130.0, "r": 16.0, "beard": "#5a3a20"},
	"hanim": {"body": "#16a085", "sleeve": "#138d75", "hat": "scarf", "scarf": "#f1c40f", "item": "oklava", "speed": 140.0, "r": 16.0, "wide": 1.1, "throws": 0},
	"berber": {"body": "#fdfefe", "sleeve": "#d5dbdb", "hat": "bald", "item": "firca", "speed": 165.0, "r": 15.0, "must": "#111", "throws": "kopuk"},
	"hamamci": {"body": "#f0b98a", "sleeve": "#e8a877", "skin": "#f0b98a", "hat": "havlu", "item": "havlu", "speed": 128.0, "r": 18.0, "must": "#333", "pants": "#c0392b", "sash": "#fff", "wide": 1.2, "melee": 1},
	"imam": {"body": "#34495e", "sleeve": "#2c3e50", "hat": "sarik", "beard": "#e6e6e6", "must": "#e6e6e6", "item": "tespih", "speed": 100.0, "r": 16.0, "throws": "tespih"},
}
const HEZ := {"body": "#9c3b26", "sleeve": "#7a2c1b", "sash": "#e3b23c", "hat": "kavuk", "beard": "#4a2c17", "must": "#4a2c17", "skin": "#f0c08a", "pants": "#5a3b22", "shoe": "#c0392b", "wings": true}

const SAVE_PATH := "user://hez_save.json"
var save_data := {}

func _ready() -> void:
	var s := {}
	if FileAccess.file_exists(SAVE_PATH):
		var t := FileAccess.get_file_as_string(SAVE_PATH)
		var j = JSON.parse_string(t)
		if j is Dictionary:
			s = j
	var defaults := {"akce": 0, "wings": ["ev"], "wing": "ev", "hats": ["kavuk"], "hat": "kavuk", "ach": {}, "unl": 1, "route": 0, "wins": {}, "best": 0, "vo": 2, "muted": false, "grudge": {}, "gh": {}}
	for k in defaults:
		if not s.has(k):
			s[k] = defaults[k]
	s["unl"] = int(s["unl"]); s["route"] = int(s["route"]); s["akce"] = int(s["akce"])
	if not (s["route"] < s["unl"] and s["route"] < ROUTES.size()):
		s["route"] = 0
	save_data = s

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data))

func route() -> Dictionary:
	return ROUTES[save_data["route"]]

func wing() -> Dictionary:
	return WINGS[save_data["wing"]]

func hez_opts(e: Dictionary) -> Dictionary:
	var o := HEZ.duplicate()
	o["hat"] = save_data["hat"]
	o["wc"] = WINGS[save_data["wing"]]["c"]
	o.merge(e, true)
	return o
