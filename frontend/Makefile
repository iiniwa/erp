# 環境構築専用のMakefile。開発サーバー起動は `docker compose up` を直接使う。
#   make build dev   開発イメージのビルド
#   make build prod  本番イメージのビルド

COMPOSE_DEV = docker compose -f ../docker-compose.yml
COMPOSE_PROD = docker compose -f ../docker-compose.prod.yml
RUN_DEV = $(COMPOSE_DEV) run --rm frontend

.PHONY: setup build dev prod lint test

setup: ## 依存パッケージインストール相当（イメージビルド）
	$(COMPOSE_DEV) build frontend

build: ## `make build dev` または `make build prod` でイメージをビルド
ifneq (,$(filter dev,$(MAKECMDGOALS)))
	$(COMPOSE_DEV) build frontend
else ifneq (,$(filter prod,$(MAKECMDGOALS)))
	$(COMPOSE_PROD) build frontend
else
	@echo "Usage: make build dev|prod" && exit 1
endif

dev prod: ## build のターゲット引数（単体では何もしない）
	@:

lint: ## ESLint / Prettier チェック
	$(RUN_DEV) npm run lint

test: ## フロントエンドテスト実行
	$(RUN_DEV) npm test
