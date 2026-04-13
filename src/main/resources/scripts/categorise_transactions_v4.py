"""
categorise_transactions.py
==========================
Categorises bank transaction CSV exports into spending buckets.

Rules and categories are loaded at runtime from the database tables:
    trx_category   - the spending buckets
    trx_narrative  - the keyword matching rules

Usage:
    python3 categorise_transactions.py <input.csv>

Expected CSV columns:
    Date, Narrative, Debit Amount, Credit Amount

Output:
    Results inserted directly into trx_categorised in the budget_web database.

DB tables required:
    trx_category      (id, name, description)
    trx_narrative     (id, pattern, category_id, confidence, match_type, created_at)
    narrative_overrides (id, narrative_pattern, correct_category, created_at)

match_type values:
    contains      - pattern appears anywhere in the narrative (case-insensitive)
    starts_with   - narrative starts with pattern (case-insensitive)
"""

import sys
import pandas as pd
import mysql.connector
from mysql.connector import Error


# ---------------------------------------------------------------------------
# Database configuration — update these values before running
# ---------------------------------------------------------------------------
DB_CONFIG = {
    'host':     'localhost',
    'port':     3306,
    'database': 'budget_web',
    'user':     'budgetdev',
    'password': 'copsaretops',
}


# ---------------------------------------------------------------------------
# DB connection
# ---------------------------------------------------------------------------

def get_connection():
    """Open and return a MySQL connection. Raises on failure."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        if conn.is_connected():
            return conn
        raise Error("Connection returned but is not connected.")
    except Error as e:
        print(f"[ERROR] Could not connect to database '{DB_CONFIG['database']}' "
              f"at {DB_CONFIG['host']}:{DB_CONFIG['port']}")
        print(f"[ERROR] {e}")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Load rules from DB
# ---------------------------------------------------------------------------

def load_rules(conn):
    """
    Load narrative rules from trx_narrative joined to trx_category.
    Returns a list of dicts:
        [{ 'pattern': str, 'category': str, 'confidence': str, 'match_type': str }, ...]
    Ordered by trx_narrative.id so insert order is preserved.
    """
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT
            n.pattern,
            n.confidence,
            n.match_type,
            c.name AS category
        FROM trx_narrative n
        JOIN trx_category c ON n.trx_category_id = c.id
        ORDER BY n.id ASC
    """)
    rules = cursor.fetchall()
    cursor.close()

    if not rules:
        print("[ERROR] trx_narrative table is empty. Seed the database before running.")
        sys.exit(1)

    print(f"[INFO] Loaded {len(rules)} narrative rules from database.")
    return rules


