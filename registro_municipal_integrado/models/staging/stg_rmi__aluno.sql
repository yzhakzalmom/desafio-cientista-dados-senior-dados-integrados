WITH source AS (

    SELECT * FROM {{ source('rmi', 'aluno') }}

),

renamed_typed AS (

    SELECT
        -- aplica hex para melhorar visualização dos dados
        cast(hex(id_aluno) AS varchar) AS aluno_id,
        cast(id_turma AS bigint) AS turma_id,
        cast(faixa_etaria AS varchar) AS faixa_etaria_num,
        cast(bairro AS bigint) AS bairro
    FROM source

),

cleaned_treated AS (
    SELECT
        aluno_id,
        turma_id,
        faixa_etaria_num,
        CASE faixa_etaria_num -- nome cada faixa etaria
            WHEN '0-5' THEN 'Primeira Infância'
            WHEN '6-10' THEN 'Infância'
            WHEN '11-14' THEN 'Pré Adolescente'
            WHEN '15-17' THEN 'Adolescente'
            WHEN '18+' THEN 'Adulto'
        END AS faixa_etaria_nome,
        -- preenche com zero bairros não especificados
        coalesce(bairro, 0) AS bairro
    FROM
        renamed_typed
)

SELECT * FROM cleaned_treated
