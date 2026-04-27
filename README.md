# Desafio Técnico — Cientista de Dados Sênior (RMI)

Implementação do desafio **Registro Municipal Integrado (RMI)** com ênfase em **analytics engineering**: modelagem em camadas no **dbt**, estratégia de **testes de qualidade de dados**, e reprodutibilidade via **Makefile + uv**.

- **Projeto dbt**: `registro_municipal_integrado/`
- **Warehouse local**: DuckDB (adapter `dbt-duckdb`)
- **Interface de execução (obrigatória)**: `Makefile` (tudo roda via `uv`)

---

## Tecnologias e ferramentas

- **Python**: \(>= 3.12\) (conforme `pyproject.toml` e `uv.lock`)
- **uv**: gerenciamento e execução do ambiente (lock em `uv.lock`)
- **dbt**: `dbt-core` + `dbt-duckdb`
- **DuckDB**: arquivo local `registro_municipal_integrado/data/dev.duckdb`
- **Pacotes dbt** (em `registro_municipal_integrado/packages.yml`)
  - `dbt-labs/dbt_utils`
  - `metaplane/dbt_expectations`
  - `dbt-labs/codegen`
- **SQLFluff**: formatação/lint de SQL com templating dbt (`sqlfluff-templater-dbt`)

---

## Requisitos do sistema

- **GNU Make**
- **uv** instalado e disponível no PATH
- **Python 3.12+**

### Instalação do GNU Make (resumo)

#### Windows

- **Chocolatey**:

```bash
choco install make
```

- **Winget** (GnuWin32 Make):

```bash
winget install GnuWin32.Make
```

#### Linux

- **Debian/Ubuntu**:

```bash
sudo apt-get update && sudo apt-get install -y make
```

#### macOS

- **Xcode Command Line Tools** (inclui `make`):

```bash
xcode-select --install
```

> Observação: este repositório utiliza `uv` para garantir um ambiente reprodutível. A execução deve ser preferencialmente feita **via `make`** (o `Makefile` encapsula `uv run ...`). Caso opte por rodar os comandos dbt de maneira direta, não se esqueça de escrevê-los após `uv run`

---

## Como executar (via Makefile)

### Inicialização do ambiente (obrigatório)

Sincroniza o ambiente a partir do lockfile (`uv.lock`). Este é o primeiro comando a ser executado ao clonar/atualizar o repositório:

```bash
uv sync
```

Todos os comandos abaixo devem ser executados dentro de `registro_municipal_integrado/`:

```bash
cd registro_municipal_integrado
```

### Descobrir comandos disponíveis

```bash
make help
```

### Instalar dependências do dbt (packages)

```bash
make deps
```

### Pipeline recomendado (end-to-end)

Executa `dbt deps`, cria as views de source e roda `dbt build`:

```bash
make full-build
```

### Fluxo de execução (Makefile) — visão sucinta

- **Setup dbt packages**: `make deps` → `uv run dbt deps`
- **Criar sources no DuckDB**: `make create-source-views` → `uv run dbt run-operation create_source_views`
- **Executar por camada**
  - `make run-stg` → `uv run dbt run --select "models/staging"`
  - `make run-intermediate` → `uv run dbt run --select "models/intermediate"`
- **Build completo**: `make build` → `uv run dbt build`
- **Orquestração**
  - `make full-run-stg` → `deps` + `create-source-views` + `run-stg`
  - `make full-build` → `deps` + `create-source-views` + `build`

### Comandos disponíveis (Makefile)

> Referência rápida (para detalhes, use `make help`).

- **Básicos dbt**: `build`, `clean`, `deps`, `test`
- **Qualidade SQL**: `lint` (executa `sqlfluff fix` em `models/` e `tests/`)
- **DuckDB**: `duckdb-ui`
- **uv**: `requirements-txt` (exporta `requirements.txt` via `uv export`)
- **Macros (dbt)**: `create-source-views`
- **Codegen (dbt-codegen)**
  - `stg-base-models` (gera SQL base de staging para `aluno`, `avaliacao`, `escola`, `frequencia`, `turma`)
  - `stg-models-schema` (gera `schema.yml` de staging)
  - `int-models-schema` (gera `schema.yml` da camada intermediate)
  - `codegen-stg` (pipeline completo: `deps` + `create-source-views` + `stg-base-models` + `run-stg` + `stg-models-schema`)

### Execuções por camada

```bash
make run-stg
make run-intermediate
```

### Testes

```bash
make test
```

### Lint / formatação SQL

```bash
make lint
```

### DuckDB UI

```bash
make duckdb-ui
```

---

## Dados e ingestão (visão de execução)