def load_overrides(conn):
    """
    Load manual corrections from narrative_overrides.
    Returns a list of dicts:
        [{ 'narrative_pattern': str, 'correct_category': str }, ...]
    """
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT narrative_pattern, correct_category
        FROM trx_narrative_overrides
        ORDER BY id ASC
    """)
    overrides = cursor.fetchall()
    cursor.close()
    print(f"[INFO] Loaded {len(overrides)} overrides from database.")
    return overrides


# ---------------------------------------------------------------------------
# Categorisation logic
# ---------------------------------------------------------------------------

def apply_overrides(narrative, overrides):
    """
    Check narrative against the narrative_overrides table entries.
    Overrides take priority over all rules.
    Returns (category, 'high') or None.
    """
    n_upper = narrative.upper()
    for o in overrides:
        if o['narrative_pattern'].upper() in n_upper:
            return (o['correct_category'], 'high')
    return None


def categorise(narrative, rules, overrides):
    """
    Categorise a single narrative string.
    Returns (category_name, confidence).

    Order of precedence:
        1. narrative_overrides (manual corrections - always win)
        2. trx_narrative rules in id order (contains before starts_with by convention)
        3. 'Other / Unknown' if nothing matches
    """
    if pd.isna(narrative):
        return ('Other / Unknown', 'low')

    # 1. Check overrides first
    override = apply_overrides(narrative, overrides)
    if override:
        return override

    n_upper = narrative.upper()

    # 2. Walk rules in order
    for rule in rules:
        pattern = rule['pattern'].upper()
        match_type = rule['match_type']

        if match_type == 'contains' and pattern in n_upper:
            return (rule['category'], rule['confidence'])
        elif match_type == 'starts_with' and n_upper.startswith(pattern):
            return (rule['category'], rule['confidence'])

    # 3. Nothing matched
    return ('Other / Unknown', 'low')


# ---------------------------------------------------------------------------
# DB insert
# ---------------------------------------------------------------------------

NARRATIVE_MAX_LEN = 128
BATCH_SIZE = 500


def get_max_date(conn):
    """
    Returns the most recent when_date already in trx_categorised,
    or None if the table is empty (first import).
    """
    cursor = conn.cursor()
    cursor.execute("SELECT MAX(when_date) FROM trx_categorised")
    result = cursor.fetchone()
    cursor.close()
    max_date = result[0] if result else None
    if max_date:
        print(f"[INFO] Most recent date in trx_categorised: {max_date} — importing rows strictly after this date.")
    else:
        print("[INFO] trx_categorised is empty — importing all rows.")
    return max_date


def insert_results(conn, df, max_date):
    """
    Batch insert categorised transactions into trx_categorised.
    Only inserts rows where when_date > max_date (or all rows if max_date is None).

    Returns (inserted, excluded) counts.
    """
    cursor = conn.cursor()

    sql = """
        INSERT INTO trx_categorised
            (when_date, narrative, debit_amount, credit_amount, category, confidence)
        VALUES
            (%s, %s, %s, %s, %s, %s)
    """

    rows = []
    excluded_count  = 0
    truncated_count = 0

    for _, row in df.iterrows():
        # Parse date — expected format d/m/yyyy from the bank export
        try:
            when_date = pd.to_datetime(row['Date'], dayfirst=True).date()
        except Exception:
            print(f"[WARN] Could not parse date '{row['Date']}' — skipping row.")
            continue

        # Skip anything on or before the max date already in the DB
        if max_date and when_date <= max_date:
            excluded_count += 1
            continue

        narrative = str(row['Narrative']) if pd.notna(row['Narrative']) else ''
        if len(narrative) > NARRATIVE_MAX_LEN:
            print(f"[WARN] Narrative truncated to {NARRATIVE_MAX_LEN} chars: {narrative[:60]}...")
            narrative = narrative[:NARRATIVE_MAX_LEN]
            truncated_count += 1

        debit_amount  = float(row['Debit Amount'])  if pd.notna(row['Debit Amount'])  else 0.00
        credit_amount = float(row['Credit Amount']) if pd.notna(row['Credit Amount']) else 0.00
        category      = str(row['Category'])
        confidence    = str(row['Confidence'])

        rows.append((when_date, narrative, debit_amount, credit_amount, category, confidence))

    print(f"[INFO] {len(rows)} rows to insert, {excluded_count} excluded (on or before {max_date}).")

    # Batch insert
    total_inserted = 0
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i + BATCH_SIZE]
        cursor.executemany(sql, batch)
        conn.commit()
        total_inserted += cursor.rowcount
        print(f"[INFO] Batch {i // BATCH_SIZE + 1}: {cursor.rowcount} rows inserted.")

    cursor.close()

    if truncated_count:
        print(f"[WARN] {truncated_count} narratives were truncated to {NARRATIVE_MAX_LEN} chars.")

    return total_inserted, excluded_count


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def run(input_path):
    """
    Load rules from DB, categorise all rows in input CSV,
    insert results into trx_categorised.
    """
    # Connect — hard fails if DB unreachable
    conn = get_connection()

    try:
        rules     = load_rules(conn)
        overrides = load_overrides(conn)
    except Exception as e:
        conn.close()
        print(f"[ERROR] Failed to load rules: {e}")
        sys.exit(1)

    # Load CSV
    try:
        df = pd.read_csv(input_path)
    except FileNotFoundError:
        conn.close()
        print(f"[ERROR] Input file not found: {input_path}")
        sys.exit(1)

    print(f"[INFO] Loaded {len(df)} transactions from {input_path}")

    # Categorise
    results       = df['Narrative'].apply(lambda n: categorise(n, rules, overrides))
    df['Category']   = results.apply(lambda x: x[0])
    df['Confidence'] = results.apply(lambda x: x[1])

    # Insert into DB
    try:
        max_date = get_max_date(conn)
        inserted, excluded = insert_results(conn, df, max_date)
    finally:
        conn.close()

    # Summary
    unknown_count = len(df[df['Category'] == 'Other / Unknown'])
    summary = (
        df.groupby('Category')
        .agg(Count=('Category', 'count'), Total_Debit=('Debit Amount', 'sum'))
        .sort_values('Total_Debit', ascending=False)
    )

    print(f"\n{'='*55}")
    print(f"  {len(df)} rows processed")
    print(f"  {inserted} inserted  |  {excluded} excluded (before cutoff date)  |  {unknown_count} uncategorised")
    print(f"{'='*55}")
    print(summary.to_string())

    if unknown_count > 0:
        print(f"\n[WARN] Uncategorised transactions:")
        unknown = (df[df['Category'] == 'Other / Unknown']
                   [['Narrative', 'Debit Amount']]
                   .drop_duplicates('Narrative'))
        print(unknown.to_string())

    return df


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 categorise_transactions.py <input.csv>")
        sys.exit(1)
    run(sys.argv[1])
