WITH source AS (

    SELECT * FROM {{ source('rmi', 'avaliacao') }}

),

renamed_typed AS (

    SELECT
        -- aplica hex para melhorar visualização dos dados
        cast(hex(id_aluno) AS varchar) AS aluno_id,
        cast(id_turma AS bigint) AS turma_id,
        cast(frequencia AS double) AS frequencia,
        cast(bimestre AS int) AS bimestre,
        cast(disciplina_1 AS double) AS disciplina_1,
        cast(disciplina_2 AS double) AS disciplina_2,
        cast(disciplina_3 AS double) AS disciplina_3,
        cast(disciplina_4 AS double) AS disciplina_4

    FROM source

),

cleaned_treated AS (
    SELECT
        aluno_id,
        turma_id,
        frequencia,
        -- flag de ausência do aluno
        bimestre,
        ((frequencia IS null) OR (frequencia == 0)) AS is_aluno_ausente,
        -- preenche com zero notas ausentes
        coalesce(disciplina_1, 0) AS disciplina_1,
        coalesce(disciplina_2, 0) AS disciplina_2,
        coalesce(disciplina_3, 0) AS disciplina_3,
        coalesce(disciplina_4, 0) AS disciplina_4,
        -- flags de ausência de nota por disciplina (provável ausência da prova)
        disciplina_1 IS null AS is_disciplina_1_ausente,
        disciplina_2 IS null AS is_disciplina_2_ausente,
        disciplina_3 IS null AS is_disciplina_3_ausente,
        disciplina_4 IS null AS is_disciplina_4_ausente
    FROM renamed_typed
)

SELECT * FROM cleaned_treated
