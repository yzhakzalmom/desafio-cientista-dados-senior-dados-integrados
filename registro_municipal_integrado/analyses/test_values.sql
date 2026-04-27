{# select aluno_id, turma_id, disciplina, data_inicio, count(data_inicio)
from {{ ref("stg_rmi__frequencia") }}
group by escola_id, aluno_id, turma_id, disciplina, data_inicio
having count(data_inicio) > 1 #}

SELECT *
FROM {{ ref('stg_rmi__frequencia') }}
WHERE aluno_id = '170276E96D42419AD338D080E5EE920FE8'
