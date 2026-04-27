import json
import sqlite3
from pathlib import Path


INPUT_JSON_PATH = Path("tools/data/bible_with_notes.json")
OUTPUT_DB_PATH = Path("assets/db/bible.db")


BOOKS = [
    {"book_id": 1, "testament": "OLD", "name_ko": "창세기", "short_name": "창", "chapter_count": 50, "sort_order": 1},
    {"book_id": 2, "testament": "OLD", "name_ko": "출애굽기", "short_name": "출", "chapter_count": 40, "sort_order": 2},
    {"book_id": 3, "testament": "OLD", "name_ko": "레위기", "short_name": "레", "chapter_count": 27, "sort_order": 3},
    {"book_id": 4, "testament": "OLD", "name_ko": "민수기", "short_name": "민", "chapter_count": 36, "sort_order": 4},
    {"book_id": 5, "testament": "OLD", "name_ko": "신명기", "short_name": "신", "chapter_count": 34, "sort_order": 5},
    {"book_id": 6, "testament": "OLD", "name_ko": "여호수아", "short_name": "수", "chapter_count": 24, "sort_order": 6},
    {"book_id": 7, "testament": "OLD", "name_ko": "사사기", "short_name": "삿", "chapter_count": 21, "sort_order": 7},
    {"book_id": 8, "testament": "OLD", "name_ko": "룻기", "short_name": "룻", "chapter_count": 4, "sort_order": 8},
    {"book_id": 9, "testament": "OLD", "name_ko": "사무엘상", "short_name": "삼상", "chapter_count": 31, "sort_order": 9},
    {"book_id": 10, "testament": "OLD", "name_ko": "사무엘하", "short_name": "삼하", "chapter_count": 24, "sort_order": 10},
    {"book_id": 11, "testament": "OLD", "name_ko": "열왕기상", "short_name": "왕상", "chapter_count": 22, "sort_order": 11},
    {"book_id": 12, "testament": "OLD", "name_ko": "열왕기하", "short_name": "왕하", "chapter_count": 25, "sort_order": 12},
    {"book_id": 13, "testament": "OLD", "name_ko": "역대상", "short_name": "대상", "chapter_count": 29, "sort_order": 13},
    {"book_id": 14, "testament": "OLD", "name_ko": "역대하", "short_name": "대하", "chapter_count": 36, "sort_order": 14},
    {"book_id": 15, "testament": "OLD", "name_ko": "에스라", "short_name": "스", "chapter_count": 10, "sort_order": 15},
    {"book_id": 16, "testament": "OLD", "name_ko": "느헤미야", "short_name": "느", "chapter_count": 13, "sort_order": 16},
    {"book_id": 17, "testament": "OLD", "name_ko": "에스더", "short_name": "에", "chapter_count": 10, "sort_order": 17},
    {"book_id": 18, "testament": "OLD", "name_ko": "욥기", "short_name": "욥", "chapter_count": 42, "sort_order": 18},
    {"book_id": 19, "testament": "OLD", "name_ko": "시편", "short_name": "시", "chapter_count": 150, "sort_order": 19},
    {"book_id": 20, "testament": "OLD", "name_ko": "잠언", "short_name": "잠", "chapter_count": 31, "sort_order": 20},
    {"book_id": 21, "testament": "OLD", "name_ko": "전도서", "short_name": "전", "chapter_count": 12, "sort_order": 21},
    {"book_id": 22, "testament": "OLD", "name_ko": "아가", "short_name": "아", "chapter_count": 8, "sort_order": 22},
    {"book_id": 23, "testament": "OLD", "name_ko": "이사야", "short_name": "사", "chapter_count": 66, "sort_order": 23},
    {"book_id": 24, "testament": "OLD", "name_ko": "예레미야", "short_name": "렘", "chapter_count": 52, "sort_order": 24},
    {"book_id": 25, "testament": "OLD", "name_ko": "예레미야애가", "short_name": "애", "chapter_count": 5, "sort_order": 25},
    {"book_id": 26, "testament": "OLD", "name_ko": "에스겔", "short_name": "겔", "chapter_count": 48, "sort_order": 26},
    {"book_id": 27, "testament": "OLD", "name_ko": "다니엘", "short_name": "단", "chapter_count": 12, "sort_order": 27},
    {"book_id": 28, "testament": "OLD", "name_ko": "호세아", "short_name": "호", "chapter_count": 14, "sort_order": 28},
    {"book_id": 29, "testament": "OLD", "name_ko": "요엘", "short_name": "욜", "chapter_count": 3, "sort_order": 29},
    {"book_id": 30, "testament": "OLD", "name_ko": "아모스", "short_name": "암", "chapter_count": 9, "sort_order": 30},
    {"book_id": 31, "testament": "OLD", "name_ko": "오바댜", "short_name": "옵", "chapter_count": 1, "sort_order": 31},
    {"book_id": 32, "testament": "OLD", "name_ko": "요나", "short_name": "욘", "chapter_count": 4, "sort_order": 32},
    {"book_id": 33, "testament": "OLD", "name_ko": "미가", "short_name": "미", "chapter_count": 7, "sort_order": 33},
    {"book_id": 34, "testament": "OLD", "name_ko": "나훔", "short_name": "나", "chapter_count": 3, "sort_order": 34},
    {"book_id": 35, "testament": "OLD", "name_ko": "하박국", "short_name": "합", "chapter_count": 3, "sort_order": 35},
    {"book_id": 36, "testament": "OLD", "name_ko": "스바냐", "short_name": "습", "chapter_count": 3, "sort_order": 36},
    {"book_id": 37, "testament": "OLD", "name_ko": "학개", "short_name": "학", "chapter_count": 2, "sort_order": 37},
    {"book_id": 38, "testament": "OLD", "name_ko": "스가랴", "short_name": "슥", "chapter_count": 14, "sort_order": 38},
    {"book_id": 39, "testament": "OLD", "name_ko": "말라기", "short_name": "말", "chapter_count": 4, "sort_order": 39},
    {"book_id": 40, "testament": "NEW", "name_ko": "마태복음", "short_name": "마", "chapter_count": 28, "sort_order": 40},
    {"book_id": 41, "testament": "NEW", "name_ko": "마가복음", "short_name": "막", "chapter_count": 16, "sort_order": 41},
    {"book_id": 42, "testament": "NEW", "name_ko": "누가복음", "short_name": "눅", "chapter_count": 24, "sort_order": 42},
    {"book_id": 43, "testament": "NEW", "name_ko": "요한복음", "short_name": "요", "chapter_count": 21, "sort_order": 43},
    {"book_id": 44, "testament": "NEW", "name_ko": "사도행전", "short_name": "행", "chapter_count": 28, "sort_order": 44},
    {"book_id": 45, "testament": "NEW", "name_ko": "로마서", "short_name": "롬", "chapter_count": 16, "sort_order": 45},
    {"book_id": 46, "testament": "NEW", "name_ko": "고린도전서", "short_name": "고전", "chapter_count": 16, "sort_order": 46},
    {"book_id": 47, "testament": "NEW", "name_ko": "고린도후서", "short_name": "고후", "chapter_count": 13, "sort_order": 47},
    {"book_id": 48, "testament": "NEW", "name_ko": "갈라디아서", "short_name": "갈", "chapter_count": 6, "sort_order": 48},
    {"book_id": 49, "testament": "NEW", "name_ko": "에베소서", "short_name": "엡", "chapter_count": 6, "sort_order": 49},
    {"book_id": 50, "testament": "NEW", "name_ko": "빌립보서", "short_name": "빌", "chapter_count": 4, "sort_order": 50},
    {"book_id": 51, "testament": "NEW", "name_ko": "골로새서", "short_name": "골", "chapter_count": 4, "sort_order": 51},
    {"book_id": 52, "testament": "NEW", "name_ko": "데살로니가전서", "short_name": "살전", "chapter_count": 5, "sort_order": 52},
    {"book_id": 53, "testament": "NEW", "name_ko": "데살로니가후서", "short_name": "살후", "chapter_count": 3, "sort_order": 53},
    {"book_id": 54, "testament": "NEW", "name_ko": "디모데전서", "short_name": "딤전", "chapter_count": 6, "sort_order": 54},
    {"book_id": 55, "testament": "NEW", "name_ko": "디모데후서", "short_name": "딤후", "chapter_count": 4, "sort_order": 55},
    {"book_id": 56, "testament": "NEW", "name_ko": "디도서", "short_name": "딛", "chapter_count": 3, "sort_order": 56},
    {"book_id": 57, "testament": "NEW", "name_ko": "빌레몬서", "short_name": "몬", "chapter_count": 1, "sort_order": 57},
    {"book_id": 58, "testament": "NEW", "name_ko": "히브리서", "short_name": "히", "chapter_count": 13, "sort_order": 58},
    {"book_id": 59, "testament": "NEW", "name_ko": "야고보서", "short_name": "약", "chapter_count": 5, "sort_order": 59},
    {"book_id": 60, "testament": "NEW", "name_ko": "베드로전서", "short_name": "벧전", "chapter_count": 5, "sort_order": 60},
    {"book_id": 61, "testament": "NEW", "name_ko": "베드로후서", "short_name": "벧후", "chapter_count": 3, "sort_order": 61},
    {"book_id": 62, "testament": "NEW", "name_ko": "요한일서", "short_name": "요일", "chapter_count": 5, "sort_order": 62},
    {"book_id": 63, "testament": "NEW", "name_ko": "요한이서", "short_name": "요이", "chapter_count": 1, "sort_order": 63},
    {"book_id": 64, "testament": "NEW", "name_ko": "요한삼서", "short_name": "요삼", "chapter_count": 1, "sort_order": 64},
    {"book_id": 65, "testament": "NEW", "name_ko": "유다서", "short_name": "유", "chapter_count": 1, "sort_order": 65},
    {"book_id": 66, "testament": "NEW", "name_ko": "요한계시록", "short_name": "계", "chapter_count": 22, "sort_order": 66},
]


