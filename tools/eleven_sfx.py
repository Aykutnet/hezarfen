"""Hezarfen ses efektleri: ElevenLabs Sound Effects ile üretim.

Kullanım:
  python tools/eleven_sfx.py sample     # birkaç örnek (sfx/preview/)
  python tools/eleven_sfx.py all        # tüm efektler, her biri N varyasyon (sfx/raw/)
  python tools/eleven_sfx.py finalize   # sfx/*.mp3 + sfx/manifest.json

Anahtar ELEVENLABS_API_KEY ortam değişkeninden okunur.
"""
import json, os, subprocess, sys, time, urllib.error, urllib.request
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(__file__))
from eleven_tts import api_key

API = "https://api.elevenlabs.io/v1/sound-generation"

# ad: (tarif, süre sn, varyasyon sayısı)
SFX = {
    "flap": ("Quick whoosh of large cloth and feather wings flapping once, cartoon game sound effect, no music", 0.7, 3),
    "jump": ("Cartoon jump whoosh with a short springy boing, game sound effect", 0.6, 1),
    "splash": ("Comedic big splash of a person falling into the sea, cartoon game sound effect", 1.5, 2),
    "bonk": ("Cartoon bonk hit on the head, comedic smack, game sound effect", 0.5, 3),
    "squawk": ("A single angry seagull squawk, close up", 0.8, 3),
    "whistle": ("Old police whistle blown twice sharply, short", 1.0, 2),
    "boing": ("Cartoon trampoline boing spring bounce sound", 0.7, 2),
    "dash": ("Fast cartoon swoosh, quick dash whoosh past the camera", 0.5, 2),
    "meow": ("A single annoyed cat meow, close up", 0.8, 2),
    "slip": ("Cartoon slip on a wet floor, squeaky slide whistle down", 0.8, 1),
    "crash": ("Comedic crash of wood and pottery falling, cartoon game sound effect", 1.2, 2),
    "throw": ("Short whoosh of a slipper thrown through the air", 0.5, 2),
    "yell": ("Angry crowd of Turkish townspeople shouting and yelling in the distance, no words, short", 1.2, 2),
    "yellHigh": ("An angry old woman's high-pitched shriek, short, no words", 0.8, 1),
    "gasp": ("A small group of people gasping in surprise", 0.7, 1),
    "cricket": ("Awkward silence with a few crickets chirping, comedic", 1.5, 1),
    "fanfare": ("Short triumphant Ottoman mehter military band fanfare with zurna and big drum, victory sting", 2.0, 1),
    "sad": ("Short comedic sad trombone wah wah wah, fail sting", 2.0, 1),
    "thud": ("Heavy body thud landing on the ground, cartoon impact", 0.6, 2),
    "eat": ("Quick crunchy bite and chewing of a sesame bagel", 0.6, 1),
    "rumble": ("Wooden cart with heavy wheels rumbling fast over cobblestones", 1.6, 1),
    "drum": ("Loud single boom of a big Turkish davul bass drum, close up, punchy", 1.0, 2),
    "clang": ("Metal pot lid struck, loud comedic clang with ringing", 0.8, 1),
    "stamp": ("Loud heavy stamp slammed hard onto a wooden desk, strong thump", 1.0, 1),
    "whip": ("Wet towel whip crack snap", 0.5, 2),
    "splat": ("Wet comedic splat of foam or a watermelon smashing", 0.5, 2),
    "laugh": ("A powerful king laughing heartily, booming belly laugh, no words", 1.8, 1),
}


def gen(text, dur, out, tries=5):
    key = api_key()
    body = json.dumps({"text": text, "duration_seconds": dur, "prompt_influence": 0.6}).encode("utf-8")
    for i in range(tries):
        r = urllib.request.Request(API + "?output_format=mp3_44100_128", data=body, method="POST",
                                   headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
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


def run(outdir, names=None):
    os.makedirs(outdir, exist_ok=True)
    jobs = []
    for n, (text, dur, var) in SFX.items():
        if names and n not in names:
            continue
        for v in range(var):
            jobs.append((n, v, text, dur))

    def one(j):
        n, v, text, dur = j
        out = os.path.join(outdir, "%s_%d.mp3" % (n, v))
        if os.path.exists(out) and os.path.getsize(out) > 1000:
            return
        gen(text, dur, out)
        print("üretildi:", os.path.basename(out), flush=True)

    with ThreadPoolExecutor(3) as ex:
        for f in [ex.submit(one, j) for j in jobs]:
            try:
                f.result()
            except Exception as e:
                print("HATA:", e, flush=True)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "sample":
        run("sfx/preview", ["flap", "splash", "bonk", "squawk", "whistle"])
    elif cmd == "all":
        import shutil
        os.makedirs("sfx/raw", exist_ok=True)
        for f in os.listdir("sfx/preview"):
            if f.endswith(".mp3") and not os.path.exists(os.path.join("sfx/raw", f)):
                shutil.copy(os.path.join("sfx/preview", f), os.path.join("sfx/raw", f))
        run("sfx/raw")
    elif cmd == "finalize":
        man = {}
        os.makedirs("sfx", exist_ok=True)
        total = 0
        for n, (_, _, var) in SFX.items():
            files = []
            for v in range(var):
                src = os.path.join("sfx/raw", "%s_%d.mp3" % (n, v))
                if not os.path.exists(src):
                    continue
                dst = os.path.join("sfx", "%s_%d.mp3" % (n, v))
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-af",
                                "silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-16:TP=-1.5",
                                "-ac", "1", "-ar", "32000", "-b:a", "64k", dst], check=True)
                total += os.path.getsize(dst)
                files.append("%s_%d" % (n, v))
            if files:
                man[n] = files
        json.dump(man, open("sfx/manifest.json", "w", encoding="utf-8"), separators=(",", ":"))
        print(len(man), "efekt,", sum(len(v) for v in man.values()), "dosya,", round(total / 1e6, 2), "MB")
    else:
        print(__doc__)
