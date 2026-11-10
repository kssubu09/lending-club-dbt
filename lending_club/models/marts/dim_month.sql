with spine as (
    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('2007-01-01' as date)",
        end_date="cast('2019-01-01' as date)"
    ) }}
)

select
    cast(date_month as date)                         as month_start,
    year(date_month)                                 as year,
    quarter(date_month)                              as quarter,
    year(date_month) || '-Q' || quarter(date_month)  as year_quarter
from spine