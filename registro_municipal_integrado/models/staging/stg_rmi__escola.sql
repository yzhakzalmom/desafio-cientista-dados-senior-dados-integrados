

with source as (

    select * from {{ source('rmi', 'escola') }}

),

renamed as (

    select
        id_escola,
        bairro

    from source

)

select * from renamed

