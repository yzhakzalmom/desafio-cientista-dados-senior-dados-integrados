{#
  Modelo: int_rmi__frequencia
  Camada: Intermediate (int)

  Objetivo:
    Enriquece os registros de frequência anual por disciplina com atributos
    do aluno (bairro e faixa etária) e da escola (bairro), permitindo análises
    geográficas e demográficas nas camadas downstream.

  Granularidade: escola + aluno + turma + disciplina + data_inicio
  (herdada de stg_rmi__frequencia)

  Fontes:
    - stg_rmi__frequencia : frequência anual por aluno/turma/disciplina
    - stg_rmi__aluno      : atributos do aluno (bairro, faixa etária)
    - stg_rmi__escola     : atributos da escola (bairro)
#}

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
        {#
          Surrogate key (SK) da frequência, derivada dos cinco campos que
          compõem a PK natural de stg_rmi__frequencia.
          Usada como chave técnica em joins nas camadas downstream (mart).
        #}
        {{ dbt_utils.generate_surrogate_key([
            'f.escola_id',
            'f.turma_id',
            'f.aluno_id',
            'f.disciplina',
            'f.data_inicio'
            ])
        }} AS frequencia_sk,

        -- Todos os campos de frequência (percentual, flags de ausência,
        -- disciplina, datas de início e fim do período)
        f.*,

        -- Bairro de residência do aluno
        a.bairro AS aluno_bairro,

        -- Faixa etária descritiva do aluno (ex: 'Adolescente')
        -- Permite segmentar a frequência por perfil demográfico
        a.faixa_etaria_nome AS aluno_faixa_etaria,

        -- Bairro onde a escola está localizada
        e.bairro AS escola_bairro

    FROM
        frequencia AS f

    {#
      LEFT JOINs preservam todos os registros de frequência mesmo que
      o aluno ou a escola não sejam encontrados nas dimensões.
      Inconsistências desse tipo são detectadas pelos testes de FK
      definidos em stg_rmi__frequencia antes de chegarem aqui.
    #}
    LEFT JOIN
        aluno AS a
        ON f.aluno_id = a.aluno_id
    LEFT JOIN
        escola AS e
        ON f.escola_id = e.escola_id
)

SELECT * FROM joined
