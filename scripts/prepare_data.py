import os
import pandas as pd

SRC = "data/accepted_2007_to_2018Q4.csv.gz"
OUT = "data/out"
COLS = [
    "id", "loan_amnt", "funded_amnt", "term", "int_rate", "installment",
    "grade", "sub_grade", "purpose", "issue_d", "loan_status", "application_type",
    "emp_title", "emp_length", "home_ownership", "annual_inc",
    "verification_status", "addr_state", "zip_code", "dti",
    "earliest_cr_line", "fico_range_low", "fico_range_high", "open_acc",
    "pub_rec", "revol_bal", "revol_util", "total_acc",
    "total_pymnt", "total_rec_prncp", "total_rec_int", "recoveries",
    "out_prncp", "last_pymnt_d", "last_pymnt_amnt",
]

os.makedirs(OUT, exist_ok=True)
total, no_issue_date = 0, 0

for chunk in pd.read_csv(SRC, usecols=COLS, dtype=str, chunksize=200_000):
    total += len(chunk)
    no_issue_date += chunk["issue_d"].isna().sum()
    chunk["issue_year"] = chunk["issue_d"].str[-4:]
    for year, part in chunk.groupby("issue_year"):  # rows without issue_d are dropped here
        path = f"{OUT}/loans_{year}.csv"
        part[COLS].to_csv(path, mode="a", index=False, header=not os.path.exists(path))
    print(f"processed {total:,} rows...")

print(f"rows read: {total:,} | dropped, no issue date: {no_issue_date:,}")