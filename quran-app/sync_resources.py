"""
Sync resources from pdf-to-images/pages into the Flutter app assets,
and generate assets/surah_index.json.

Usage:
    python sync_resources.py

Run this again after the other agent generates more page JSONs.
"""
import json
import os
import shutil
import sys
from datetime import date

# Paths.
# Local default (this machine); if it doesn't exist (e.g. CI on Linux), fall
# back to the `pages/` folder in the parent repo — since quran-app lives inside
# the pdf-to-images repo, `../pages` is the committed source of truth.
APP_DIR = os.path.dirname(os.path.abspath(__file__))
_LOCAL_SOURCE = r"C:\Users\devtips\Documents\pdf-to-images\pages"
_REPO_SOURCE = os.path.normpath(os.path.join(APP_DIR, "..", "pages"))
SOURCE_DIR = _LOCAL_SOURCE if os.path.isdir(_LOCAL_SOURCE) else _REPO_SOURCE
IMG_DEST = os.path.join(APP_DIR, "assets", "images")
JSON_DEST = os.path.join(APP_DIR, "assets", "json")
INDEX_PATH = os.path.join(APP_DIR, "assets", "surah_index.json")
THUMUN_MENU_PATH = os.path.join(APP_DIR, "assets", "thumun-menu.json")


def strip_prefix(name):
    """'سورة الفاتحة' -> 'الفاتحة'"""
    name = name.strip()
    for prefix in ("سُورَةُ ", "سورة "):
        if name.startswith(prefix):
            return name[len(prefix):]
    return name


def main():
    if not os.path.isdir(SOURCE_DIR):
        print(f"[ERROR] Source folder not found: {SOURCE_DIR}")
        print("        Edit SOURCE_DIR at the top of this file.")
        sys.exit(1)

    os.makedirs(IMG_DEST, exist_ok=True)
    os.makedirs(JSON_DEST, exist_ok=True)

    # 1) Copy .png files
    pngs = sorted(f for f in os.listdir(SOURCE_DIR) if f.lower().endswith(".png"))
    copied_img = 0
    for f in pngs:
        src = os.path.join(SOURCE_DIR, f)
        dst = os.path.join(IMG_DEST, f)
        if not os.path.exists(dst) or os.path.getmtime(src) > os.path.getmtime(dst):
            shutil.copy2(src, dst)
            copied_img += 1
    print(f"[1/3] Images: {len(pngs)} found, {copied_img} copied")

    # 2) Copy .json files
    jsons = sorted(f for f in os.listdir(SOURCE_DIR) if f.lower().endswith(".json"))
    copied_json = 0
    available_pages = []
    for f in jsons:
        src = os.path.join(SOURCE_DIR, f)
        dst = os.path.join(JSON_DEST, f)
        if not os.path.exists(dst) or os.path.getmtime(src) > os.path.getmtime(dst):
            shutil.copy2(src, dst)
            copied_json += 1
        try:
            data = json.load(open(src, encoding="utf-8"))
            available_pages.append(int(data["page"]["page_number"]))
        except Exception:
            pass
    available_pages = sorted(set(available_pages))
    print(f"[2/3] JSONs: {len(jsons)} found, {copied_json} copied")

    # 3) Build surah index:
    #    - menu.json from pdf-to-images is the authoritative source for
    #      order / name / classification / unfamiliar_words_count / start page
    #    - page JSONs still provide the per-surah pages[] list
    menu_path = os.path.join(os.path.dirname(SOURCE_DIR), "menu.json")
    menu = {}
    if os.path.exists(menu_path):
        try:
            menu_data = json.load(open(menu_path, encoding="utf-8"))
            for item in menu_data.get("quran_index", []):
                menu[item["order"]] = item
            print(f"  [menu] loaded {len(menu)} surahs from menu.json")
        except Exception as e:
            print(f"  [warn] could not read menu.json: {e}")
    else:
        print("  [warn] menu.json not found; index will lack counts/classification")

    pages_by_order = {}
    for f in jsons:
        path = os.path.join(SOURCE_DIR, f)
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception as e:
            print(f"  [warn] could not read {f}: {e}")
            continue
        page_num = data["page"]["page_number"]
        for section in data["page"].get("sections", []):
            if section.get("type") != "surah_section":
                continue
            s = section.get("surah") or {}
            order = s.get("order")
            if order is None:
                continue
            pages = pages_by_order.setdefault(order, [])
            if page_num not in pages:
                pages.append(page_num)

    surah_list = []
    for order in sorted(set(list(menu.keys()) + list(pages_by_order.keys()))):
        m = menu.get(order, {}) or {}
        title_norm = m.get("title_normalized", "") or ""
        scan_pages = sorted(pages_by_order.get(order, []) or [])
        entry = {
            "order": order,
            "name_normalized": title_norm,
            "short_normalized": strip_prefix(title_norm),
            "classification": m.get("classification", "") or "",
            "unfamiliar_words_count": m.get("unfamiliar_words_count", 0) or 0,
            "start_page": m.get("page_number") or (scan_pages[0] if scan_pages else 0),
            "pages": scan_pages,
        }
        surah_list.append(entry)

    surah_list.sort(key=lambda e: e["order"])

    index = {
        "generated": date.today().isoformat(),
        "page_count": len(available_pages),
        "image_count": len(pngs),
        "pages": available_pages,
        "surahs": surah_list,
    }
    with open(INDEX_PATH, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    print(f"[3/4] Index written: {len(surah_list)} surahs, {len(available_pages)} pages")

    # 4) Copy the Hizb -> Thumun navigation index (thumun-menu.json) which lives
    #    next to menu.json (one dir above the pages/ source folder).
    thumun_src = os.path.join(os.path.dirname(SOURCE_DIR), "thumun-menu.json")
    if os.path.exists(thumun_src):
        if (not os.path.exists(THUMUN_MENU_PATH)
                or os.path.getmtime(thumun_src) > os.path.getmtime(THUMUN_MENU_PATH)):
            shutil.copy2(thumun_src, THUMUN_MENU_PATH)
            print("[4/4] Thumun menu: copied thumun-menu.json")
        else:
            print("[4/4] Thumun menu: up to date")
    else:
        print("[4/4] Thumun menu: [warn] thumun-menu.json not found; Hizb menu will be unavailable")

    print("DONE. Re-build the app or refresh assets.")


if __name__ == "__main__":
    main()