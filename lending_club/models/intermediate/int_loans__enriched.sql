with loans as (
    select * from {{ ref('stg_lending_club__loans') }}
),

status_map as (
    select * from {{ ref('loan_status_map') }}
)

select
    loans.*,
    status_map.status_group,
    status_map.is_closed,
    status_map.is_bad,
    (loans.fico_low + loans.fico_high) / 2 as fico_mid,
    case
        when status_map.status_group = 'Defaulted'
            then greatest(loans.funded_amount - loans.principal_paid - loans.recoveries, 0)
        else 0
    end as net_loss_amount
from loans
left join status_map
    on loans.loan_status = status_map.loan_status