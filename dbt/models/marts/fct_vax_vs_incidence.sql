with stg_data as (
    select * from {{ ref('stg_who_data') }}
),

indicator_mapping as (select * from {{ ref('indicator_mapping') }}),
country_mapping as (select * from {{ ref('country_codes') }}),

vax_data as (
    select
        s.country_code,
        s.year,
        s.indicator_code as vax_code,
        m.indicator_name as vax_name,
        s.value as vax_coverage
    from stg_data s
    join indicator_mapping m on s.indicator_code = m.indicator_code
    where m.category = 'Vaccine'
),

incidence_data as (
    select
        s.country_code,
        c.name as country_name,
        s.year,
        s.indicator_code as disease_code,
        m.indicator_name as disease_name,
        s.value as reported_cases
    from stg_data s
    join indicator_mapping m on s.indicator_code = m.indicator_code
    join country_mapping c on s.country_code = c.`alpha-3`
    where m.category = 'Disease'
),

joined as (
    select
        i.country_code,
        i.country_name,
        i.year,
        -- Group DTP diseases together, keep others as is
        case 
            when i.disease_code in ('WHS3_41', 'WHS3_43', 'WHS3_46') then 'DTP-related Diseases'
            else i.disease_name 
        end as disease_group,
        v.vax_name,
        i.reported_cases,
        v.vax_coverage
    from incidence_data i
    left join vax_data v 
        on i.country_code = v.country_code 
        and i.year = v.year
    -- Ensure we only pair the right vaccine with the right disease group
    where (i.disease_code in ('WHS3_41', 'WHS3_43', 'WHS3_46') and v.vax_code = 'WHS4_100') 
       or (i.disease_code = 'WHS3_49' and v.vax_code = 'WHS4_544')
)

-- Final Aggregation: Sum cases by the new group
select 
    country_code,
    country_name,
    year,
    disease_group as disease_name, -- Renaming back to disease_name for your Streamlit app
    vax_name,
    vax_coverage,
    sum(reported_cases) as reported_cases
from joined
group by 1, 2, 3, 4, 5, 6
