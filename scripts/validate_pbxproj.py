"""Minimal OpenStep-plist parser used to catch malformed pbxproj files locally."""
from pathlib import Path
import sys

path = Path(__file__).resolve().parents[1] / "LUNE.xcodeproj" / "project.pbxproj"
s = path.read_text(encoding="utf-8")
i = 0
n = len(s)


def ws():
    global i
    while i < n:
        if s[i].isspace():
            i += 1
        elif s.startswith("/*", i):
            j = s.find("*/", i + 2)
            if j < 0:
                raise Exception("unterminated comment")
            i = j + 2
        elif s.startswith("//", i):
            j = s.find("\n", i)
            i = n if j < 0 else j + 1
        else:
            break


def token():
    global i
    ws()
    if i >= n:
        return None
    c = s[i]
    if c in "{}()=;,":
        i += 1
        return c
    if c == '"':
        i += 1
        out = []
        while i < n and s[i] != '"':
            if s[i] == "\\":
                i += 1
            out.append(s[i])
            i += 1
        i += 1
        return "".join(out)
    j = i
    while j < n and not s[j].isspace() and s[j] not in "{}()=;,":
        j += 1
    if j == i:
        raise Exception(f"bad char at {i}: {s[i:i+30]!r}")
    out = s[i:j]
    i = j
    return out


def value():
    global i
    t = token()
    if t == "{":
        d = {}
        while True:
            ws()
            if s[i] == "}":
                i += 1
                return d
            k = token()
            if token() != "=":
                raise Exception(f"expected '=' after {k} near {s[i-40:i+40]!r}")
            d[k] = value()
            if token() != ";":
                raise Exception(f"expected ';' after {k} near {s[i-40:i+40]!r}")
    if t == "(":
        arr = []
        while True:
            ws()
            if s[i] == ")":
                i += 1
                return arr
            arr.append(value())
            c = token()
            if c == ",":
                continue
            if c == ")":
                return arr
            raise Exception(f"expected ',' or ')' near {s[i-40:i+40]!r}")
    return t


# Report unquoted tokens containing characters that Apple's old-style plist parser rejects.
import re
_clean = re.sub(r"/\*.*?\*/", " ", s, flags=re.S)
_clean = re.sub(r'"(?:[^"\\]|\\.)*"', "Q", _clean)
_bad = set()
for _tok in re.findall(r"[^\s{}()=;,]+", _clean):
    if not re.fullmatch(r"[A-Za-z0-9_./$+\-]+", _tok):
        _bad.add(_tok)
if _bad:
    print("SUSPECT TOKENS:", sorted(_bad))

try:
    root = value()
    ws()
    if i != n:
        raise Exception(f"trailing content at {i}: {s[i:i+50]!r}")
    print(f"PARSE OK: objects={len(root['objects'])}, rootObject={root['rootObject']}")
except Exception as exc:
    print("PARSE ERROR:", exc)
    sys.exit(1)
