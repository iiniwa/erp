# 環境構築専用のMakefile。サーバー起動は `docker compose up` を直接使う。
#   make build dev   開発イメージのビルド
#   make build prod  本番イメージのビルド

COMPOSE_DEV = docker compose -f ../docker-compose.yml
COMPOSE_PROD = docker compose -f ../docker-compose.prod.yml
RUN_DEV = $(COMPOSE_DEV) run --rm backend

.PHONY: setup build dev prod db-create db-migrate db-seed lint test

setup: ## bundle install相当（イメージビルド）+ DBセットアップ
	$(COMPOSE_DEV) build backend
	$(RUN_DEV) bin/rails db:prepare

build: ## `make build dev` または `make build prod` でイメージをビルド
ifneq (,$(filter dev,$(MAKECMDGOALS)))
	$(COMPOSE_DEV) build backend
else ifneq (,$(filter prod,$(MAKECMDGOALS)))
	$(COMPOSE_PROD) build backend
else
	@echo "Usage: make build dev|prod" && exit 1
endif

dev prod: ## build のターゲット引数（単体では何もしない）
	@:

db-create:
	$(RUN_DEV) bin/rails db:create

db-migrate: ## マイグレーション実行
	$(RUN_DEV) bin/rails db:migrate

db-seed: ## シード投入（管理ユーザーのみ）
	$(RUN_DEV) bin/rails db:seed

lint: ## RuboCop チェック
	$(RUN_DEV) bin/rubocop

test: ## RSpec実行（テストDBを使うようRAILS_ENVを上書き）
	$(COMPOSE_DEV) run --rm -e RAILS_ENV=test backend bundle exec rspec
