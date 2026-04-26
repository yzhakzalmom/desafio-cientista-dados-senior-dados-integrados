WITH source AS (

    SELECT * FROM {{ source('rmi', 'escola') }}

),

renamed_typed AS (

    SELECT
        cast(id_escola AS bigint) AS escola_id,
        cast(bairro AS bigint) AS bairro

    FROM source

)

SELECT * FROM renamed_typed
