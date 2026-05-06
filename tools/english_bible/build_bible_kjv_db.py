from __future__ import annotations

import re
import sqlite3
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[2]
INPUT_SQL_PATH = BASE_DIR / "tools" / "english_bible" / "data" / "eng-kjv2006_vpl.sql"
OUTPUT_DB_PATH = BASE_DIR / "assets" / "db" / "bible_kjv.db"


# 수정: KJV SQL 원본 약어 체계 기준으로 정리
BOOKS = [
    {"book_id": 1, "code": "GEN", "testament": "OLD", "name_en": "Genesis", "short_name": "Gen", "chapter_count": 50, "sort_order": 1},
    {"book_id": 2, "code": "EXO", "testament": "OLD", "name_en": "Exodus", "short_name": "Exod", "chapter_count": 40, "sort_order": 2},
    {"book_id": 3, "code": "LEV", "testament": "OLD", "name_en": "Leviticus", "short_name": "Lev", "chapter_count": 27, "sort_order": 3},
    {"book_id": 4, "code": "NUM", "testament": "OLD", "name_en": "Numbers", "short_name": "Num", "chapter_count": 36, "sort_order": 4},
    {"book_id": 5, "code": "DEU", "testament": "OLD", "name_en": "Deuteronomy", "short_name": "Deut", "chapter_count": 34, "sort_order": 5},
    {"book_id": 6, "code": "JOS", "testament": "OLD", "name_en": "Joshua", "short_name": "Josh", "chapter_count": 24, "sort_order": 6},
    {"book_id": 7, "code": "JDG", "testament": "OLD", "name_en": "Judges", "short_name": "Judg", "chapter_count": 21, "sort_order": 7},
    {"book_id": 8, "code": "RUT", "testament": "OLD", "name_en": "Ruth", "short_name": "Ruth", "chapter_count": 4, "sort_order": 8},
    {"book_id": 9, "code": "1SA", "testament": "OLD", "name_en": "1 Samuel", "short_name": "1Sam", "chapter_count": 31, "sort_order": 9},
    {"book_id": 10, "code": "2SA", "testament": "OLD", "name_en": "2 Samuel", "short_name": "2Sam", "chapter_count": 24, "sort_order": 10},
    {"book_id": 11, "code": "1KI", "testament": "OLD", "name_en": "1 Kings", "short_name": "1Kgs", "chapter_count": 22, "sort_order": 11},
    {"book_id": 12, "code": "2KI", "testament": "OLD", "name_en": "2 Kings", "short_name": "2Kgs", "chapter_count": 25, "sort_order": 12},
    {"book_id": 13, "code": "1CH", "testament": "OLD", "name_en": "1 Chronicles", "short_name": "1Chr", "chapter_count": 29, "sort_order": 13},
    {"book_id": 14, "code": "2CH", "testament": "OLD", "name_en": "2 Chronicles", "short_name": "2Chr", "chapter_count": 36, "sort_order": 14},
    {"book_id": 15, "code": "EZR", "testament": "OLD", "name_en": "Ezra", "short_name": "Ezra", "chapter_count": 10, "sort_order": 15},
    {"book_id": 16, "code": "NEH", "testament": "OLD", "name_en": "Nehemiah", "short_name": "Neh", "chapter_count": 13, "sort_order": 16},
    {"book_id": 17, "code": "EST", "testament": "OLD", "name_en": "Esther", "short_name": "Esth", "chapter_count": 10, "sort_order": 17},
    {"book_id": 18, "code": "JOB", "testament": "OLD", "name_en": "Job", "short_name": "Job", "chapter_count": 42, "sort_order": 18},
    {"book_id": 19, "code": "PSA", "testament": "OLD", "name_en": "Psalms", "short_name": "Ps", "chapter_count": 150, "sort_order": 19},
    {"book_id": 20, "code": "PRO", "testament": "OLD", "name_en": "Proverbs", "short_name": "Prov", "chapter_count": 31, "sort_order": 20},
    {"book_id": 21, "code": "ECC", "testament": "OLD", "name_en": "Ecclesiastes", "short_name": "Eccl", "chapter_count": 12, "sort_order": 21},
    {"book_id": 22, "code": "SNG", "testament": "OLD", "name_en": "Song of Solomon", "short_name": "Song", "chapter_count": 8, "sort_order": 22},
    {"book_id": 23, "code": "ISA", "testament": "OLD", "name_en": "Isaiah", "short_name": "Isa", "chapter_count": 66, "sort_order": 23},
    {"book_id": 24, "code": "JER", "testament": "OLD", "name_en": "Jeremiah", "short_name": "Jer", "chapter_count": 52, "sort_order": 24},
    {"book_id": 25, "code": "LAM", "testament": "OLD", "name_en": "Lamentations", "short_name": "Lam", "chapter_count": 5, "sort_order": 25},
    {"book_id": 26, "code": "EZK", "testament": "OLD", "name_en": "Ezekiel", "short_name": "Ezek", "chapter_count": 48, "sort_order": 26},
    {"book_id": 27, "code": "DAN", "testament": "OLD", "name_en": "Daniel", "short_name": "Dan", "chapter_count": 12, "sort_order": 27},
    {"book_id": 28, "code": "HOS", "testament": "OLD", "name_en": "Hosea", "short_name": "Hos", "chapter_count": 14, "sort_order": 28},
    {"book_id": 29, "code": "JOL", "testament": "OLD", "name_en": "Joel", "short_name": "Joel", "chapter_count": 3, "sort_order": 29},
    {"book_id": 30, "code": "AMO", "testament": "OLD", "name_en": "Amos", "short_name": "Amos", "chapter_count": 9, "sort_order": 30},
    {"book_id": 31, "code": "OBA", "testament": "OLD", "name_en": "Obadiah", "short_name": "Obad", "chapter_count": 1, "sort_order": 31},
    {"book_id": 32, "code": "JON", "testament": "OLD", "name_en": "Jonah", "short_name": "Jonah", "chapter_count": 4, "sort_order": 32},
    {"book_id": 33, "code": "MIC", "testament": "OLD", "name_en": "Micah", "short_name": "Mic", "chapter_count": 7, "sort_order": 33},
    {"book_id": 34, "code": "NAM", "testament": "OLD", "name_en": "Nahum", "short_name": "Nah", "chapter_count": 3, "sort_order": 34},
    {"book_id": 35, "code": "HAB", "testament": "OLD", "name_en": "Habakkuk", "short_name": "Hab", "chapter_count": 3, "sort_order": 35},
    {"book_id": 36, "code": "ZEP", "testament": "OLD", "name_en": "Zephaniah", "short_name": "Zeph", "chapter_count": 3, "sort_order": 36},
    {"book_id": 37, "code": "HAG", "testament": "OLD", "name_en": "Haggai", "short_name": "Hag", "chapter_count": 2, "sort_order": 37},
    {"book_id": 38, "code": "ZEC", "testament": "OLD", "name_en": "Zechariah", "short_name": "Zech", "chapter_count": 14, "sort_order": 38},
    {"book_id": 39, "code": "MAL", "testament": "OLD", "name_en": "Malachi", "short_name": "Mal", "chapter_count": 4, "sort_order": 39},
    {"book_id": 40, "code": "MAT", "testament": "NEW", "name_en": "Matthew", "short_name": "Matt", "chapter_count": 28, "sort_order": 40},
    {"book_id": 41, "code": "MRK", "testament": "NEW", "name_en": "Mark", "short_name": "Mark", "chapter_count": 16, "sort_order": 41},
    {"book_id": 42, "code": "LUK", "testament": "NEW", "name_en": "Luke", "short_name": "Luke", "chapter_count": 24, "sort_order": 42},
    {"book_id": 43, "code": "JHN", "testament": "NEW", "name_en": "John", "short_name": "John", "chapter_count": 21, "sort_order": 43},
    {"book_id": 44, "code": "ACT", "testament": "NEW", "name_en": "Acts", "short_name": "Acts", "chapter_count": 28, "sort_order": 44},
    {"book_id": 45, "code": "ROM", "testament": "NEW", "name_en": "Romans", "short_name": "Rom", "chapter_count": 16, "sort_order": 45},
    {"book_id": 46, "code": "1CO", "testament": "NEW", "name_en": "1 Corinthians", "short_name": "1Cor", "chapter_count": 16, "sort_order": 46},
    {"book_id": 47, "code": "2CO", "testament": "NEW", "name_en": "2 Corinthians", "short_name": "2Cor", "chapter_count": 13, "sort_order": 47},
    {"book_id": 48, "code": "GAL", "testament": "NEW", "name_en": "Galatians", "short_name": "Gal", "chapter_count": 6, "sort_order": 48},
    {"book_id": 49, "code": "EPH", "testament": "NEW", "name_en": "Ephesians", "short_name": "Eph", "chapter_count": 6, "sort_order": 49},
    {"book_id": 50, "code": "PHP", "testament": "NEW", "name_en": "Philippians", "short_name": "Phil", "chapter_count": 4, "sort_order": 50},
    {"book_id": 51, "code": "COL", "testament": "NEW", "name_en": "Colossians", "short_name": "Col", "chapter_count": 4, "sort_order": 51},
    {"book_id": 52, "code": "1TH", "testament": "NEW", "name_en": "1 Thessalonians", "short_name": "1Thess", "chapter_count": 5, "sort_order": 52},
    {"book_id": 53, "code": "2TH", "testament": "NEW", "name_en": "2 Thessalonians", "short_name": "2Thess", "chapter_count": 3, "sort_order": 53},
    {"book_id": 54, "code": "1TI", "testament": "NEW", "name_en": "1 Timothy", "short_name": "1Tim", "chapter_count": 6, "sort_order": 54},
    {"book_id": 55, "code": "2TI", "testament": "NEW", "name_en": "2 Timothy", "short_name": "2Tim", "chapter_count": 4, "sort_order": 55},
    {"book_id": 56, "code": "TIT", "testament": "NEW", "name_en": "Titus", "short_name": "Titus", "chapter_count": 3, "sort_order": 56},
    {"book_id": 57, "code": "PHM", "testament": "NEW", "name_en": "Philemon", "short_name": "Phlm", "chapter_count": 1, "sort_order": 57},
    {"book_id": 58, "code": "HEB", "testament": "NEW", "name_en": "Hebrews", "short_name": "Heb", "chapter_count": 13, "sort_order": 58},
    {"book_id": 59, "code": "JAS", "testament": "NEW", "name_en": "James", "short_name": "Jas", "chapter_count": 5, "sort_order": 59},
    {"book_id": 60, "code": "1PE", "testament": "NEW", "name_en": "1 Peter", "short_name": "1Pet", "chapter_count": 5, "sort_order": 60},
    {"book_id": 61, "code": "2PE", "testament": "NEW", "name_en": "2 Peter", "short_name": "2Pet", "chapter_count": 3, "sort_order": 61},
    {"book_id": 62, "code": "1JN", "testament": "NEW", "name_en": "1 John", "short_name": "1John", "chapter_count": 5, "sort_order": 62},
    {"book_id": 63, "code": "2JN", "testament": "NEW", "name_en": "2 John", "short_name": "2John", "chapter_count": 1, "sort_order": 63},
    {"book_id": 64, "code": "3JN", "testament": "NEW", "name_en": "3 John", "short_name": "3John", "chapter_count": 1, "sort_order": 64},
    {"book_id": 65, "code": "JUD", "testament": "NEW", "name_en": "Jude", "short_name": "Jude", "chapter_count": 1, "sort_order": 65},
    {"book_id": 66, "code": "REV", "testament": "NEW", "name_en": "Revelation", "short_name": "Rev", "chapter_count": 22, "sort_order": 66},
]

