with duplicatas as (
    SELECT
        aluno_id,
        turma_id,
        bimestre,
        count(*) AS qtd
    FROM {{ ref("stg_rmi__avaliacao") }}
    GROUP BY aluno_id, turma_id, bimestre
    HAVING count(*) > 1
),

deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY aluno_id, turma_id, bimestre
            ORDER BY
                -- maior número de colunas preenchidas primeiro
                (
                    (portugues != 0)::int +
                    (ciencias  != 0)::int +
                    (ingles    != 0)::int +
                    (matematica != 0)::int
                ) DESC,
                -- desempate: maior frequencia primeiro
                frequencia DESC
        ) AS rn
    FROM {{ ref("stg_rmi__avaliacao") }}
)

SELECT
    aluno_id,
    turma_id,
    bimestre,
    count(*) AS qtd
FROM deduped
WHERE rn = 1
GROUP BY aluno_id, turma_id, bimestre
HAVING count(*) > 1