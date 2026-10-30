--files are uploaded with PUT via the Snowflake CLI (see SETUP.md section 7)

USE ROLE SYSADMIN;
USE WAREHOUSE LC_WH;
USE SCHEMA LENDING_CLUB.RAW;

CREATE OR REPLACE FILE FORMAT CSV_FF
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE;

CREATE OR REPLACE STAGE LC_STAGE FILE_FORMAT = CSV_FF;

CREATE TABLE IF NOT EXISTS LOANS (
  id VARCHAR, loan_amnt VARCHAR, funded_amnt VARCHAR, term VARCHAR,
  int_rate VARCHAR, installment VARCHAR, grade VARCHAR, sub_grade VARCHAR,
  purpose VARCHAR, issue_d VARCHAR, loan_status VARCHAR, application_type VARCHAR,
  emp_title VARCHAR, emp_length VARCHAR, home_ownership VARCHAR, annual_inc VARCHAR,
  verification_status VARCHAR, addr_state VARCHAR, zip_code VARCHAR, dti VARCHAR,
  earliest_cr_line VARCHAR, fico_range_low VARCHAR, fico_range_high VARCHAR,
  open_acc VARCHAR, pub_rec VARCHAR, revol_bal VARCHAR, revol_util VARCHAR,
  total_acc VARCHAR, total_pymnt VARCHAR, total_rec_prncp VARCHAR,
  total_rec_int VARCHAR, recoveries VARCHAR, out_prncp VARCHAR,
  last_pymnt_d VARCHAR, last_pymnt_amnt VARCHAR,
  _file_name VARCHAR, _loaded_at TIMESTAMP_LTZ
);


COPY INTO LOANS
FROM (
  SELECT $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,
         $19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,
         METADATA$FILENAME, CURRENT_TIMESTAMP()
  FROM @LC_STAGE/loans/
)
ON_ERROR = 'ABORT_STATEMENT';