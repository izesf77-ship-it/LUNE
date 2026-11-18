"""Check that VERSION, Info.plist and the generated Xcode project agree."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text(encoding="utf-8").strip()
plist = (root / "Info.plist").read_text(encoding="utf-8")
pbxproj = (root / "LUNE.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")

errors = []

if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    errors.append(f"VERSION has unexpected format: {version!r}")

if "<string>$(MARKETING_VERSION)</string>" not in plist:
    errors.append("Info.plist must use $(MARKETING_VERSION) for CFBundleShortVersionString")
if "<string>$(CURRENT_PROJECT_VERSION)</string>" not in plist:
    errors.append("Info.plist must use $(CURRENT_PROJECT_VERSION) for CFBundleVersion")

marketing = set(re.findall(r"MARKETING_VERSION = ([^;]+);", pbxproj))
if marketing != {version}:
    errors.append(f"MARKETING_VERSION in project {marketing} != VERSION {version}")

for path in (root / "Features" / "Settings").rglob("*.swift"):
    text = path.read_text(encoding="utf-8")
    if re.search(r'Text\("Версия 1\.\d+', text):
        errors.append(f"Hardcoded app version in {path.relative_to(root)}")

if errors:
    for error in errors:
        print("ERROR:", error)
    sys.exit(1)

print(f"VERSION_OK: {version} (Info.plist + project.pbxproj + UI are in sync)")
