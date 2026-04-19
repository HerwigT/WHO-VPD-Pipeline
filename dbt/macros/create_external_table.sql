{% macro create_external_table(project_id, dataset, table_name) %}
    {% set bucket_name = env_var('BUCKET_NAME') %}
    {% set gcs_path = "gs://" ~ bucket_name ~ "/raw_who_data/*.parquet" %}

    CREATE OR REPLACE EXTERNAL TABLE `{{ project_id }}.{{ dataset }}.{{ table_name }}`
    OPTIONS (
        format = 'PARQUET',
        uris = ['{{ gcs_path }}']
    );
{% endmacro %}
