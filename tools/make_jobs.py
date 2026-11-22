"""voices/lines.json -> voices/jobs.json (Applio için perde/hız ayarlı iş listesi)."""
import hashlib, json, re

# karakter: (perde yarım ton, TTS hız %)
PITCH = {"hez": (0, 0), "teyze": (9, 18), "hanim": (7, 10), "kiz": (11, 5), "cocuk": (12, 25), "amca": (-3, -10),
         "kasap": (-6, 0), "boss": (-7, -8), "padisah": (-4, -12), "imam": (-3, -15), "bekci": (0, 15),
         "balikci": (-2, 0), "berber": (3, 20), "hamamci": (-5, -5), "ulak": (2, 15), "gull": (12, 40),
         "fish": (-9, -15), "carpet": (4, 5), "kaptan": (-4, 0), "karpuzcu": (5, 30), "evliya": (0, -5),
         "ressam": (3, 0), "anlatici": (-2, 0), None: (0, 0)}
FIX = {"Arrr! Kanatlı martı yakaladık!": "kaptan", "Reis! Direğe tüy yapıştı!": "kaptan"}


def speak_text(t):
    t = t.replace("I", "ı").replace("İ", "i").lower()
    t = re.sub(r"[→•…\"]", " ", t)
    return t


lines = json.load(open("voices/lines.json", encoding="utf-8"))
jobs, manifest = [], {}
for l in lines:
    o = FIX.get(l["text"], l["owner"])
    p, r = PITCH.get(o, (0, 0))
    fid = hashlib.sha1(l["text"].encode("utf-8")).hexdigest()[:10]
    jobs.append({"id": fid, "text": speak_text(l["text"]), "pitch": p, "rate": r})
    manifest[l["text"]] = [fid, o]
json.dump(jobs, open("voices/jobs.json", "w", encoding="utf-8"), ensure_ascii=False, indent=0)
json.dump(manifest, open("voices/manifest_all.json", "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print(len(jobs), "iş")