O projeto foi estruturado para consumo local em DuckDB, com suporte a leitura remota quando aplicável.

- **Profile**: `registro_municipal_integrado/profiles.yml`
  - `type: duckdb`
  - `path: ./data/dev.duckdb`
  - `extensions: [httpfs]`

### Sources no DuckDB (macro)

O alvo `make create-source-views` executa uma macro que:

- Cria o schema de source (`rmi`)
- Cria views no DuckDB apontando para os Parquets (ex.: via `httpfs`)

```bash
make create-source-views
```

---

## Arquitetura do projeto (dbt)

### Convenção de camadas

- **Staging** (`registro_municipal_integrado/models/staging/`): padronização, tipagem e validações iniciais.
- **Intermediate** (`registro_municipal_integrado/models/intermediate/`): joins/enriquecimentos e transformações de grão.
- **Marts** (`registro_municipal_integrado/models/marts/`): camada final orientada ao consumo analítico.

### Materializações (config em `registro_municipal_integrado/dbt_project.yml`)

- **staging**: `view`
- **intermediate**: `view`
- **marts**: `table`

---

## Entregas implementadas (alinhadas ao enunciado)

### Parte 1 — Projeto dbt e Modelagem

#### 1) Configuração e estrutura do projeto

- **Projeto dbt funcional** em `registro_municipal_integrado/`
- **Estrutura por camadas** configurada no `dbt_project.yml`
- **Execução reprodutível** via `Makefile` utilizando `uv run ...`

#### 2) Camada de staging (>= 4 tabelas)

Models implementados:

- `stg_rmi__aluno`
- `stg_rmi__escola`
- `stg_rmi__turma`
- `stg_rmi__frequencia`
- `stg_rmi__avaliacao`

Documentação e testes declarativos: `registro_municipal_integrado/models/staging/schema.yml`.

#### 3) Camada intermediate (>= 1 model combinando múltiplas fontes)

Models implementados:

- `int_educacao__frequencia_enriquecida`: enriquece frequência com atributos de aluno e escola.
- `int_educacao__avaliacao_enriquecida`: enriquece avaliação e normaliza notas por disciplina (unpivot) no grão **aluno + turma + bimestre + disciplina**; gera surrogate key.
- `int_educacao__tamanho_turma`: calcula quantidade de alunos por turma.

Documentação: `registro_municipal_integrado/models/intermediate/schema.yml`.

### Parte 2 — Testes e Qualidade de Dados

#### 5) Testes genéricos (schema tests)

Implementados principalmente em `registro_municipal_integrado/models/staging/schema.yml`:

- **Integridade**: `unique`, `not_null`
- **Relacionamentos**: `relationships` (FKs entre staging)
- **Domínios**: conjuntos aceitos (ex.: bimestre, disciplina, faixas etárias)
- **Intervalos**: verificações de faixa (ex.: frequência 0–100; notas 0–10) com `dbt_expectations`
- **Chaves compostas**: `dbt_utils.unique_combination_of_columns`

#### 6) Testes de regra de negócio (singular/customizados)

Teste singular implementado:

- `registro_municipal_integrado/tests/check_data_frequencia.sql`: valida `data_inicio <= data_fim` em `stg_rmi__frequencia` (severidade `warn`).

---

## Pendências (com lembretes)

### Parte 1 — Projeto dbt e Modelagem

#### 4) Camada de Marts

**Lembrete**: criar pelo menos **1 mart** em `registro_municipal_integrado/models/marts/` (table ou incremental) para responder uma pergunta analítica do enunciado, incluindo `schema.yml` e uma breve análise dos resultados.

### Parte 2 — Testes e Qualidade de Dados

#### 6) Testes de Regra de Negócio (mínimo 2)

**Lembrete**: adicionar **ao menos mais 1** teste singular/customizado (total \(>= 2\)), com documentação da regra e motivação.

### Parte 3 — Documentação e Análise

#### 8) Documentação do Projeto

**Lembrete**: complementar a documentação com:

- **Lineage** (staging → intermediate → marts) e grãos por modelo
- **Decisões de arquitetura** (materializações, SKs, critérios de testes)
- **Trade-offs** e próximos passos

#### 9) Análise Exploratória (opcional — diferencial)

**Lembrete**: (opcional) adicionar notebook em `notebooks/` com EDA e achados que motivaram decisões de modelagem/testes.

---

## Notas de reprodutibilidade

- O ambiente Python é definido em `pyproject.toml` e travado em `uv.lock`.
- O arquivo `registro_municipal_integrado/requirements.txt` é **gerado automaticamente** via `uv export` (alvo `requirements-txt`), e não é a fonte primária de dependências.