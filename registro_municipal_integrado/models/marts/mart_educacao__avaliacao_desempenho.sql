WITH avaliacao_enriquecida AS (
    SELECT * FROM {{ ref('int_educacao__avaliacao_enriquecida') }}
),

tamanho_turma AS (
    SELECT
        *,
        CASE
            WHEN alunos_qtd <= 15 THEN 'Pequena'
            WHEN alunos_qtd <= 25 THEN 'Média'
            ELSE 'Grande'
        END AS turma_tamanho
    FROM {{ ref('int_educacao__tamanho_turma') }}
    WHERE alunos_qtd > 1
),

unpivoted AS (
    SELECT
        aluno_id,
        faixa_etaria_nome,
        turma_id,
        disciplina,
        bimestre,
        frequencia_anual,
        is_aluno_ausente,
        nota
    FROM avaliacao_enriquecida
    UNPIVOT (
        nota FOR disciplina IN (portugues, ciencias, ingles, matematica)
    )
),

joined AS (
    SELECT
        u.*,
        t.turma_tamanho
    FROM tamanho_turma AS t
    INNER JOIN unpivoted AS u ON t.turma_id = u.turma_id
),

notas_medias AS (
    SELECT
        disciplina,
        faixa_etaria_nome,
        turma_tamanho,
        bimestre,
        avg(nota) AS media_nota
    FROM
        joined
    GROUP BY faixa_etaria_nome, turma_tamanho, disciplina, bimestre
    ORDER BY
        disciplina,
        faixa_etaria_nome,
        turma_tamanho,
        bimestre
)

SELECT * FROM notas_medias
