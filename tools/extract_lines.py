"""index.html içindeki seslendirilen tüm replikleri konuşanıyla birlikte çıkarır.

Çıktı: [{"text": ..., "owner": "hez"|"teyze"|...|null}, ...]
Kullanım: python tools/extract_lines.py index.html lines.json
"""
import json, re, sys

src = open(sys.argv[1], encoding="utf-8").read()
js = src.split("<script>")[1].split("</script>")[0]

SQ_LIT = r"'((?:\\.|[^'\\])*)'"
TPL_LIT = r"`((?:\\.|[^`\\])*)`"
unesc = lambda s: s.replace("\\'", "'").replace('\\"', '"')
lines = {}  # text -> owner (None = ortak replik)


def add(text, owner):
    if not re.search(r"[A-Za-zÇĞİÖŞÜçğıöşü]", text):
        return
    if text in lines and lines[text] != owner:
        lines[text] = None if lines[text] is None or owner is None else lines[text]
        return
    lines.setdefault(text, owner)


def region(start_pat):
    """start_pat'tan sonraki ilk dengeli [] veya {} bloğunu döndürür."""
    m = re.search(start_pat, js)
    if not m:
        raise SystemExit("bulunamadı: " + start_pat)
    i = m.end() - 1
    open_c = js[i]
    close_c = {"[": "]", "{": "}", "(": ")"}[open_c]
    depth, j, q = 0, i, None
    while j < len(js):
        c = js[j]
        if q:
            if c == "\\":
                j += 2
                continue
            if c == q:
                q = None
        elif c in "'`\"":
            q = c
        elif c == open_c:
            depth += 1
        elif c == close_c:
            depth -= 1
            if depth == 0:
                return js[i:j + 1]
        j += 1
    raise SystemExit("kapanmadı: " + start_pat)


lits = lambda s: [unesc(x) for x in re.findall(SQ_LIT, s)]

for name, owner in [("L_FLY", "hez"), ("L_TIRED", "hez"), ("L_RUN", "hez"), ("L_HURT", "hez"), ("L_GULL", "gull"),
                    ("L_FISH", "fish"), ("L_CARPET", "carpet"), ("L_FERRY", "kaptan"), ("L_ARGUE", None),
                    ("WIN_L", None), ("KAHVE_L", "amca")]:
    for t in lits(region(r"const %s=\[" % name)):
        add(t, owner)
for key, body in re.findall(r"(\w+):\[(.*?)\]", region(r"const SH=\{")):
    for t in lits(body):
        add(t, key)
riv = region(r"const RIV=\{")
for body in re.findall(r"l:\[(.*?)\]", riv):
    for t in lits(body):
        add(t, "carpet")
for t in re.findall(r"f:" + SQ_LIT, riv):
    add(unesc(t), "carpet")
for t in lits(region(r"const GL=\{")):
    add(t, None)
sq = region(r"const SQ=\[")
for t in re.findall(r"q:" + SQ_LIT, sq):
    add(unesc(t), "padisah")
for a, _, r in re.findall(r"\[" + SQ_LIT + r",(\d)," + SQ_LIT + r"\]", sq):
    add(unesc(a), "hez")
    add(unesc(r), "padisah")
for body in re.findall(r"lines:\[(.*?)\]", region(r"const ROUTES=\[")):
    for t in lits(body):
        add(t, "boss")
m = re.search(r"lines:\[line,(.*?)\]", js)
for t in lits(m.group(1)):
    add(t, None)
for t in re.findall(r"text:" + SQ_LIT + r"\}", js):
    add(unesc(t), None)

ROUTE_TO = re.findall(r"to:'([^']+)'", region(r"const ROUTES=\["))
BOSS_N = re.findall(r"boss:\{n:'([^']+)'", region(r"const ROUTES=\["))


def expand_tpl(t):
    if "${" not in t:
        return [t]
    out = []
    if re.fullmatch(r"(?:[^$]|\$\{R\.to\})*", t):
        out += [t.replace("${R.to}", x) for x in ROUTE_TO]
    elif re.fullmatch(r"(?:[^$]|\$\{R\.boss\.n\})*", t):
        out += [t.replace("${R.boss.n}", x) for x in BOSS_N]
    return out


def args_of(pos):
    """pos '(' karakterinde; üst seviye argümanları döndürür."""
    depth, j, q, cur, out = 0, pos, None, "", []
    while j < len(js):
        c = js[j]
        if q:
            cur += c
            if c == "\\":
                cur += js[j + 1]
                j += 2
                continue
            if c == q:
                q = None
        elif c in "'`\"":
            q = c
            cur += c
        elif c in "([{":
            depth += 1
            if depth > 1:
                cur += c
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                out.append(cur)
                return out
            cur += c
        elif c == "," and depth == 1:
            out.append(cur)
            cur = ""
        else:
            cur += c
        j += 1
    return out


OWN = {"P": "hez", "S.hz": "hez", "S.pad": "padisah", "u": "ulak", "C.mini": "ressam", "m": "ressam",
       "c.owner": "karpuzcu", "f.cap": "kaptan", "L.yeller": "teyze", "o": "evliya", "o.m1": "amca",
       "choice([o.m1,o.m2])": "amca", "SR.pad": "padisah", "C.mini": "ressam"}
for m in re.finditer(r"(?<![\w.])say\(", js):
    a = args_of(m.end() - 1)
    if len(a) < 2:
        continue
    who = a[0].strip()
    vo = re.search(r"vo:'(\w+)'", who)
    owner = vo.group(1) if vo else OWN.get(who)
    for t in lits(a[1]):
        add(t, owner)
    for t in re.findall(TPL_LIT, a[1]):
        for x in expand_tpl(t):
            add(x, owner)
for m in re.finditer(r"(?<![\w.])banner\(", js):
    a = args_of(m.end() - 1)
    if not a or a[0].strip().startswith("text"):
        continue
    for t in lits(a[0]):
        add(t, "anlatici")
    for t in re.findall(TPL_LIT, a[0]):
        for x in expand_tpl(t):
            add(x, "anlatici")
for m in re.finditer(r"stunV\)?\(", js):
    a = args_of(m.end() - 1)
    if len(a) >= 3:
        for t in lits(a[2]):
            add(t, None)
for body in re.findall(r"text:choice\(\[(.*?)\]\)", js):
    for t in lits(body):
        add(t, None)
add("Ses kontrol! Bir, iki!", "hez")

out = [{"text": t, "owner": o} for t, o in lines.items()]
json.dump(out, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=0)
from collections import Counter
print(len(out), "replik", Counter(o or "ortak" for o in lines.values()).most_common())
