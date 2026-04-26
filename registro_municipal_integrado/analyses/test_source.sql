SELECT hex(id_aluno)
FROM
    {{ source('rmi', 'frequencia') }}