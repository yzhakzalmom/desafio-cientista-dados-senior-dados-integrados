WITH source AS (

    SELECT * FROM {{ source('rmi', 'turma') }}

),

renamed_typed AS (

    SELECT
        cast(ano AS int) AS ano,
        cast(id_turma AS bigint) AS turma_id,
        cast(hex(id_aluno) AS varchar) AS aluno_id

    FROM source

)

SELECT * FROM renamed_typed
