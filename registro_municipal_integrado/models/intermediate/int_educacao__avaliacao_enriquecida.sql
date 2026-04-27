{#
  Modelo: int_rmi__avaliacao
  Camada: Intermediate (int)
  
  Objetivo:
    Enriquece os registros de avaliação bimestral com atributos do aluno
    (faixa etária) e da turma (tamanho), consolidando as informações
    necessárias para análises downstream na camada mart.

  Granularidade: aluno + turma + bimestre (herdada de stg_rmi__avaliacao)

  Fontes:
    - stg_rmi__avaliacao : notas e frequência por aluno/turma/bimestre
    - stg_rmi__aluno     : atributos do aluno (faixa etária, bairro)
    - stg_rmi__turma     : matrículas — usada apenas para calcular o tamanho da turma
#}

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

{# 
  Calcula o tamanho de cada turma contando os alunos matriculados.
  stg_rmi__turma tem granularidade aluno + turma, então um COUNT(aluno_id)
  por turma_id equivale ao número de alunos matriculados na turma.
  Este agregado é feito aqui para evitar fanout na CTE joined abaixo.
#}
tamanho_turma AS (
    SELECT
        turma_id,
        count(aluno_id) AS tamanho
    FROM turma
    GROUP BY turma_id
),

joined AS (
    SELECT
        {#
          Surrogate key (SK) da avaliação, gerada a partir dos três campos
          que compõem a PK natural de stg_rmi__avaliacao.
          Usada como chave técnica em joins nas camadas downstream (mart).
        #}
        {{ 
            dbt_utils.generate_surrogate_key([
                'av.aluno_id',
                'av.turma_id',
                'av.bimestre'
            ])
        }} AS avaliacao_sk,

        -- Todos os campos de avaliação (notas, frequência, flags de ausência, bimestre)
        av.*,

        -- Atributo descritivo do aluno: faixa etária por extenso (ex: 'Adolescente')
        -- Derivado de stg_rmi__aluno.faixa_etaria_num, útil para segmentação analítica
        al.faixa_etaria_nome,

        -- Quantidade de alunos matriculados na turma no ano letivo
        -- Permite análises de desempenho relativas ao porte da turma
        t.tamanho AS turma_tamanho

    FROM
        avaliacao av

    {#
      LEFT JOINs garantem que nenhum registro de avaliação seja descartado
      caso o aluno ou a turma não sejam encontrados nas tabelas de dimensão.
      Isso pode ocorrer em casos de inconsistência na fonte ou carga parcial.
      Os testes de FK em stg_rmi__avaliacao sinalizam esses casos previamente.
    #}
    LEFT JOIN
        aluno al
        ON av.aluno_id = al.aluno_id
    LEFT JOIN
        tamanho_turma t
        ON av.turma_id = t.turma_id
)

SELECT * FROM joined