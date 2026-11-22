"""voices/raw/*.mp3 -> voices/*.mp3 (mono, 48 kbps, baştaki sessizlik kırpılmış) + voices/manifest.json"""
import json, os, subprocess

man = json.load(open("voices/manifest_all.json", encoding="utf-8"))
out, total = {}, 0
for text, (fid, owner) in man.items():
    src = os.path.join("voices", "raw", fid + ".mp3")
    dst = os.path.join("voices", fid + ".mp3")
    if not os.path.exists(src) or os.path.getsize(src) < 1000:
        continue
    if not os.path.exists(dst):
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-af",
                        "silenceremove=start_periods=1:start_threshold=-45dB,loudnorm=I=-16:TP=-1.5",
                        "-ac", "1", "-ar", "32000", "-b:a", "48k", dst], check=True)
    total += os.path.getsize(dst)
    out[text] = [fid, owner]
json.dump(out, open("voices/manifest.json", "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print(len(out), "/", len(man), "ses,", round(total / 1e6, 2), "MB")
