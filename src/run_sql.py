"""
Loads the cleaned CSV into a SQLite database and runs every query in sql/queries.sql.
Results are printed and also saved as CSV files in reports/sql_results/.

Usage (from the project root):
    python src/run_sql.py
"""
import re
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data" / "processed" / "amazon_products_clean.csv"
DB_PATH = ROOT / "data" / "processed" / "amazon.db"
SQL_PATH = ROOT / "sql" / "queries.sql"
OUT_DIR = ROOT / "reports" / "sql_results"


def load_database():
    df = pd.read_csv(CSV_PATH)
    conn = sqlite3.connect(DB_PATH)
    df.to_sql("products", conn, if_exists="replace", index=False)
    return conn


def read_queries():
    text = SQL_PATH.read_text(encoding="utf-8")
    # split on the "-- name: xxx" markers
    chunks = re.split(r"^-- name:\s*(\w+)\s*$", text, flags=re.MULTILINE)
    # chunks = [header, name1, sql1, name2, sql2, ...]
    return list(zip(chunks[1::2], chunks[2::2]))


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    conn = load_database()
    pd.set_option("display.width", 200)
    pd.set_option("display.max_columns", 20)

    for name, sql in read_queries():
        result = pd.read_sql_query(sql, conn)
        result.to_csv(OUT_DIR / f"{name}.csv", index=False)
        print(f"\n=== {name} ({len(result)} rows) ===")
        print(result.head(10).to_string(index=False))

    conn.close()
    print(f"\nDone. Results saved in {OUT_DIR}")


if __name__ == "__main__":
    main()