# 수정: 혹시 다른 약어 체계가 섞여 있어도 흡수하도록 alias 추가
BOOK_CODE_ALIASES = {
    "SOL": "SNG",
    "EZE": "EZK",
    "JOE": "JOL",
    "NAH": "NAM",
    "MAR": "MRK",
    "JOH": "JHN",
    "PHI": "PHP",
    "JAM": "JAS",
    "1JO": "1JN",
    "2JO": "2JN",
    "3JO": "3JN",
}

BOOK_CODE_TO_ID = {book["code"]: book["book_id"] for book in BOOKS}
BOOK_CODE_TO_ID.update(
    {
        alias: BOOK_CODE_TO_ID[canonical]
        for alias, canonical in BOOK_CODE_ALIASES.items()
    }
)

INSERT_PATTERN = re.compile(
    r'^INSERT INTO eng_kjv2006_vpl VALUES '
    r'\("([^"]*)","([^"]*)","([^"]*)","([^"]*)","([^"]*)","([^"]*)","(.*)"\);$'
)


def decode_sql_string(value: str) -> str:
    value = value.replace(r"\\", "\\")
    value = value.replace(r"\"", '"')
    value = value.replace(r"\'", "'")
    return value.strip()


def parse_insert_line(line: str) -> tuple[int, int, int, str] | None:
    match = INSERT_PATTERN.match(line)
    if not match:
        return None

    book_code = match.group(3).strip()
    chapter = int(match.group(4).strip())
    start_verse = int(match.group(5).strip())
    verse_text = decode_sql_string(match.group(7))

    if book_code not in BOOK_CODE_TO_ID:
        raise ValueError(f"알 수 없는 book code: {book_code}")

    book_id = BOOK_CODE_TO_ID[book_code]
    return (book_id, chapter, start_verse, verse_text)


