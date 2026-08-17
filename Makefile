# 環境構築専用のMakefile。起動は `docker compose up` を直接使う。
#   make build dev   開発環境イメージのビルド（docker/docker-compose.yml）
#   make build prod  本番環境イメージのビルド（docker/docker-compose.prod.yml）
#
# docker/.env をcompose fileと同じディレクトリに置いているため、
# `docker compose` 実行時に --env-file を指定する必要はない。
#
# 起動例:
#   docker compose -f docker/docker-compose.yml up       (dev)
#   docker compose -f docker/docker-compose.prod.yml up  (prod)

COMPOSE_DEV = docker compose -f docker/docker-compose.yml
COMPOSE_PROD = docker compose -f docker/docker-compose.prod.yml

.PHONY: setup build dev prod

setup: ## docker/.env作成（初回のみ）
	@test -f docker/.env || cp docker/.env.example docker/.env

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
