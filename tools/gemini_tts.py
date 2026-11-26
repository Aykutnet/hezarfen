"""Hezarfen replikleri için Gemini 3.8 Flash TTS ile seslendirme.

Kullanım:
  python tools/gemini_tts.py design            # karakter seslerini tasarla (voices/gemini_voices.json)
  python tools/gemini_tts.py sample            # birkaç örnek replik üret (voices/gemini_preview/)
  python tools/gemini_tts.py all               # tüm replikleri üret (voices/gemini_raw/)
  python tools/gemini_tts.py finalize          # mp3'e çevir + voices/manifest.json

API anahtarı GEMINI_API_KEY ortam değişkeninden (yoksa Windows kullanıcı ortamından) okunur;
hiçbir dosyaya yazılmaz.
"""
import base64, hashlib, json, os, subprocess, sys, time, urllib.error, urllib.request
from concurrent.futures import ThreadPoolExecutor

API = "https://generativelanguage.googleapis.com/v1beta"
MODEL = "gemini-3.8-flash-tts"
VOICES_FILE = "voices/gemini_voices.json"
RAW = "voices/gemini_raw"
PREVIEW = "voices/gemini_preview"


def api_key():
    k = os.environ.get("GEMINI_API_KEY")
    if not k and sys.platform == "win32":
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as h:
            k = winreg.QueryValueEx(h, "GEMINI_API_KEY")[0]
    if not k:
        raise SystemExit("GEMINI_API_KEY bulunamadı")
    return k


KEY = None


def req(method, path, body=None, tries=6):
    global KEY
    KEY = KEY or api_key()
    data = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    for i in range(tries):
        r = urllib.request.Request(API + path, data=data, method=method,
                                   headers={"x-goog-api-key": KEY, "Content-Type": "application/json; charset=utf-8"})
        try:
            with urllib.request.urlopen(r, timeout=180) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "ignore")[:400]
            if e.code in (429, 500, 503) and i < tries - 1:
                time.sleep(min(60, 4 * 2 ** i))
                continue
            raise RuntimeError("HTTP %d: %s" % (e.code, msg))
        except urllib.error.URLError:
            if i < tries - 1:
                time.sleep(3)
                continue
            raise


# ---------------------------------------------------------------- karakter sesleri
# (ad, cinsiyet, tarif)
CAST = {
    "hez": ("male", "A Turkish man in his early 30s with a warm, bright, expressive tenor voice and a clear Istanbul accent. Lively and animated, great comic timing."),
    "teyze": ("female", "A lively Turkish woman in her 60s with a high, bright, slightly raspy voice and a strong Istanbul accent. Expressive and animated."),
    "hanim": ("female", "A Turkish woman in her 40s with a clear, crisp, energetic voice and an Istanbul accent. Brisk and expressive."),
    "kiz": ("female", "A Turkish woman in her early 20s with a smooth, cool, slightly dry voice. Modern and expressive."),
    "cocuk": ("male", "A 10-year-old Turkish boy with a high, bright, playful voice. Fast and energetic."),
    "amca": ("male", "A Turkish man in his 70s with a gravelly, cracked, slow old voice and a warm Istanbul accent."),
    "kasap": ("male", "A large Turkish man in his 40s with a very deep, booming, chesty bass voice."),
    "bekci": ("male", "A Turkish man in his 50s with a nasal, precise, formal voice, like a strict official."),
    "balikci": ("male", "A Turkish fisherman in his 50s with a raspy, weathered, loud voice."),
    "berber": ("male", "A Turkish man in his 30s with a bright, sing-song, fast-talking voice. Chatty and theatrical."),
    "hamamci": ("male", "A big Turkish man in his 40s with a round, hearty, booming voice and a jolly tone."),
    "imam": ("male", "A Turkish man in his 70s with a soft, calm, gentle, slow voice."),
    "padisah": ("male", "A Turkish man in his late 20s with a deep, rich, regal and theatrical voice, like a stage actor playing an emperor."),
    "ulak": ("male", "A young Turkish man in his 20s with a loud, clear, ringing announcer voice."),
    "gull": ("male", "A cartoon character voice: very high, scratchy, squawky and fast, like an animated seagull."),
    "fish": ("male", "A cartoon character voice: low, slow, bubbly and deadpan, like an animated fish."),
    "carpet": ("male", "A Turkish man in his 40s with a slightly nasal, polished salesman voice. Confident and showy."),
    "kaptan": ("male", "A Turkish sea captain in his 50s with a gravelly, loud, commanding voice."),
    "karpuzcu": ("male", "A Turkish man in his 30s with a high, reedy, emotional voice."),
    "evliya": ("male", "A Turkish man in his 40s with a warm, curious, storyteller voice, full of wonder."),
    "ressam": ("male", "A Turkish man in his 30s with a refined, precise, slightly dramatic artistic voice."),
    "anlatici": ("male", "A Turkish male sports commentator with an energetic, booming, dramatic broadcast voice."),
    "boss0": ("male", "A Turkish man in his 50s with a pompous, fussy, self-important official voice."),
    "boss1": ("male", "A Turkish man in his 60s with a deep, solemn, theatrical judge's voice."),
    "boss2": ("male", "A Turkish man in his 40s with a loud, gruff, commanding military voice."),
    "boss3": ("male", "A man in his 50s with a gravelly, low, swaggering voice and a slight North African accent speaking Turkish."),
    "mahalle_e": ("male", "A Turkish man in his 40s with a loud, rough, everyday Istanbul street voice."),
    "mahalle_k": ("female", "A Turkish woman in her 40s with a loud, sharp, everyday Istanbul street voice."),
}
FEMALE_WHO = {"teyze", "hanim", "kiz"}

