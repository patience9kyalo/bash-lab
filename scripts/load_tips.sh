#!/usr/bin/env bash
# load_tips.sh - Download a CSV, check it, and load it into SQLite
set -euo pipefail

URL="${1:-https://raw.githubusercontent.com/mwaskom/seaborn-data/master/tips.csv}"
RAW_FILE="data/raw/tips.csv"
CLEAN_FILE="data/clean/tips_clean.csv"
BODY_FILE="data/clean/tips_body.csv"
DB_FILE="db/tips.db"
LOG_FILE="logs/load_tips.log"
EXPECTED_HEADER="total_bill,tip,sex,smoker,day,time,size"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

fail() {
  log ERROR "$1"
  exit 1
}

mkdir -p data/raw data/clean db logs

for tool in curl sqlite3; do
  command -v "$tool" > /dev/null || fail "$tool is not installed"
done

log INFO "Pipeline started"

# ---------- EXTRACT ----------
log INFO "Downloading $URL"
curl -fsSL --retry 3 -o "$RAW_FILE" "$URL" || fail "Download failed"
[ -s "$RAW_FILE" ] || fail "Downloaded file is empty"
log INFO "Saved $RAW_FILE ($(wc -l < "$RAW_FILE") lines)"

# ---------- TRANSFORM ----------
tr -d '"\r' < "$RAW_FILE" > "$CLEAN_FILE"

header=$(head -n 1 "$CLEAN_FILE")
[ "$header" = "$EXPECTED_HEADER" ] || fail "Unexpected header: $header"

bad_rows=$(awk -F',' 'NR>1 && NF!=7' "$CLEAN_FILE" | wc -l)
[ "$bad_rows" -eq 0 ] || fail "$bad_rows rows do not have 7 columns"

tail -n +2 "$CLEAN_FILE" > "$BODY_FILE"
expected_rows=$(wc -l < "$BODY_FILE")
log INFO "Validated $expected_rows rows"

# ---------- LOAD ----------
sqlite3 "$DB_FILE" <<SQL
DROP TABLE IF EXISTS tips;
CREATE TABLE tips (
  total_bill REAL,
  tip        REAL,
  sex        TEXT,
  smoker     TEXT,
  day        TEXT,
  time       TEXT,
  size       INTEGER
);
.mode csv
.import $BODY_FILE tips
SQL

loaded_rows=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tips;")
[ "$loaded_rows" -eq "$expected_rows" ] || fail "Loaded $loaded_rows rows but expected $expected_rows"

log INFO "Loaded $loaded_rows rows into $DB_FILE"
log INFO "Pipeline finished successfully"