def create_tables(cursor: sqlite3.Cursor) -> None:
    cursor.execute("""
        CREATE TABLE bible_book (
            book_id INTEGER PRIMARY KEY,
            testament TEXT NOT NULL,
            name_ko TEXT NOT NULL,
            short_name TEXT NOT NULL,
            chapter_count INTEGER NOT NULL,
            sort_order INTEGER NOT NULL
        )
    """)

    cursor.execute("""
        CREATE TABLE bible_verse (
            verse_id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_id INTEGER,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            verse_text TEXT NOT NULL,
            raw_html TEXT,
            FOREIGN KEY (book_id) REFERENCES bible_book(book_id)
        )
    """)

    cursor.execute("""
        CREATE TABLE bible_note (
            note_id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            marker TEXT,
            note_text TEXT NOT NULL,
            FOREIGN KEY (book_id) REFERENCES bible_book(book_id)
        )
    """)

    cursor.execute("""
        CREATE TABLE bible_section_title (
            title_id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            title_text TEXT NOT NULL,
            FOREIGN KEY (book_id) REFERENCES bible_book(book_id)
        )
    """)

    cursor.execute("""
        CREATE INDEX idx_bible_verse_book_chapter
        ON bible_verse(book_id, chapter, verse)
    """)

    cursor.execute("""
        CREATE INDEX idx_bible_note_location
        ON bible_note(book_id, chapter, verse)
    """)

    cursor.execute("""
        CREATE INDEX idx_bible_section_title_location
        ON bible_section_title(book_id, chapter, verse)
    """)


