COMPOSE = docker compose --env-file ../.env -f ../docker/docker-compose.yml
RUN = $(COMPOSE) run --rm frontend

.PHONY: setup dev lint test build

setup: ## 依存パッケージインストール
	$(COMPOSE) build frontend

dev: ## 開発サーバー起動（docker compose経由）
	$(COMPOSE) up frontend

lint: ## ESLint / Prettier チェック
	$(RUN) npm run lint

test: ## フロントエンドテスト実行
	$(RUN) npm test

build: ## 本番ビルド
	$(RUN) npm run build