def read_kjv_rows(sql_path: Path) -> list[tuple[int, int, int, str]]:
    if not sql_path.exists():
        raise FileNotFoundError(f"입력 SQL 파일이 없습니다: {sql_path}")

    rows: list[tuple[int, int, int, str]] = []

    with sql_path.open("r", encoding="utf-8-sig", errors="ignore") as file:
        for line_number, raw_line in enumerate(file, start=1):
            line = raw_line.strip()

            if not line.startswith("INSERT INTO eng_kjv2006_vpl VALUES "):
                continue

            parsed = parse_insert_line(line)

            if parsed is None:
                raise ValueError(f"{line_number}번째 INSERT 파싱 실패:\n{line}")

            rows.append(parsed)

    return rows


def create_kjv_db(
    output_db_path: Path,
    verse_rows: list[tuple[int, int, int, str]],
) -> None:
    output_db_path.parent.mkdir(parents=True, exist_ok=True)

    if output_db_path.exists():
        output_db_path.unlink()

    conn = sqlite3.connect(output_db_path)
    cursor = conn.cursor()

    try:
        cursor.execute("""
            CREATE TABLE translation_info (
                translation_code TEXT PRIMARY KEY,
                translation_name TEXT NOT NULL
            )
        """)

        cursor.execute("""
            CREATE TABLE bible_book (
                book_id INTEGER PRIMARY KEY,
                testament TEXT NOT NULL,
                name_en TEXT NOT NULL,
                short_name TEXT NOT NULL,
                chapter_count INTEGER NOT NULL,
                sort_order INTEGER NOT NULL
            )
        """)

        cursor.execute("""
            CREATE TABLE bible_verse (
                verse_id INTEGER PRIMARY KEY AUTOINCREMENT,
                book_id INTEGER NOT NULL,
                chapter INTEGER NOT NULL,
                verse INTEGER NOT NULL,
                verse_text TEXT NOT NULL,
                UNIQUE (book_id, chapter, verse)
            )
        """)

        cursor.execute("""
            CREATE INDEX idx_bible_book_sort_order
            ON bible_book (sort_order)
        """)

        cursor.execute("""
            CREATE INDEX idx_bible_verse_reference
            ON bible_verse (book_id, chapter, verse)
        """)

        cursor.execute("""
            INSERT INTO translation_info (translation_code, translation_name)
            VALUES (?, ?)
        """, ("KJV", "King James Version"))

        cursor.executemany("""
            INSERT INTO bible_book (
                book_id, testament, name_en, short_name, chapter_count, sort_order
            )
            VALUES (
                :book_id, :testament, :name_en, :short_name, :chapter_count, :sort_order
            )
        """, BOOKS)

        cursor.executemany("""
            INSERT INTO bible_verse (book_id, chapter, verse, verse_text)
            VALUES (?, ?, ?, ?)
        """, verse_rows)

        conn.commit()

    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def main() -> None:
    print(f"[1/3] KJV SQL 읽는 중: {INPUT_SQL_PATH}")
    verse_rows = read_kjv_rows(INPUT_SQL_PATH)
    print(f"총 {len(verse_rows):,}절 읽음")

    print(f"[2/3] DB 생성 준비: {OUTPUT_DB_PATH}")
    create_kjv_db(OUTPUT_DB_PATH, verse_rows)

    print("[3/3] 완료")
    print(f"출력 DB: {OUTPUT_DB_PATH}")
    print("bible_kjv.db 생성 완료")


if __name__ == "__main__":
    main()