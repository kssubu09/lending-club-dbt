with source as (
    select * from {{ source('lending_club', 'loans') }}
),

renamed as (
    select
        -- ids and amounts
        try_to_number(id)                                       as loan_id,
        try_to_number(loan_amnt, 12, 2)                         as loan_amount,
        try_to_number(funded_amnt, 12, 2)                       as funded_amount,
        try_to_number(installment, 12, 2)                       as installment_amount,
        try_to_number(regexp_substr(term, '[0-9]+'))            as term_months,
        try_to_number(replace(int_rate, '%', ''), 6, 2) / 100   as interest_rate,

        -- loan attributes
        grade,
        sub_grade,
        lower(purpose)                                          as loan_purpose,
        try_to_date(issue_d, 'MON-YYYY')                        as issue_month,
        trim(loan_status)                                       as loan_status,
        application_type,

        -- borrower
        nullif(trim(emp_title), '')                             as employer_title,
        case
            when emp_length = '< 1 year' then 0
            else try_to_number(regexp_substr(emp_length, '[0-9]+'))
        end                                                     as employment_years,
        upper(home_ownership)                                   as home_ownership,
        try_to_number(annual_inc, 14, 2)                        as annual_income,
        verification_status,
        addr_state                                              as state_code,
        zip_code                                                as zip3_masked,
        try_to_number(dti, 8, 2)                                as debt_to_income_ratio,

        -- credit history
        try_to_date(earliest_cr_line, 'MON-YYYY')               as earliest_credit_line_month,
        try_to_number(fico_range_low)                           as fico_low,
        try_to_number(fico_range_high)                          as fico_high,
        try_to_number(open_acc)                                 as open_accounts,
        try_to_number(pub_rec)                                  as public_records,
        try_to_number(revol_bal, 14, 2)                         as revolving_balance,
        try_to_number(replace(revol_util, '%', ''), 6, 2) / 100 as revolving_utilisation,
        try_to_number(total_acc)                                as total_accounts,

        -- repayment to date
        try_to_number(total_pymnt, 14, 2)                       as total_paid,
        try_to_number(total_rec_prncp, 14, 2)                   as principal_paid,
        try_to_number(total_rec_int, 14, 2)                     as interest_paid,
        try_to_number(recoveries, 14, 2)                        as recoveries,
        try_to_number(out_prncp, 14, 2)                         as outstanding_principal,
        try_to_date(last_pymnt_d, 'MON-YYYY')                   as last_payment_month,
        try_to_number(last_pymnt_amnt, 14, 2)                   as last_payment_amount,

        -- audit
        _file_name                                              as source_file,
        _loaded_at                                              as loaded_at
    from source
    where try_to_number(id) is not null
)

select * from renamed