-- Garante que não haja datas de início maiores que datas fim
SELECT *
FROM {{ ref("stg_rmi__frequencia") }}
WHERE data_inicio > data_fim
