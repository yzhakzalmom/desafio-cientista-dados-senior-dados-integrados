# Variáveis
STAGING_DIR = ./models/staging/
SOURCE = rmi
TABLES = aluno avaliacao escola frequencia turma

.PHONY: help deps create-source-views stg-base-models stg-models-schema codegen-stg lint run test docs

help: ## Lista todos os comandos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

deps: ## Instala dependências do dbt
	uv run dbt deps


run-stg: ## Executa os models dbt
	uv run dbt run --select "models/staging"

create-source-views: ## Cria o schema rmi e as views no DuckDB apontando para o GCS
	uv run dbt run-operation create_source_views

stg-base-models: ## Gera os .sql de staging para todas as tabelas do source rmi
	@mkdir -p $(STAGING_DIR)
	@for table in $(TABLES); do \
		echo ">>> Gerando stg_$(SOURCE)__$$table.sql"; \
		uv run dbt --quiet run-operation generate_base_model \
			--args "{\"source_name\": \"$(SOURCE)\", \"table_name\": \"$$table\"}" \
			2>/dev/null \
			| grep -v "^[0-9]\{2\}:" \
			> $(STAGING_DIR)/stg_$(SOURCE)__$$table.sql; \
	done

stg-models-schema: ## Gera o schema.yml com descrição dos models de staging
	@echo ">>> Gerando schema.yml"
	@uv run dbt --quiet run-operation generate_model_yaml \
		--args '{"model_names": [$(shell echo $(TABLES) | sed "s/\([^ ]*\)/\"stg_$(SOURCE)__\1\"/g; s/ /, /g")]}' \
		2>/dev/null \
		| grep -v "^[0-9]\{2\}:" \
		> $(STAGING_DIR)/schema.yml

codegen-stg: deps create-source-views stg-base-models run-stg stg-models-schema ## Pipeline completo: instala deps, cria views e roda codegen

# lint: ## Roda sqlfluff lint nos models
# 	uv run sqlfluff lint models/

test: ## Roda os testes dbt
	uv run dbt test

# docs: ## Gera e serve a documentação
# 	uv run dbt docs generate && uv run dbt docs serve