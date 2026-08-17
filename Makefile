COMPOSE = docker compose --env-file .env -f docker/docker-compose.yml

.PHONY: up down build logs ps restart setup

setup: ## 初回セットアップ（.env作成 + イメージビルド）
	@test -f .env || cp .env.example .env
	$(MAKE) build

build:
	$(COMPOSE) build

up: ## 全コンテナ起動（フォアグラウンド）
	$(COMPOSE) up

down: ## 全コンテナ停止・削除
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps
