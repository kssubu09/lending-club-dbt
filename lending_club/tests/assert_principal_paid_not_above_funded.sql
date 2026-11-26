-- A borrower can't repay more principal than was lent.
{{ config(severity = 'warn') }}

select loan_id, funded_amount, principal_paid
from {{ ref('fct_loans') }}
where principal_paid > funded_amount + 1   -- 1 dollar tolerance for rounding