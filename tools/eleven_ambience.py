"""Sahne ortam sesleri (dikişsiz döngü) — ElevenLabs Sound Effects, loop=True.
Kullanım: python tools/eleven_ambience.py   -> sfx/amb_<ad>.mp3
"""
import json, os, subprocess, sys, urllib.request
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(__file__))
from eleven_tts import api_key

AMB = {
    "deniz": "Seamless loop of open sea ambience: gentle waves, soft wind over the Bosphorus, distant seagulls, no music",
    "meydan": "Seamless loop of a busy historic Istanbul town square: crowd murmur, distant chatter, footsteps on cobblestones, a fountain trickling, no music, no clear words",
    "carsi": "Seamless loop of a lively old Ottoman bazaar: merchants calling in the distance, crowd bustle, clinking tea glasses, no music, no clear words",
    "iskele": "Seamless loop of an old wooden harbor pier: water lapping against boats, creaking wood and ropes, seagulls, distant ferry horn, no music",
    "gece": "Seamless loop of a calm night by the sea in old Istanbul: crickets, soft waves, a distant dog barking once, no music",
    "saray": "Seamless loop of a quiet grand Ottoman palace hall: soft marble fountain trickling, faint echoing murmurs of courtiers, no music, no clear words",
}


def gen(name, text):
    out_raw = "sfx/raw/amb_%s.mp3" % name
    if not (os.path.exists(out_raw) and os.path.getsize(out_raw) > 10000):
        body = json.dumps({"text": text, "duration_seconds": 12, "loop": True, "prompt_influence": 0.4,
                           "model_id": "eleven_text_to_sound_v2"}).encode("utf-8")
        r = urllib.request.Request("https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128", data=body,
                                   method="POST", headers={"xi-api-key": api_key(), "Content-Type": "application/json"})
        with urllib.request.urlopen(r, timeout=180) as resp:
            open(out_raw, "wb").write(resp.read())
    # döngü bozulmasın diye sessizlik kırpılmaz; sadece ses seviyesi eşitlenir
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", out_raw, "-af", "loudnorm=I=-24:TP=-3", "-ac", "2", "-ar", "44100",
                    "-b:a", "96k", "sfx/amb_%s.mp3" % name], check=True)
    print("ortam sesi:", name, flush=True)


if __name__ == "__main__":
    os.makedirs("sfx/raw", exist_ok=True)
    with ThreadPoolExecutor(3) as ex:
        for f in [ex.submit(gen, n, t) for n, t in AMB.items()]:
            try:
                f.result()
            except Exception as e:
                print("HATA:", e, flush=True)
