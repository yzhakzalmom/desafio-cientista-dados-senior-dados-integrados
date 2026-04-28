{#
  Modelo: int_rmi__avaliacao
  Camada: Intermediate (int)

  Objetivo:
    Enriquece os registros de avaliação bimestral com atributos do aluno
    (faixa etária), consolidando as informações
    necessárias para análises downstream na camada mart.

  Granularidade:
    aluno + turma + bimestre + disciplina

  Fontes:
    - stg_rmi__avaliacao : notas e frequência por aluno/turma/bimestre
    - stg_rmi__aluno     : atributos do aluno
#}

WITH avaliacao AS (
    SELECT *
    FROM {{ ref('stg_rmi__avaliacao') }}
),

aluno AS (
    SELECT *
    FROM {{ ref('stg_rmi__aluno') }}
),

joined AS (
    SELECT
        -- Todos os campos originais de avaliação
        av.*,

        -- Faixa etária descritiva do aluno
        -- Ex.: Infantil, Adolescente
        al.faixa_etaria_nome

    FROM
        avaliacao AS av

    {#
      LEFT JOIN garante preservação total dos registros de avaliação,
      mesmo em casos de inconsistência cadastral na tabela de alunos.
    #}
    LEFT JOIN
        aluno AS al
        ON av.aluno_id = al.aluno_id
),

sk_filled_flagged AS (
    SELECT
        -- Chave substituta que identifica unicamente
        -- cada avaliação por aluno/turma/bimestre/disciplina
        {{
            dbt_utils.generate_surrogate_key([
                'aluno_id',
                'turma_id',
                'bimestre',
            ])
        }} AS avaliacao_sk,

        aluno_id,
        faixa_etaria_nome,
        faixa_etaria_nome,
        turma_id,
        bimestre,
        frequencia_anual,
        portugues,
        ciencias,
        ingles,
        matematica,

        -- Indica ausência geral do aluno durante o ano letivo
        is_aluno_ausente

    FROM joined
)

SELECT *
FROM sk_filled_flagged
