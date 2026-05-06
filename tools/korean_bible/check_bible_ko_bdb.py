import sqlite3
from pathlib import Path


# 수정: 한글 성경 전용 폴더 구조로 경로 분리
BDB_PATH = Path("tools/korean_bible/data/bible_ko_source.bdb")


def print_section(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


def main() -> None:
    if not BDB_PATH.exists():
        print(f"파일이 없습니다: {BDB_PATH}")
        print("파일 위치를 다시 확인하세요.")
        return

    print_section("한글 BDB 파일 기본 정보")
    print(f"파일 경로: {BDB_PATH}")
    print(f"파일 크기: {BDB_PATH.stat().st_size:,} bytes")

    try:
        conn = sqlite3.connect(BDB_PATH)
        cursor = conn.cursor()
    except sqlite3.Error as error:
        print("SQLite 파일로 열 수 없습니다.")
        print(f"오류: {error}")
        return

    try:
        print_section("테이블 목록")
        cursor.execute("""
            SELECT name
            FROM sqlite_master
            WHERE type = 'table'
            ORDER BY name
        """)
        tables = [row[0] for row in cursor.fetchall()]

        if not tables:
            print("테이블이 없습니다.")
            return

        for table in tables:
            print(f"- {table}")

        for table in tables:
            print_section(f"테이블 구조: {table}")
            cursor.execute(f"PRAGMA table_info({table})")
            columns = cursor.fetchall()

            for column in columns:
                cid, name, col_type, not_null, default_value, pk = column
                print(
                    f"- {name} | type={col_type} | "
                    f"not_null={not_null} | pk={pk}"
                )

            print_section(f"데이터 수: {table}")
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"{table} row count: {count:,}")

            print_section(f"샘플 데이터: {table}")
            cursor.execute(f"SELECT * FROM {table} LIMIT 5")
            rows = cursor.fetchall()

            if not rows:
                print("샘플 데이터 없음")
            else:
                column_names = [description[0] for description in cursor.description]

                for index, row in enumerate(rows, start=1):
                    print(f"[{index}]")
                    for name, value in zip(column_names, row):
                        text = str(value)
                        if len(text) > 300:
                            text = text[:300] + "..."
                        print(f"  {name}: {text}")

        if "Bible" in tables:
            print_section("Bible 테이블 상세 검수")

            cursor.execute("SELECT COUNT(*) FROM Bible")
            total_count = cursor.fetchone()[0]
            print(f"총 행 수: {total_count:,}")

            cursor.execute("""
                SELECT book, chapter, verse, btext
                FROM Bible
                ORDER BY book, chapter, verse
                LIMIT 1
            """)
            first = cursor.fetchone()

            cursor.execute("""
                SELECT book, chapter, verse, btext
                FROM Bible
                ORDER BY book DESC, chapter DESC, verse DESC
                LIMIT 1
            """)
            last = cursor.fetchone()

            print()
            print("[첫 구절]")
            if first:
                book, chapter, verse, btext = first
                print(f"book={book}, chapter={chapter}, verse={verse}")
                print(f"btext={btext[:500]}")

            print()
            print("[마지막 구절]")
            if last:
                book, chapter, verse, btext = last
                print(f"book={book}, chapter={chapter}, verse={verse}")
                print(f"btext={btext[:500]}")

            print_section("책별 장/절 개수 요약")
            cursor.execute("""
                SELECT
                    book,
                    COUNT(*) AS verse_count,
                    MIN(chapter) AS min_chapter,
                    MAX(chapter) AS max_chapter
                FROM Bible
                GROUP BY book
                ORDER BY book
            """)

            summaries = cursor.fetchall()

            for book, verse_count, min_chapter, max_chapter in summaries:
                print(
                    f"book={book:>2} | "
                    f"verses={verse_count:>5} | "
                    f"chapter={min_chapter}~{max_chapter}"
                )

            print_section("HTML 태그 포함 여부 샘플")
            cursor.execute("""
                SELECT book, chapter, verse, btext
                FROM Bible
                WHERE btext LIKE '%<%'
                LIMIT 10
            """)
            html_rows = cursor.fetchall()

            if not html_rows:
                print("HTML 태그가 포함된 샘플을 찾지 못했습니다.")
            else:
                for book, chapter, verse, btext in html_rows:
                    text = btext
                    if len(text) > 500:
                        text = text[:500] + "..."
                    print(f"[{book}:{chapter}:{verse}] {text}")

    except sqlite3.Error as error:
        print("DB 조회 중 오류가 발생했습니다.")
        print(f"오류: {error}")

    finally:
        conn.close()


if __name__ == "__main__":
    main()