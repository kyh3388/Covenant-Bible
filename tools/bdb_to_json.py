import json
import re
import sqlite3
from html import unescape
from pathlib import Path
from collections import defaultdict


BDB_PATH = Path("tools/data/03개역난외주.bdb")
OUTPUT_JSON_PATH = Path("tools/data/bible_with_notes.json")


BOOK_NAMES = {
    1: "창세기",
    2: "출애굽기",
    3: "레위기",
    4: "민수기",
    5: "신명기",
    6: "여호수아",
    7: "사사기",
    8: "룻기",
    9: "사무엘상",
    10: "사무엘하",
    11: "열왕기상",
    12: "열왕기하",
    13: "역대상",
    14: "역대하",
    15: "에스라",
    16: "느헤미야",
    17: "에스더",
    18: "욥기",
    19: "시편",
    20: "잠언",
    21: "전도서",
    22: "아가",
    23: "이사야",
    24: "예레미야",
    25: "예레미야애가",
    26: "에스겔",
    27: "다니엘",
    28: "호세아",
    29: "요엘",
    30: "아모스",
    31: "오바댜",
    32: "요나",
    33: "미가",
    34: "나훔",
    35: "하박국",
    36: "스바냐",
    37: "학개",
    38: "스가랴",
    39: "말라기",
    40: "마태복음",
    41: "마가복음",
    42: "누가복음",
    43: "요한복음",
    44: "사도행전",
    45: "로마서",
    46: "고린도전서",
    47: "고린도후서",
    48: "갈라디아서",
    49: "에베소서",
    50: "빌립보서",
    51: "골로새서",
    52: "데살로니가전서",
    53: "데살로니가후서",
    54: "디모데전서",
    55: "디모데후서",
    56: "디도서",
    57: "빌레몬서",
    58: "히브리서",
    59: "야고보서",
    60: "베드로전서",
    61: "베드로후서",
    62: "요한일서",
    63: "요한이서",
    64: "요한삼서",
    65: "유다서",
    66: "요한계시록",
}


SECTION_TITLE_PATTERN = re.compile(
    r'<FONT\s+COLOR="#996699">\s*〔(.*?)〕\s*</FONT>',
    re.IGNORECASE,
)

NOTE_MARKER_PATTERN = re.compile(
    r'<SMALL>\s*<FONT\s+COLOR="#FF6095">\s*<SUP>(.*?)</SUP>\s*</FONT>\s*</SMALL>',
    re.IGNORECASE,
)

NOTE_TEXT_PATTERN = re.compile(
    r'<SMALL>\s*<FONT\s+COLOR="#FF6095">\s*〔(.*?)〕\s*</FONT>\s*</SMALL>',
    re.IGNORECASE,
)

HTML_TAG_PATTERN = re.compile(r"<[^>]+>")


