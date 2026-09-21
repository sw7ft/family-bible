#!/usr/bin/env python3
"""Pack public-domain Bible JSON into compact book/chapter arrays."""
from __future__ import annotations

import json
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "FamilyBible" / "Resources"
OUT.mkdir(parents=True, exist_ok=True)

OT = {
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges",
    "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
    "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Psalm", "Proverbs", "Ecclesiastes",
    "Song of Solomon", "Song of Songs", "Isaiah", "Jeremiah", "Lamentations", "Ezekiel",
    "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
    "Zephaniah", "Haggai", "Zechariah", "Malachi",
}

NAME_FIX = {
    "Psalm": "Psalms",
    "Song of Songs": "Song of Solomon",
    "Song of Solomon": "Song of Solomon",
}


def slug(name: str) -> str:
    return "".join(ch for ch in name.lower() if ch.isalnum())


def testament(name: str) -> str:
    return "ot" if name in OT else "nt"


def pack_webu(path: Path) -> list[dict]:
    verses = json.loads(path.read_text(encoding="utf-8-sig"))
    books: OrderedDict[str, dict] = OrderedDict()
    for row in verses:
        name = NAME_FIX.get(row["book"], row["book"])
        book = books.setdefault(
            name,
            {"id": slug(name), "name": name, "testament": testament(name), "chapters": {}},
        )
        ch = int(row["chapter"])
        vs = int(row["verse"])
        chapter = book["chapters"].setdefault(ch, {})
        chapter[vs] = row["text"].strip()
    return finish(books)


def pack_thiago(path: Path) -> list[dict]:
    raw = json.loads(path.read_text(encoding="utf-8-sig"))
    books: OrderedDict[str, dict] = OrderedDict()
    for item in raw:
        name = NAME_FIX.get(item.get("name") or item.get("book"), item.get("name") or item.get("book"))
        book = books.setdefault(
            name,
            {"id": slug(name), "name": name, "testament": testament(name), "chapters": {}},
        )
        for idx, verses in enumerate(item["chapters"], start=1):
            book["chapters"][idx] = {n: str(text).strip() for n, text in enumerate(verses, start=1)}
    return finish(books)


def finish(books: OrderedDict[str, dict]) -> list[dict]:
    out = []
    for book in books.values():
        chapters = []
        for ch in sorted(book["chapters"]):
            verses = book["chapters"][ch]
            chapters.append([verses[n] for n in sorted(verses)])
        out.append(
            {
                "id": book["id"],
                "name": book["name"],
                "testament": book["testament"],
                "chapters": chapters,
            }
        )
    return out


def write(name: str, label: str, notice: str, books: list[dict]) -> None:
    payload = {"id": name, "label": label, "notice": notice, "books": books}
    dest = OUT / f"{name}.json"
    dest.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    verses = sum(len(ch) for b in books for ch in b["chapters"])
    print(f"{dest.name}: {dest.stat().st_size / 1024:.0f} KB, {len(books)} books, {verses} verses")


def main() -> None:
    write(
        "webu",
        "World English Bible",
        "Public domain. World English Bible Updated (WEBU), eBible.org.",
        pack_webu(Path("/tmp/webu-complete.json")),
    )
    write(
        "bbe",
        "Bible in Basic English",
        "Public domain. Bible in Basic English.",
        pack_thiago(Path("/tmp/en_bbe.json")),
    )
    write(
        "kjv",
        "King James Version",
        "Public domain in the United States. King James Version.",
        pack_thiago(Path("/tmp/en_kjv.json")),
    )


if __name__ == "__main__":
    main()
