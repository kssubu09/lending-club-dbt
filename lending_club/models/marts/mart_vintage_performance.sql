select
    m.year_quarter                                                      as vintage,
    g.grade,
    count(*)                                                            as loans,
    sum(f.funded_amount)                                                as funded_amount,
    avg(f.interest_rate)                                                as avg_interest_rate,
    count_if(f.is_closed)                                               as closed_loans,
    count_if(f.status_group = 'Defaulted')                              as defaulted_loans,
    div0(count_if(f.status_group = 'Defaulted'), count_if(f.is_closed)) as default_rate_closed,
    div0(sum(f.net_loss_amount), sum(f.funded_amount))                  as net_loss_rate
from {{ ref('fct_loans') }} f
join {{ ref('dim_month') }} m on f.issue_month = m.month_start
join {{ ref('dim_grade') }} g on f.sub_grade = g.sub_grade
group by 1, 2