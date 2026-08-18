# backend

Ruby on Rails（APIモード）。詳細は[リポジトリルートのREADME](../README.md)、
仕様は[docs/ERP_phase1_spec.md](../docs/ERP_phase1_spec.md)を参照。

## 開発サーバーの起動

このプロジェクトはDocker上で完結する構成のため、ホストにRuby/Bundlerのインストールは不要。

```sh
# リポジトリルートで
make setup
make build dev
docker compose -f docker/docker-compose.yml up backend
```

http://localhost:3001 で確認できる（ヘルスチェック: `/up`, `/api/v1/health`）。

## よく使うコマンド

```sh
make build dev     # 開発イメージのビルド
make build prod     # 本番イメージのビルド
make db-migrate     # マイグレーション実行
make db-seed        # シード投入（管理ユーザーのみ）
make lint           # RuboCop チェック
make test           # RSpec実行（テストDBを使用）
```

いずれも `backend/` 配下で実行する（内部的に `docker compose run --rm backend ...` を呼ぶ）。

## Railsの認証情報

`config/master.key` はGit管理対象外（公開リポジトリのため）。ローカルで新規に
鍵ペアを作りたい場合は`config/credentials.yml.enc`を削除した上で、
リポジトリルートから以下を実行する（詳しくは[ルートREADME](../README.md#railsの認証情報)を参照）。

```sh
docker compose -f docker/docker-compose.yml run --rm -it -e EDITOR=nano backend bin/rails credentials:edit
```