# karakterin genel oynayış tarzı
BASE_STYLE = {
    "hez": "comic, expressive, energetic", "teyze": "furious, shrieking", "hanim": "angry, scolding", "kiz": "annoyed, sarcastic",
    "cocuk": "cheeky, excited", "amca": "grumpy, gravelly", "kasap": "menacing, booming", "bekci": "officious, indignant",
    "balikci": "gruff, loud", "berber": "fast, theatrical", "hamamci": "hearty, booming", "imam": "calm but bewildered",
    "padisah": "regal, theatrical", "ulak": "urgent, breathless, loud", "gull": "screechy, rude", "fish": "deadpan, dry",
    "carpet": "smug, boastful", "kaptan": "gruff, barking", "karpuzcu": "panicked, wailing", "evliya": "amazed, witty",
    "ressam": "dramatic, fussy", "anlatici": "dramatic announcer, energetic", "boss": "pompous, threatening, loud",
    None: "angry, loud, indignant",
}
# önemli repliklere özel yönerge
OVERRIDE = {
    "O BENİM ŞALVARIM!!!": "screaming at the top of her lungs, outraged",
    "CİN BU, CİN!": "terrified and yelling",
    "Bismillaaaah!": "screaming bravely while jumping off a tower, long drawn-out shout",
    "Eee... bilim?": "sheepish, awkward, hesitant",
    "İNDİM! TARİH YAZDIM!": "triumphant, overjoyed shouting",
    "DURUUUUUN!": "very loud long drawn-out shout, out of breath",
    "Kanatlar grev yaptı! İniyoruuum!": "panicked, falling, yelling",
    "Dur! Güneşe yaklaşma, İkarus'u biliyoruz!": "talking to himself, alarmed",
    "Aşağı bakma Ahmet, aşağı bakma...": "nervous whisper to himself",
    "Annemden öğrendim!": "proud, menacing",
}


def style_for(text, owner):
    if text in OVERRIDE:
        return OVERRIDE[text]
    s = BASE_STYLE.get(owner, BASE_STYLE[None])
    t = text.strip()
    if t.endswith("!!!") or (t.isupper() and len(t) > 4):
        s += ", shouting very loudly"
    elif t.endswith("?!"):
        s += ", outraged disbelief"
    elif t.endswith("!"):
        s += ", exclaiming"
    elif t.endswith("?"):
        s += ", questioning"
    if "..." in t:
        s += ", with a dramatic pause"
    if "HA HA" in t or "KAH KAH" in t:
        s += ", laughing heartily"
    return s


def boss_index(text):
    src = open("index.html", encoding="utf-8").read()
    i = src.index("const ROUTES=[")
    blocks = src[i:src.index("];", i)].split("{n:'")[1:]
    for bi, b in enumerate(blocks):
        if text.replace("'", "\\'") in b:
            return bi
    return 0


def tts_text(t):
    return t.replace("→", " ").replace("•", " ")


