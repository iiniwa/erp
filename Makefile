# 環境構築専用のMakefile。起動は `docker compose up` を直接使う。
#   make build dev   開発環境イメージのビルド（docker-compose.yml）
#   make build prod  本番環境イメージのビルド（docker-compose.prod.yml）
#
# .env をcompose fileと同じディレクトリ（リポジトリルート）に置いているため、
# `docker compose` 実行時に --env-file を指定する必要はない。
#
# 起動例:
#   docker compose -f docker-compose.yml up       (dev)
#   docker compose -f docker-compose.prod.yml up  (prod)

COMPOSE_DEV = docker compose -f docker-compose.yml
COMPOSE_PROD = docker compose -f docker-compose.prod.yml

.PHONY: setup _generate-env build dev prod lint

setup: ## .env作成（初回のみ。旧docker/.envからの移行にも対応）
	@if [ -f .env ]; then \
		echo ".env は既に存在するため作成をスキップします"; \
	elif [ -f docker/.env ]; then \
		mv docker/.env .env && echo "docker/.env を .env に移行しました"; \
	else \
		$(MAKE) _generate-env; \
	fi

_generate-env: ## パスワード/シークレット類をランダム生成した.envを新規作成
	cp .env.example .env
	sed -i.bak "s/^DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=$$(openssl rand -hex 24)/" .env
	sed -i.bak "s/^DB_PASSWORD=.*/DB_PASSWORD=$$(openssl rand -hex 24)/" .env
	sed -i.bak "s/^INTERNAL_API_SECRET=.*/INTERNAL_API_SECRET=$$(openssl rand -hex 32)/" .env
	sed -i.bak "s/^SFTPGO_ADMIN_PASSWORD=.*/SFTPGO_ADMIN_PASSWORD=$$(openssl rand -hex 16)/" .env
	rm -f .env.bak
	echo ".env を作成しました（DB/内部API/SFTPGo管理者パスワードはランダム生成済み）"

build: ## `make build dev` または `make build prod` でイメージをビルド
ifneq (,$(filter dev,$(MAKECMDGOALS)))
	$(COMPOSE_DEV) build
else ifneq (,$(filter prod,$(MAKECMDGOALS)))
	$(COMPOSE_PROD) build
else
	@echo "Usage: make build dev|prod" && exit 1
endif

dev prod: ## build のターゲット引数（単体では何もしない）
	@:

lint: ## frontend/backend双方のLintを実行
	$(MAKE) -C frontend lint
	$(MAKE) -C backend lint
