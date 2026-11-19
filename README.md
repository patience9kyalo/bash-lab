# Bash Lab

A small Bash-based ETL pipeline that downloads the Seaborn `tips.csv` dataset, validates its structure, and loads the rows into a SQLite database.

## Requirements

- Bash
- `curl`
- `sqlite3`
- Standard Unix utilities used by the script: `awk`, `head`, `tail`, `tr`, `wc`, and `date`
- Network access to the CSV URL

## Run the pipeline

From the repository root:

```bash
bash scripts/load_tips.sh
```

By default, the script downloads the dataset from:

```text
https://raw.githubusercontent.com/mwaskom/seaborn-data/master/tips.csv
```

To use a different CSV URL, pass it as the first argument:

```bash
bash scripts/load_tips.sh "https://example.com/tips.csv"
```

The input must have the expected header (`total_bill,tip,sex,smoker,day,time,size`) and each data row must contain seven comma-separated columns.

## What it does

1. Creates the required `data/`, `db/`, and `logs/` directories if they do not exist.
2. Downloads the CSV to `data/raw/tips.csv`.
3. Removes double quotes and carriage returns, checks the header and row column counts, and writes the cleaned data to `data/clean/`.
4. Creates the `tips` table in `db/tips.db` and imports the validated rows.
5. Checks that the number of imported rows matches the number validated.
6. Writes timestamped progress and error messages to `logs/load_tips.log`.

The database table has these columns: `total_bill` (REAL), `tip` (REAL), `sex` (TEXT), `smoker` (TEXT), `day` (TEXT), `time` (TEXT), and `size` (INTEGER).

> **Note:** Each run drops and recreates the `tips` table. Existing rows in that table will be replaced.

## Output files

- `data/raw/tips.csv` — downloaded source CSV
- `data/clean/tips_clean.csv` — cleaned CSV, including its header
- `data/clean/tips_body.csv` — validated data rows without the header
- `db/tips.db` — SQLite database containing the `tips` table
- `logs/load_tips.log` — pipeline log
