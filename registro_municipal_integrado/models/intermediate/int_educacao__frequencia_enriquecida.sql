WITH frequencia AS (
    SELECT * FROM {{ ref('stg_rmi__frequencia') }}
),

aluno AS (
    SELECT * FROM {{ ref('stg_rmi__aluno') }}
),

escola AS (
    SELECT * FROM {{ ref('stg_rmi__escola') }}
),

joined AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'f.escola_id',
            'f.turma_id',
            'f.aluno_id',
            'f.disciplina',
            'f.data_inicio'
            ])
        }} AS frequencia_sk,
        f.*,
        a.bairro AS aluno_bairro,
        a.faixa_etaria_nome AS aluno_faixa_etaria,
        e.bairro AS escola_bairro
    FROM
        frequencia AS f
    LEFT JOIN
        aluno AS a
        ON f.aluno_id = a.aluno_id
    LEFT JOIN
        escola AS e
        ON f.escola_id = e.escola_id
)

SELECT * FROM joined
