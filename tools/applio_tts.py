"""Hezarfen replikleri için Applio ile seslendirme üretir.

Kullanım:  set APPLIO_KEY=...   python tools/applio_tts.py lines.json out_dir
lines.json: [{"id": "...", "text": "...", "pitch": 0, "voice": "tr-TR-AhmetNeural"}, ...]
Anahtar sadece ortam değişkeninden okunur, dosyaya yazılmaz.
"""
import json, os, sys, time, urllib.request

API = os.environ.get("APPLIO_URL", "http://127.0.0.1:3000/v1")
KEY = os.environ["APPLIO_KEY"]
MODEL = os.environ.get("APPLIO_PTH", "logs/Aykut_Rap/Aykut_Rap_200e_2800s.pth")
INDEX = os.environ.get("APPLIO_INDEX", "logs/Aykut_Rap/Aykut_Rap.index")


def req(method, path, body=None, raw=False):
    data = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method,
                               headers={"Authorization": "Bearer " + KEY, "Content-Type": "application/json; charset=utf-8"})
    with urllib.request.urlopen(r, timeout=120) as resp:
        b = resp.read()
    return b if raw else json.loads(b.decode("utf-8"))


def tts(text, out, pitch=0, voice="tr-TR-AhmetNeural", rate=0):
    job = req("POST", "/applio/tts", {"pthPath": MODEL, "indexPath": INDEX, "ttsVoice": voice, "ttsText": text,
                                      "ttsRate": rate, "pitch": pitch, "exportFormat": "MP3", "f0Method": "rmvpe"})
    jid = job.get("jobId") or job.get("id")
    if not jid:
        raise RuntimeError("İş kimliği yok: %r" % job)
    for _ in range(600):
        st = req("GET", "/jobs/%s" % jid)
        st = st.get("job", st)
        s = st.get("status") or st.get("state")
        if s in ("completed", "succeeded", "done", "success"):
            break
        if s in ("failed", "error", "cancelled", "canceled"):
            raise RuntimeError("İş başarısız: %r" % st)
        time.sleep(0.5)
    audio = req("GET", "/jobs/%s/content" % jid, raw=True)
    with open(out, "wb") as f:
        f.write(audio)
    return len(audio)


if __name__ == "__main__":
    lines = json.load(open(sys.argv[1], encoding="utf-8"))
    outdir = sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    for i, l in enumerate(lines):
        out = os.path.join(outdir, l["id"] + ".mp3")
        if os.path.exists(out) and os.path.getsize(out) > 1000:
            continue
        try:
            n = tts(l["text"], out, l.get("pitch", 0), l.get("voice", "tr-TR-AhmetNeural"), l.get("rate", 0))
            print("[%d/%d] %s  %d bayt" % (i + 1, len(lines), l["id"], n), flush=True)
        except Exception as e:
            print("[%d/%d] HATA %s: %s" % (i + 1, len(lines), l["id"], e), flush=True)
