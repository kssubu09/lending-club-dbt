{{ config(
    materialized = 'incremental',
    unique_key = 'loan_id',
    incremental_strategy = 'merge',
    on_schema_change = 'append_new_columns'
) }}

select
    loan_id,
    loan_id            as borrower_key,
    issue_month,
    sub_grade,
    loan_purpose,
    state_code,
    term_months,
    interest_rate,
    loan_amount,
    funded_amount,
    installment_amount,
    loan_status,
    status_group,
    is_closed,
    is_bad,
    total_paid,
    principal_paid,
    interest_paid,
    recoveries,
    outstanding_principal,
    net_loss_amount,
    last_payment_month,
    loaded_at
from {{ ref('int_loans__enriched') }}

{% if is_incremental() %}
where loaded_at > (select max(loaded_at) from {{ this }})
{% endif %}