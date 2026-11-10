select distinct
    sub_grade,
    grade,
    ascii(grade) - 64 as grade_rank   -- A = 1 ... G = 7
from {{ ref('stg_lending_club__loans') }}
where sub_grade is not null