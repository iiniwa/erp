COMPOSE = docker compose --env-file ../.env -f ../docker/docker-compose.yml
RUN = $(COMPOSE) run --rm backend

.PHONY: setup dev db-migrate db-seed db-create lint test

setup: ## bundle install、DBセットアップ
	$(COMPOSE) build backend
	$(RUN) bin/rails db:prepare

dev: ## Railsサーバー起動（docker compose経由）
	$(COMPOSE) up backend

db-create:
	$(RUN) bin/rails db:create

db-migrate: ## マイグレーション実行
	$(RUN) bin/rails db:migrate

db-seed: ## シード投入（管理ユーザーのみ）
	$(RUN) bin/rails db:seed

lint: ## RuboCop チェック
	$(RUN) bin/rubocop

test: ## RSpec実行
	$(RUN) bundle exec rspec
