

with source as (

    select * from {{ source('rmi', 'aluno') }}

),

renamed as (

    select
        id_aluno,
        id_turma,
        faixa_etaria,
        bairro

    from source

)

select * from renamed

