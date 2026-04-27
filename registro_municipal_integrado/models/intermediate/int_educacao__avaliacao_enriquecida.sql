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

unpivoted AS (
    SELECT
        *,
        nota,
        disciplina
    FROM
        joined

    {#
      Converte o formato wide de notas:
        portugues | ciencias | ingles | matematica

      Para formato long:
        disciplina | nota

      Isso facilita agregações analíticas por disciplina.
    #}
    UNPIVOT (
        nota FOR disciplina IN (
            portugues,
            ciencias,
            ingles,
            matematica
        )
    )
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
                'disciplina'
            ])
        }} AS avaliacao_sk,

        aluno_id,
        turma_id,
        bimestre,
        disciplina,
        frequencia_anual,

        -- Indica ausência geral do aluno durante o ano letivo
        is_aluno_ausente,

        -- Quando nota é nula significa ausência
        -- especificamente naquela prova/disciplina
        (nota IS NULL) AS is_prova_ausente,

        -- Preenche notas nulas com zero para facilitar cálculos posteriores
        -- sem perder a sinalização de ausência
        COALESCE(nota, 0) AS nota

    FROM unpivoted
)

SELECT *
FROM sk_filled_flagged
