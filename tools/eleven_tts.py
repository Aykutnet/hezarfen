"""Hezarfen replikleri için ElevenLabs (eleven_v4) seslendirme.

Kullanım:
  python tools/eleven_tts.py sample      # her sesten bir örnek (voices/eleven_preview/)
  python tools/eleven_tts.py all         # tüm replikler (voices/eleven_raw/)
  python tools/eleven_tts.py finalize    # voices/*.mp3 + voices/manifest.json

API anahtarı ELEVENLABS_API_KEY ortam değişkeninden (yoksa Windows kullanıcı ortamından) okunur.
"""
import json, os, re, subprocess, sys, time, urllib.error, urllib.request
from concurrent.futures import ThreadPoolExecutor

API = "https://api.elevenlabs.io/v1"
MODEL = "eleven_v4"
RAW = "voices/eleven_raw"
PREVIEW = "voices/eleven_preview"

# karakter -> ElevenLabs kütüphane sesi
V = {
    "arman": "r1r1ppYo40wJjlxE95dP", "duygu": "Rnbz9MZgX4nkmTzXgezp", "ezgi": "BMRQG4PIovkwKTk46STk",
    "deniz": "2w5twzryiFg9VNnXphRP", "onur": "cuqE298lnnTMNFYuX9DI", "seyfullah": "mF7tIc9VLrznhGooGjaT",
    "nihat": "MuOq11XzQTthwLhmGZ2V", "alp": "QKYtglm8EuIgEe3ZmvUj", "dogan": "KeCJmqttICgReHIwS66F",
    "arif": "oafr6pIDZj0XlLA4eHub",
}
CAST = {
    "hez": "arman", "teyze": "duygu", "hanim": "duygu", "mahalle_k": "duygu", "kiz": "ezgi",
    "cocuk": "deniz", "gull": "deniz", "fish": "deniz",
    "kasap": "onur", "hamamci": "onur", "kaptan": "onur", "boss2": "onur",
    "amca": "seyfullah", "imam": "seyfullah", "boss1": "seyfullah",
    "padisah": "nihat", "boss3": "nihat", "anlatici": "alp", "ulak": "alp",
    "bekci": "dogan", "berber": "dogan", "balikci": "dogan", "karpuzcu": "dogan", "boss0": "dogan", "mahalle_e": "dogan",
    "evliya": "arif", "ressam": "arif", "carpet": "arif",
}
# karakterin oynayış etiketi (aynı sesi farklı karakter gibi oynatır)
TAG = {
    "hez": "[excited]", "teyze": "[furious, shrill old woman]", "hanim": "[angry, scolding]", "mahalle_k": "[angry]",
    "kiz": "[annoyed, sarcastic]", "cocuk": "[cheeky little boy, giggling]", "gull": "[squawking, screechy cartoon seagull]",
    "fish": "[deadpan, slow, bubbly]", "kasap": "[menacing, deep]", "hamamci": "[hearty, booming]", "kaptan": "[gruff, barking]",
    "boss2": "[gruff military bark]", "amca": "[grumpy old man]", "imam": "[calm, gentle, bewildered]", "boss1": "[stern, solemn judge]",
    "padisah": "[regal, theatrical]", "boss3": "[menacing swagger]", "anlatici": "[dramatic announcer]", "ulak": "[urgent, out of breath]",
    "bekci": "[officious, nasal]", "berber": "[fast, chatty, theatrical]", "balikci": "[gruff, salty]", "karpuzcu": "[panicked, wailing]",
    "boss0": "[pompous, fussy]", "mahalle_e": "[angry]", "evliya": "[amazed, curious]", "ressam": "[dramatic, fussy artist]",
    "carpet": "[smug, boastful]",
}
OVERRIDE = {
    "O BENİM ŞALVARIM!!!": "[screaming at the top of her lungs, outraged]",
    "CİN BU, CİN!": "[terrified, yelling]",
    "Bismillaaaah!": "[screaming bravely, jumping]",
    "Eee... bilim?": "[sheepish, awkward]",
    "İNDİM! TARİH YAZDIM!": "[triumphant, overjoyed]",
    "DURUUUUUN!": "[shouting, out of breath]",
    "Kanatlar grev yaptı! İniyoruuum!": "[panicked, falling, yelling]",
    "Aşağı bakma Ahmet, aşağı bakma...": "[nervous whisper]",
    "Teşekkürler, tam benim boyum!": "[deadpan, satisfied]",
}
FEMALE_WHO = {"teyze", "hanim", "kiz"}


def api_key():
    k = os.environ.get("ELEVENLABS_API_KEY")
    if not k and sys.platform == "win32":
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as h:
            k = winreg.QueryValueEx(h, "ELEVENLABS_API_KEY")[0]
    if not k:
        raise SystemExit("ELEVENLABS_API_KEY bulunamadı")
    return k


KEY = None


