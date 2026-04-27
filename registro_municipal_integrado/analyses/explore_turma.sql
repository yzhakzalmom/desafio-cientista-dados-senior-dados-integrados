select turma_id, count(aluno_id)
from {{ ref('stg_rmi__turma') }}
group by turma_id