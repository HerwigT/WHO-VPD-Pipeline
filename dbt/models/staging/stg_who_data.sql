with source as (
    select * from {{ source('bronze_who', 'who_data_raw') }}
),

renamed as (
    select
        cast(Id as INT64) as id,
        IndicatorCode as indicator_code,
        SpatialDimType as spatial_dim_type,
        SpatialDim as country_code,
        TimeDimType as time_dim_type,
        cast(TimeDim as INT64) as year,
        Dim1Type as dim1_type,
        Dim1 as dim1,
        cast(NumericValue as FLOAT64) as value,
        ingestion_timestamp
    from source
)

select * from renamed
