"""Üretilen sesleri Gemini'ye dinletip yazıya döktürür; dil/aksan/uzunluk kontrolü.
Kullanım: python tools/gemini_check.py voices/gemini_preview/*.wav
"""
import base64, json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import gemini_tts as g

man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
by_id = {v[0]: t for t, v in man.items()}
for path in sys.argv[1:]:
    fid = os.path.basename(path).split(".")[0].rstrip("f")
    want = by_id.get(fid, "?")
    audio = base64.b64encode(open(path, "rb").read()).decode()
    body = {"contents": [{"parts": [{"inline_data": {"mime_type": "audio/wav", "data": audio}},
                                    {"text": "Bu ses kaydını kelimesi kelimesine yazıya dök. Sonra tek satırda: dil, aksan (anadili Türkçe gibi mi, yabancı aksanlı mı), kayıt süresi tahmini. Format: METİN: ... | DİL: ... | AKSAN: ..."}]}]}
    r = g.req("POST", "/models/gemini-3.7-flash:generateContent", body)
    out = r["candidates"][0]["content"]["parts"][0]["text"].strip().replace("\n", " ")
    print("BEKLENEN:", want, "\n   ->", out[:300], "\n")
