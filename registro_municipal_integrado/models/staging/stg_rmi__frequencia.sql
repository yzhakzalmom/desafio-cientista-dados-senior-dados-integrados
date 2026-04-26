WITH source AS (

    SELECT * FROM {{ source('rmi', 'frequencia') }}

),

renamed_typed AS (

    SELECT
        cast(id_escola AS bigint) AS escola_id,
        -- aplica hex para melhorar visualização dos dados
        cast(hex(id_aluno) AS varchar) AS aluno_id,
        cast(id_turma AS bigint) AS turma_id,
        cast(data_inicio AS date) AS data_inicio,
        cast(data_fim AS date) AS data_fim,
        cast(disciplina AS varchar) AS disciplina,
        cast(frequencia AS double) AS frequencia

    FROM source

),

cleaned_treated AS (
    SELECT
        *,
        -- flag de ausência do aluno
        ((frequencia IS null) OR (frequencia == 0)) AS is_aluno_ausente
    FROM renamed_typed
)

SELECT * FROM cleaned_treated
