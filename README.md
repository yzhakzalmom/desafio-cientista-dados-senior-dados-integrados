# Registro Municipal Integrado (RMI) — Desafio Técnico (Cientista de Dados Sênior)

Este repositório implementa o desafio **Registro Municipal Integrado (RMI)** com foco em **analytics engineering**: modelagem em camadas com **dbt**, execução reprodutível com **uv** e automação via **Makefile**, além de **testes de qualidade de dados**.

- **Projeto dbt**: `registro_municipal_integrado/`
- **Warehouse local**: DuckDB (adapter `dbt-duckdb`)
- **Banco de dados**: `registro_municipal_integrado/data/dev.duckdb`

---

## Stack

- **Python**: \(>= 3.12\) (conforme `pyproject.toml` e `uv.lock`)
- **uv**: gerenciamento do ambiente e execução
- **dbt**: `dbt-core` + `dbt-duckdb`
- **DuckDB**: execução local (arquivo `.duckdb`)
- **Pacotes dbt** (em `registro_municipal_integrado/packages.yml`)
  - `dbt-labs/dbt_utils`
  - `metaplane/dbt_expectations`
  - `dbt-labs/codegen`
- **SQLFluff**: lint/format de SQL com templating do dbt (`sqlfluff-templater-dbt`)

---

## Pré-requisitos

- **Python 3.12+**
- **uv** instalado e disponível no PATH
- **GNU Make**

---

## Como executar

### 1) Preparar o ambiente

Sincronize o ambiente a partir do lockfile:

```bash
uv sync
```

Entre no diretório do projeto dbt:

```bash
cd registro_municipal_integrado
```

### 2) Pipeline end-to-end

Instala pacotes do dbt, cria as views de source no DuckDB e executa `dbt build`:

```bash
make full-build
```

### 3) Comandos úteis

Listar alvos disponíveis:

```bash
make help
```

Executar por camada:

```bash
make run-stg
make run-intermediate
```

Rodar testes:

```bash
make test
```

Lint/format SQL (SQLFluff):

```bash
make lint
```

Abrir DuckDB UI:

```bash
make duckdb-ui
```

---

## Dados e ingestão (DuckDB)

O projeto foi estruturado para execução local em DuckDB, com suporte a leitura remota quando aplicável.

- **Profile**: `registro_municipal_integrado/profiles.yml`
  - `type: duckdb`
  - `path: ./data/dev.duckdb`
  - `extensions: [httpfs]`

### Sources no DuckDB

O alvo `make create-source-views` executa uma macro que cria o schema de source (`rmi`) e views no DuckDB apontando para os arquivos de origem (ex.: Parquet via `httpfs`).

```bash
make create-source-views
```

---

## Arquitetura (dbt)

### Camadas

- **Staging** (`registro_municipal_integrado/models/staging/`): padronização, tipagem e validações iniciais.
- **Intermediate** (`registro_municipal_integrado/models/intermediate/`): joins/enriquecimentos e ajustes de grão.
- **Marts** (`registro_municipal_integrado/models/marts/`): camada final orientada ao consumo analítico.

### Materializações

Configuração definida em `registro_municipal_integrado/dbt_project.yml`:

- **staging**: `view`
- **intermediate**: `view`
- **marts**: `table`

---

## Modelos implementados

### Staging

- `stg_rmi__aluno`
- `stg_rmi__escola`
- `stg_rmi__turma`
- `stg_rmi__frequencia`
- `stg_rmi__avaliacao`

Documentação e testes declarativos: `registro_municipal_integrado/models/staging/schema.yml`.

### Intermediate

- `int_educacao__frequencia_enriquecida`: enriquece frequência com atributos de aluno e escola.
- `int_educacao__avaliacao_enriquecida`: enriquece avaliação e normaliza notas por disciplina (unpivot) no grão **aluno + turma + bimestre + disciplina**; gera surrogate key.
- `int_educacao__tamanho_turma`: calcula quantidade de alunos por turma.

Documentação: `registro_municipal_integrado/models/intermediate/schema.yml`.

### Marts

- `mart_educacao__avaliacao_desempenho`: agrega **média de notas** por **disciplina**, **faixa etária**, **tamanho de turma** e **bimestre**, a partir de `int_educacao__avaliacao_enriquecida` e `int_educacao__tamanho_turma`.

---

## Qualidade de dados

### Testes genéricos (schema tests)

Implementados principalmente em `registro_municipal_integrado/models/staging/schema.yml`:

- **Integridade**: `unique`, `not_null`
- **Relacionamentos**: `relationships`
- **Domínios**: conjuntos aceitos (ex.: bimestre, disciplina, faixas etárias)
- **Intervalos**: verificações de faixa com `dbt_expectations` (ex.: frequência 0–100; notas 0–10)
- **Chaves compostas**: `dbt_utils.unique_combination_of_columns`

### Testes de regra de negócio (singular)

- `registro_municipal_integrado/tests/check_data_frequencia.sql`: valida `data_inicio <= data_fim` em `stg_rmi__frequencia` (configurado com severidade `warn`).

---

## Reprodutibilidade

- O ambiente Python é definido em `pyproject.toml` e travado em `uv.lock`.
- `registro_municipal_integrado/requirements.txt`, quando presente, é derivado via `uv export` (alvo `make requirements-txt`) e não é a fonte primária de dependências.