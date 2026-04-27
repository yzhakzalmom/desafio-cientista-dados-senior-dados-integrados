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
        -- nomes das disciplinas conforme descrito em case_vagas/rmi_schema.yml
        cast(disciplina_1 AS double) AS portugues,
        cast(disciplina_2 AS double) AS ciencias,
        cast(disciplina_3 AS double) AS ingles,
        cast(disciplina_4 AS double) AS matematica

    FROM source

),

cleaned_treated AS (
    SELECT
        aluno_id,
        turma_id,
        bimestre,
        -- flag de ausência do aluno
        coalesce(frequencia, 0) AS frequencia,
        ((frequencia IS null) OR (frequencia == 0)) AS is_aluno_ausente,
        -- preenche com zero notas ausentes
        coalesce(portugues, 0) AS portugues,
        coalesce(ciencias, 0) AS ciencias,
        coalesce(ingles, 0) AS ingles,
        coalesce(matematica, 0) AS matematica,
        -- flags de ausência de nota por disciplina (provável ausência da prova)
        portugues IS null AS is_portugues_ausente,
        ciencias IS null AS is_ciencias_ausente,
        ingles IS null AS is_ingles_ausente,
        matematica IS null AS is_matematica_ausente
    FROM renamed_typed
)

SELECT * FROM cleaned_treated
