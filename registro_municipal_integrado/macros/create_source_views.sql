{% macro create_source_views() %}

{% set base_path = 'https://storage.googleapis.com/case_vagas/rmi' %}
{% set tables = ['aluno', 'avaliacao', 'escola', 'frequencia', 'turma'] %}
{% set source_schema = 'rmi' %}

{# Cria o schema se não existir #}
{% set create_schema %}
    CREATE SCHEMA IF NOT EXISTS {{ source_schema }}
{% endset %}
{% do run_query(create_schema) %}
{{ log("Schema criado: " ~ source_schema, info=True) }}

{# Cria as views dentro do schema #}
{% for table in tables %}
    {% set create_view %}
        CREATE OR REPLACE VIEW {{ source_schema }}.{{ table }} AS
        SELECT * FROM read_parquet('{{ base_path }}/{{ table }}')
    {% endset %}
    {% do run_query(create_view) %}
    {{ log("View criada: " ~ source_schema ~ "." ~ table, info=True) }}
{% endfor %}

{% endmacro %}