def insert_books(cursor: sqlite3.Cursor) -> None:
    cursor.executemany(
        """
        INSERT INTO bible_book (
            book_id,
            testament,
            name_ko,
            short_name,
            chapter_count,
            sort_order
        )
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        [
            (
                book["book_id"],
                book["testament"],
                book["name_ko"],
                book["short_name"],
                book["chapter_count"],
                book["sort_order"],
            )
            for book in BOOKS
        ],
    )


def insert_verses_notes_titles(cursor: sqlite3.Cursor, verses: list[dict]) -> tuple[int, int, int]:
    verse_count = 0
    note_count = 0
    title_count = 0

    for item in verses:
        book_id = item["book_id"]
        chapter = item["chapter"]
        verse = item["verse"]

        cursor.execute(
            """
            INSERT INTO bible_verse (
                source_id,
                book_id,
                chapter,
                verse,
                verse_text,
                raw_html
            )
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                item.get("source_id"),
                book_id,
                chapter,
                verse,
                item.get("verse_text", ""),
                item.get("raw_html", ""),
            ),
        )
        verse_count += 1

        for note in item.get("notes", []):
            note_text = note.get("note_text", "").strip()
            if not note_text:
                continue

            cursor.execute(
                """
                INSERT INTO bible_note (
                    book_id,
                    chapter,
                    verse,
                    marker,
                    note_text
                )
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    book_id,
                    chapter,
                    verse,
                    note.get("marker", ""),
                    note_text,
                ),
            )
            note_count += 1

        for title_text in item.get("section_titles", []):
            title_text = title_text.strip()
            if not title_text:
                continue

            cursor.execute(
                """
                INSERT INTO bible_section_title (
                    book_id,
                    chapter,
                    verse,
                    title_text
                )
                VALUES (?, ?, ?, ?)
                """,
                (
                    book_id,
                    chapter,
                    verse,
                    title_text,
                ),
            )
            title_count += 1

    return verse_count, note_count, title_count


def main() -> None:
    if not INPUT_JSON_PATH.exists():
        print(f"입력 JSON 파일이 없습니다: {INPUT_JSON_PATH}")
        return

    OUTPUT_DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    if OUTPUT_DB_PATH.exists():
        OUTPUT_DB_PATH.unlink()

    with INPUT_JSON_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)

    verses = data.get("verses", [])

    conn = sqlite3.connect(OUTPUT_DB_PATH)
    cursor = conn.cursor()

    try:
        cursor.execute("PRAGMA foreign_keys = ON")

        create_tables(cursor)
        insert_books(cursor)

        verse_count, note_count, title_count = insert_verses_notes_titles(
            cursor=cursor,
            verses=verses,
        )

        conn.commit()

        cursor.execute("SELECT COUNT(*) FROM bible_book")
        book_count = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM bible_verse")
        db_verse_count = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM bible_note")
        db_note_count = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM bible_section_title")
        db_title_count = cursor.fetchone()[0]

        cursor.execute("""
            SELECT book_id, chapter, verse, verse_text
            FROM bible_verse
            ORDER BY book_id, chapter, verse
            LIMIT 1
        """)
        first = cursor.fetchone()

        cursor.execute("""
            SELECT book_id, chapter, verse, verse_text
            FROM bible_verse
            ORDER BY book_id DESC, chapter DESC, verse DESC
            LIMIT 1
        """)
        last = cursor.fetchone()

        print("===== bible.db 생성 완료 =====")
        print(f"입력 JSON: {INPUT_JSON_PATH}")
        print(f"출력 DB: {OUTPUT_DB_PATH}")
        print(f"책 수: {book_count}")
        print(f"본문 절 행 수: {db_verse_count}")
        print(f"난외주 수: {db_note_count}")
        print(f"소제목 수: {db_title_count}")
        print()
        print(f"첫 구절: {first}")
        print(f"마지막 구절: {last}")

        if book_count == 66 and db_verse_count == verse_count:
            print()
            print("DB 생성 결과: 정상으로 보입니다.")
        else:
            print()
            print("DB 생성 결과: 추가 확인이 필요합니다.")

    except Exception as error:
        conn.rollback()
        print("DB 생성 중 오류가 발생했습니다.")
        print(error)

    finally:
        conn.close()


if __name__ == "__main__":
    main()