WITH avaliacao AS (
    SELECT *
    FROM {{ ref('stg_rmi__avaliacao') }}
),

aluno AS (
    SELECT * FROM {{ ref('stg_rmi__aluno') }}
),

turma AS (
    SELECT * FROM {{ ref('stg_rmi__turma') }}
),

tamanho_turma AS (
    SELECT
        turma_id,
        count(aluno_id) AS tamanho
    FROM turma
    GROUP BY turma_id
),

joined AS (
    SELECT
        {{ 
            dbt_utils.generate_surrogate_key([
                'av.aluno_id',
                'av.turma_id',
                'av.bimestre'
            ])
        }} as avaliacao_sk,
        av.*,
        al.faixa_etaria_nome,
        t.tamanho AS turma_tamanho
    FROM
        avaliacao AS av
    LEFT JOIN
        aluno AS al
        ON av.aluno_id = al.aluno_id
    LEFT JOIN
        tamanho_turma AS t
        ON av.turma_id = t.turma_id
)

SELECT * FROM joined