# ---------------------------------------------------------------- komutlar
def design():
    voices = json.load(open(VOICES_FILE, encoding="utf-8")) if os.path.exists(VOICES_FILE) else {}
    os.makedirs(PREVIEW, exist_ok=True)

    def one(name):
        if name in voices:
            return
        g, desc = CAST[name]
        r = req("POST", "/voices", {"store": True, "voice": {"model": MODEL, "type": "prompted", "display_name": "hezarfen_" + name,
                                                             "gender": g, "language_code": "tr-TR", "prompted": {"input": desc}}})
        vid = r.get("id") or r.get("name", "").split("/")[-1] or r.get("voice", {}).get("id")
        if not vid:
            raise RuntimeError("ses kimliği yok: %r" % list(r.keys()))
        voices[name] = vid
        sa = r.get("sample_audio") or r.get("voice", {}).get("sample_audio")
        if sa and sa.get("data"):
            open(os.path.join(PREVIEW, "ses_%s.wav" % name), "wb").write(base64.b64decode(sa["data"]))
        print("ses tasarlandı:", name, flush=True)

    with ThreadPoolExecutor(4) as ex:
        for f in [ex.submit(one, n) for n in CAST]:
            try:
                f.result()
            except Exception as e:
                print("HATA:", e, flush=True)
    json.dump(voices, open(VOICES_FILE, "w", encoding="utf-8"), indent=1)
    print(len(voices), "/", len(CAST), "ses hazır")


def synth(text, voice_id, style, out):
    body = {"model": MODEL, "input": [{"type": "user_input", "content": [{"type": "text", "text": tts_text(text),
             "annotations": [{"type": "speech_metadata", "style": style}]}]}],
            "response_format": {"type": "audio"}, "generation_config": {"speech_config": [{"voice": voice_id}]}}
    r = req("POST", "/interactions", body)
    data = None
    for st in r.get("steps", []):
        if st.get("type") == "model_output":
            for c in st.get("content", []):
                if c.get("type") == "audio" and c.get("data"):
                    data = c["data"]
    if not data:
        raise RuntimeError("ses verisi yok: %s" % json.dumps(r)[:300])
    open(out, "wb").write(base64.b64decode(data))


def jobs():
    """(çıktı adı, metin, ses adı, tarz, sahip, kadın varyantı mı)"""
    man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
    out = []
    for text, (fid, owner) in man.items():
        if owner is None:
            out.append((fid, text, "mahalle_e", style_for(text, None), None, False))
            out.append((fid + "f", text, "mahalle_k", style_for(text, None), None, True))
        else:
            v = "boss%d" % boss_index(text) if owner == "boss" else owner
            out.append((fid, text, v, style_for(text, owner), owner, False))
    return out


def run(selected, outdir):
    voices = json.load(open(VOICES_FILE, encoding="utf-8"))
    os.makedirs(outdir, exist_ok=True)
    done = [0]

    def one(j):
        name, text, v, style, _, _ = j
        out = os.path.join(outdir, name + ".wav")
        if os.path.exists(out) and os.path.getsize(out) > 2000:
            return
        synth(text, voices[v], style, out)
        done[0] += 1
        print("[%d/%d] %s (%s) %s" % (done[0], len(selected), name, v, text[:40]), flush=True)

    with ThreadPoolExecutor(4) as ex:
        for f in [ex.submit(one, j) for j in selected]:
            try:
                f.result()
            except Exception as e:
                print("HATA:", e, flush=True)


SAMPLES = ["Bismillaaaah!", "O BENİM ŞALVARIM!!!", "Gel buraya kuş bozuntusu!", "Sucukla tanış!", "Demek uçan adam sensin! Anlat bakalım...",
           "Bilet!", "Önüne baksana!", "SİMİT VER!", "Ne bakıyon?", "Eee... bilim?"]


def finalize():
    man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
    out, total = {}, 0
    for text, (fid, owner) in man.items():
        ent = [fid, owner]
        for name in ([fid] if owner is not None else [fid, fid + "f"]):
            src = os.path.join(RAW, name + ".wav")
            dst = os.path.join("voices", name + ".mp3")
            if not os.path.exists(src):
                ent = None
                break
            if not os.path.exists(dst) or os.path.getmtime(dst) < os.path.getmtime(src):
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-af",
                                "silenceremove=start_periods=1:start_threshold=-45dB,loudnorm=I=-16:TP=-1.5",
                                "-ac", "1", "-ar", "32000", "-b:a", "48k", dst], check=True)
            total += os.path.getsize(dst)
            if name.endswith("f") and owner is None:
                ent.append(name)
        if ent:
            out[text] = ent
    json.dump(out, open("voices/manifest.json", "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(len(out), "/", len(man), "replik,", round(total / 1e6, 2), "MB")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "design":
        design()
    elif cmd == "sample":
        js = jobs()
        run([j for j in js if j[1] in SAMPLES and not j[5]], PREVIEW)
    elif cmd == "all":
        run(jobs(), RAW)
    elif cmd == "finalize":
        finalize()
    else:
        print(__doc__)