def normalize_space(text: str) -> str:
    text = unescape(text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def remove_html_tags(text: str) -> str:
    text = HTML_TAG_PATTERN.sub("", text)
    return normalize_space(text)


def parse_btext(raw_html: str) -> dict:
    """
    btext 안에는 다음이 섞여 있다.

    1. 소제목:
       <FONT COLOR="#996699">〔천지 창조〕</FONT>

    2. 난외주 번호:
       <SMALL><FONT COLOR="#FF6095"><SUP>①</SUP></FONT></SMALL>

    3. 난외주 내용:
       <SMALL><FONT COLOR="#FF6095">〔진주〕</FONT></SMALL>

    이 함수는 raw_html을 분석해서 다음 구조로 분리한다.

    - section_titles: 소제목 목록
    - verse_text: 화면에 보여줄 본문
    - notes: 난외주 목록
    - raw_html: 원본 보존
    """

    section_titles = []

    def collect_section_title(match: re.Match) -> str:
        title = remove_html_tags(match.group(1))
        if title:
            section_titles.append(title)
        return ""

    text = SECTION_TITLE_PATTERN.sub(collect_section_title, raw_html)

    note_markers = []

    def replace_note_marker(match: re.Match) -> str:
        marker = remove_html_tags(match.group(1))
        if marker:
            note_markers.append(marker)
            return marker
        return ""

    text = NOTE_MARKER_PATTERN.sub(replace_note_marker, text)

    note_texts = []

    def collect_note_text(match: re.Match) -> str:
        note = remove_html_tags(match.group(1))
        if note:
            note_texts.append(note)
        return ""

    text = NOTE_TEXT_PATTERN.sub(collect_note_text, text)

    verse_text = remove_html_tags(text)

    notes = []
    for index, note_text in enumerate(note_texts):
        marker = note_markers[index] if index < len(note_markers) else ""

        notes.append(
            {
                "marker": marker,
                "note_text": note_text,
            }
        )

    return {
        "section_titles": section_titles,
        "verse_text": verse_text,
        "notes": notes,
        "raw_html": raw_html,
    }


def main() -> None:
    if not BDB_PATH.exists():
        print(f"파일이 없습니다: {BDB_PATH}")
        return

    OUTPUT_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(BDB_PATH)
    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT id, book, chapter, verse, btext
        FROM Bible
        ORDER BY book, chapter, verse, id
        """
    )

    rows = cursor.fetchall()
    conn.close()

    verses = []
    verse_key_count = defaultdict(int)
    total_note_count = 0
    total_section_title_count = 0

    for row in rows:
        source_id, book_id, chapter, verse, btext = row

        if book_id not in BOOK_NAMES:
            print(f"알 수 없는 book_id 발견: {book_id}")
            continue

        parsed = parse_btext(btext or "")

        verse_key = f"{book_id}:{chapter}:{verse}"
        verse_key_count[verse_key] += 1

        total_note_count += len(parsed["notes"])
        total_section_title_count += len(parsed["section_titles"])

        verses.append(
            {
                "source_id": source_id,
                "book_id": book_id,
                "book_name": BOOK_NAMES[book_id],
                "chapter": chapter,
                "verse": verse,
                "verse_text": parsed["verse_text"],
                "section_titles": parsed["section_titles"],
                "notes": parsed["notes"],
                "raw_html": parsed["raw_html"],
            }
        )

    duplicate_keys = [
        key for key, count in verse_key_count.items()
        if count > 1
    ]

    output = {
        "meta": {
            "source_file": str(BDB_PATH),
            "format": "bdb_sqlite_to_json",
            "verse_row_count": len(verses),
            "book_count": len(set(item["book_id"] for item in verses)),
            "first_verse": {
                "book_id": verses[0]["book_id"] if verses else None,
                "book_name": verses[0]["book_name"] if verses else None,
                "chapter": verses[0]["chapter"] if verses else None,
                "verse": verses[0]["verse"] if verses else None,
            },
            "last_verse": {
                "book_id": verses[-1]["book_id"] if verses else None,
                "book_name": verses[-1]["book_name"] if verses else None,
                "chapter": verses[-1]["chapter"] if verses else None,
                "verse": verses[-1]["verse"] if verses else None,
            },
            "section_title_count": total_section_title_count,
            "note_count": total_note_count,
            "duplicate_verse_key_count": len(duplicate_keys),
            "duplicate_verse_keys_sample": duplicate_keys[:20],
        },
        "verses": verses,
    }

    with OUTPUT_JSON_PATH.open("w", encoding="utf-8") as file:
        json.dump(output, file, ensure_ascii=False, indent=2)

    print("===== BDB → JSON 변환 완료 =====")
    print(f"입력 파일: {BDB_PATH}")
    print(f"출력 파일: {OUTPUT_JSON_PATH}")
    print(f"변환 절 행 수: {len(verses):,}")
    print(f"인식 책 수: {output['meta']['book_count']} / 66")
    print(f"첫 구절: {output['meta']['first_verse']}")
    print(f"마지막 구절: {output['meta']['last_verse']}")
    print(f"소제목 수: {total_section_title_count:,}")
    print(f"난외주 수: {total_note_count:,}")
    print(f"중복 book/chapter/verse 키 수: {len(duplicate_keys):,}")

    if duplicate_keys:
        print()
        print("[중복 구절 키 샘플]")
        for key in duplicate_keys[:20]:
            print(f"- {key}")

    print()
    print("다음 단계: JSON 파일을 열어서 구조를 확인하세요.")


if __name__ == "__main__":
    main()