def tts(text, voice_id, out, tries=5):
    global KEY
    KEY = KEY or api_key()
    body = json.dumps({"text": text, "model_id": MODEL, "language_code": "tr"}, ensure_ascii=False).encode("utf-8")
    for i in range(tries):
        r = urllib.request.Request("%s/text-to-speech/%s?output_format=mp3_44100_128" % (API, voice_id), data=body, method="POST",
                                   headers={"xi-api-key": KEY, "Content-Type": "application/json", "Accept": "audio/mpeg"})
        try:
            with urllib.request.urlopen(r, timeout=120) as resp:
                open(out, "wb").write(resp.read())
                return
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "ignore")[:300]
            if e.code in (429, 500, 502, 503) and i < tries - 1:
                time.sleep(3 * 2 ** i)
                continue
            raise RuntimeError("HTTP %d: %s" % (e.code, msg))


def tag_for(text, who):
    if text in OVERRIDE:
        return OVERRIDE[text]
    t = TAG.get(who, "[angry]")
    s = text.strip()
    extra = []
    if s.endswith("!!!") or (s.upper() == s and len(s) > 4 and re.search("[A-ZÇĞİÖŞÜ]", s)):
        extra.append("shouting")
    elif s.endswith("?!"):
        extra.append("outraged")
    if "HA HA" in s or "KAH KAH" in s:
        extra.append("laughing")
    if extra:
        t = t[:-1] + ", " + ", ".join(extra) + "]"
    return t


def boss_index(text):
    src = open("index.html", encoding="utf-8").read()
    i = src.index("const ROUTES=[")
    arrs = re.findall(r"boss:\{n:'.*?lines:\[(.*?)\]", src[i:src.index("];", i)])
    for bi, body in enumerate(arrs):
        if "'" + text + "'" in body.replace("\\'", "'"):
            return bi
    return 0


def jobs():
    man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
    out = []
    for text, (fid, owner) in man.items():
        if owner is None:
            out.append((fid, text, "mahalle_e"))
            out.append((fid + "f", text, "mahalle_k"))
        else:
            out.append((fid, text, "boss%d" % boss_index(text) if owner == "boss" else owner))
    return out


def clean(text):
    return text.replace("→", " ").replace("•", " ")


def run(selected, outdir):
    os.makedirs(outdir, exist_ok=True)
    n = [0]

    def one(j):
        name, text, who = j
        out = os.path.join(outdir, name + ".mp3")
        if os.path.exists(out) and os.path.getsize(out) > 1500:
            return
        tts(tag_for(text, who) + " " + clean(text), V[CAST[who]], out)
        n[0] += 1
        print("[%d/%d] %s (%s/%s) %s" % (n[0], len(selected), name, who, CAST[who], text[:40]), flush=True)

    with ThreadPoolExecutor(3) as ex:
        for f in [ex.submit(one, j) for j in selected]:
            try:
                f.result()
            except Exception as e:
                print("HATA:", e, flush=True)


SAMPLES = {"hez": "Bismillaaaah!", "teyze": "O BENİM ŞALVARIM!!!", "kiz": "Burası özel mülk! ...Yine mi sen?!", "cocuk": "Abi bana da kanat yap!",
           "kasap": "Sucukla tanış!", "amca": "Bizim zamanımızda yürürdük!", "padisah": "Demek uçan adam sensin! Anlat bakalım...",
           "anlatici": "KARPUZ ARABASI KAÇTI!", "bekci": "Uçuş ruhsatın var mı?!", "evliya": "Bunu Seyahatname'ye yazacağım, kimse inanmayacak!"}


def finalize():
    man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
    out, total = {}, 0
    for text, (fid, owner) in man.items():
        names = [fid] if owner is not None else [fid, fid + "f"]
        if not all(os.path.exists(os.path.join(RAW, n + ".mp3")) for n in names):
            continue
        for n in names:
            src = os.path.join(RAW, n + ".mp3")
            dst = os.path.join("voices", n + ".mp3")
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-af",
                            "silenceremove=start_periods=1:start_threshold=-45dB,loudnorm=I=-16:TP=-1.5",
                            "-ac", "1", "-ar", "32000", "-b:a", "48k", dst], check=True)
            total += os.path.getsize(dst)
        out[text] = [fid, owner] + ([fid + "f"] if owner is None else [])
    json.dump(out, open("voices/manifest.json", "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(len(out), "/", len(man), "replik,", round(total / 1e6, 2), "MB")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "test":
        os.makedirs(PREVIEW, exist_ok=True)
        tts(tag_for("Bismillaaaah!", "hez") + " Bismillaaaah!", V["arman"], os.path.join(PREVIEW, "test.mp3"))
        print("ok", os.path.getsize(os.path.join(PREVIEW, "test.mp3")), "bayt")
    elif cmd == "sample":
        man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
        run([("ornek_" + who, t, who) for who, t in SAMPLES.items()], PREVIEW)
    elif cmd == "all":
        run(jobs(), RAW)
    elif cmd == "finalize":
        finalize()
    else:
        print(__doc__)
