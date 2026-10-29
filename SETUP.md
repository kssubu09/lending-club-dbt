# Setup: rebuild this project from scratch

This guide lets anyone (including future me, on a new Snowflake trial) rebuild the project end to end on Windows.

## Prerequisites

- Windows with PowerShell
- Python 3.11 or 3.12
- [uv](https://docs.astral.sh/uv/) (Python package and environment manager)
- Git for Windows (includes Git Bash and `openssl`)
- VS Code
- A free [Kaggle](https://www.kaggle.com) account
- A Snowflake account (a 30-day trial works)

## 1. Clone the repo and create the Python environment

```powershell
git clone https://github.com/kssubu09/lending-club-dbt.git
cd lending-club-dbt
uv sync
.\.venv\Scripts\Activate.ps1
dbt --version
```

`uv sync` installs the exact package versions recorded in `uv.lock` (dbt Core 1.12, dbt-snowflake, pandas, pyarrow).

If PowerShell blocks the activation script, run this once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

In VS Code, select this folder's `.venv` as the Python interpreter (Ctrl+Shift+P → **Python: Select Interpreter**).

## 2. Download the source data

1. Download the Lending Club dataset from [Kaggle (wordsforthewise/lending-club)](https://www.kaggle.com/wordsforthewise/lending-club).
2. Create a `data` folder in the project root.
3. Copy only `accepted_2007_to_2018Q4.csv.gz` (about 390 MB) into `data\`.

The `data` folder is git-ignored; the dataset is never committed.

## 3. Split the file by issue year

```powershell
uv run python scripts\prepare_data.py
```

This keeps 35 of the 151 columns and writes one CSV per issue year to `data\out\` (`loans_2007.csv` to `loans_2018.csv`). Rows without an issue date are dropped and counted.

Run it only once: the script appends to the output files. To rerun, delete `data\out` first.

## 4. Create a Snowflake account

1. Sign up at [signup.snowflake.com](https://signup.snowflake.com).
2. Choose **Enterprise** edition (needed for masking policies), **AWS**, region **Europe (Frankfurt)**.
3. Note the account identifier: Snowsight → your name (bottom left) → **Account** → **View account details**.

## 5. Create the key pair for the dbt service user

Run in **Git Bash**. Keys are stored outside the repo, so they can never be committed.

```bash
mkdir -p /c/Keys/lending_club && cd /c/Keys/lending_club
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 aes-256-cbc -inform PEM -out rsa_key.p8
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

Keep the passphrase safe. Never share `rsa_key.p8`.

Print the public key as one line, to paste into the setup script:

```bash
grep -v "PUBLIC KEY" /c/Keys/lending_club/rsa_key.pub | tr -d '\n'; echo
```

## 6. Create the Snowflake objects

1. Open `setup\01_snowflake_setup.sql` in a Snowsight SQL file.
2. Replace `<PASTE_PUBLIC_KEY>` with the one-line public key, and `<YOUR_LOGIN_NAME>` with the result of `SELECT CURRENT_USER();`.
3. Run all statements.
4. Check: `DESC USER DBT_SVC;` shows an `RSA_PUBLIC_KEY_FP` value starting with `SHA256:`.

This creates the `LC_WH` warehouse (X-Small, auto-suspend 60 s), the `LENDING_CLUB` database with a `RAW` schema, the `LC_TRANSFORMER` role, and the `DBT_SVC` service user that signs in with the key pair.

## Next sections (added as the project progresses)

- 7. Load the raw data into Snowflake
- 8. Configure the dbt profile
- 9. Build and test the dbt project
- 10. Run CI on GitHub Actions