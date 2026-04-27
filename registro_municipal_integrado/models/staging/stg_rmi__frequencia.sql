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
        escola_id,
        aluno_id,
        turma_id,
        data_inicio,
        data_fim,
        CASE disciplina
            WHEN 'disciplina_1' THEN 'Português'
            WHEN 'disciplina_2' THEN 'Ciências'
            WHEN 'disciplina_3' THEN 'Inglês'
            WHEN 'disciplina_4' THEN 'Matemática'
        END AS disciplina,
        -- flag de ausência do aluno
        coalesce(frequencia, 0) AS frequencia,
        -- flag de ausência do aluno
        ((frequencia IS null) OR (frequencia == 0)) AS is_aluno_ausente
    FROM renamed_typed
),

-- Como há combinações (escola_id, aluno_id, turma_id, disciplina, data_inicio) duplicadas, garante a exclusão das linhas duplicadas
deduped AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY escola_id, aluno_id, turma_id, disciplina, data_inicio
            -- critério de desempate; ajuste conforme necessário
            ORDER BY aluno_id
        ) AS rn
    FROM cleaned_treated
    ORDER BY data_inicio
)

SELECT * EXCLUDE (rn) FROM deduped
WHERE rn = 1
