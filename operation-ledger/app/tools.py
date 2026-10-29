"""The database tool behind LEDGER.

`run_sql` connects with a high-privilege account, runs the model-generated
statement verbatim, and collects every result set it produces. It does not
parse or restrict the SQL, which is the point of the exercise.
"""
import os
import re

import pymssql

MSSQL_HOST = os.environ.get("MSSQL_HOST", "db")
MSSQL_USER = os.environ.get("MSSQL_USER", "sa")
MSSQL_PASSWORD = os.environ.get("MSSQL_SA_PASSWORD", "")
MSSQL_DB = os.environ.get("MSSQL_DB", "reports")

# Pulls the SQL out of a ```sql ... ``` (or plain ``` ... ```) code block.
SQL_FENCE_RE = re.compile(r"```(?:sql)?\s*(.+?)```", re.DOTALL | re.IGNORECASE)


def extract_sql(text: str):
    """Return the SQL from the model's fenced code block, or None."""
    match = SQL_FENCE_RE.search(text or "")
    return match.group(1).strip() if match else None


def run_sql(sql: str):
    """Run the generated SQL and return [(columns, rows), ...].

    Walks every result set the statement produces and returns them all.
    """
    conn = pymssql.connect(
        server=MSSQL_HOST,
        user=MSSQL_USER,
        password=MSSQL_PASSWORD,
        database=MSSQL_DB,
        autocommit=True,
        login_timeout=10,
        timeout=60,
    )
    try:
        cur = conn.cursor()
        cur.execute(sql)
        blocks = []
        while True:
            if cur.description:
                columns = [d[0] for d in cur.description]
                try:
                    rows = cur.fetchall()
                except pymssql.OperationalError:
                    rows = []
                blocks.append((columns, rows))
            if not cur.nextset():
                break
        return blocks
    finally:
        conn.close()
