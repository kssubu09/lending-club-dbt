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

This creates the LC_WH warehouse (X-Small, auto-suspend 60 s), the LENDING_CLUB database with a RAW schema, the LC_TRANSFORMER role with the DBT_SVC user for dbt, and the LC_LOADER role with the LOADER_SVC user for loading. Both service users sign in with the key pair.

## 7. Load the raw data into Snowflake

Loading uses a separate service user, `LOADER_SVC` with the `LC_LOADER` role, so dbt's `LC_TRANSFORMER` role can only read raw data.

1. Run the file format, stage and table section of `setup\02_raw_load.sql` as SYSADMIN.
2. Run the loader role and user section of `setup\01_snowflake_setup.sql`, replacing `<PASTE_PUBLIC_KEY>` with the one-line public key from section 5.
3. Install the Snowflake CLI:

   ```powershell
   uv tool install snowflake-cli
   snow --version
   ```

4. Create `%USERPROFILE%\.snowflake\config.toml` with this connection:

   ```toml
   [connections.lc_loader]
   account = "<YOUR_ACCOUNT_IDENTIFIER>"
   user = "LOADER_SVC"
   authenticator = "SNOWFLAKE_JWT"
   private_key_file = "C:\\Keys\\lending_club\\rsa_key.p8"
   role = "LC_LOADER"
   warehouse = "LC_WH"
   database = "LENDING_CLUB"
   schema = "RAW"
   ```

5. Set the key passphrase for the session and test the connection:

   ```powershell
   $env:PRIVATE_KEY_PASSPHRASE = "<your passphrase>"
   snow connection test -c lc_loader
   ```

6. Hold back the 2017 and 2018 files for the incremental demo:

   ```powershell
   mkdir data\later
   Move-Item data\out\loans_2017.csv, data\out\loans_2018.csv data\later\
   ```

7. Upload the 2007–2016 files to the internal stage with PUT (files are gzip-compressed on upload):

   ```powershell
   snow sql -c lc_loader -q "PUT 'file://C:/Projects/lending-club-dbt/data/out/*.csv' @LC_STAGE/loans/ AUTO_COMPRESS=TRUE"
   ```

8. Run the `COPY INTO` section of `setup\02_raw_load.sql`.
9. Check: one row count per file, and zero rows where `TRY_TO_NUMBER(id)` is null.

Rerunning `COPY INTO` is safe: Snowflake skips files it has already loaded.