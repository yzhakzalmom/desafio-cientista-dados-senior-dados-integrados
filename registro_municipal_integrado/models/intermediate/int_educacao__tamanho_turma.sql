{#
  Modelo: int_rmi__tamanho_turma

  Objetivo:
    Calcular a quantidade de alunos matriculados por turma.

  Granularidade:
    1 linha por turma

  Uso esperado:
    Este modelo pode ser utilizado por marts ou outros modelos intermediate
    para análises relacionadas ao tamanho da turma e seu impacto em métricas
    como desempenho acadêmico, frequência e evasão.
#}

WITH turma AS (
    -- Base de matrículas/alocação de alunos por turma
    SELECT * FROM {{ ref('stg_rmi__turma') }}
),

tamanho_turma AS (
    SELECT
        -- Identificador único da turma
        turma_id,

        -- Quantidade total de alunos vinculados à turma
        COUNT(aluno_id) AS alunos_qtd

    FROM turma

    -- Agrega para obter uma linha por turma
    GROUP BY turma_id
)

-- Resultado final: tamanho de cada turma
SELECT *
FROM tamanho_turma
