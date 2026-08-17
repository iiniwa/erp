# frontend

Next.js（App Router）+ Tailwind CSS。詳細は[リポジトリルートのREADME](../README.md)、
仕様は[docs/ERP_phase1_spec.md](../docs/ERP_phase1_spec.md)を参照。

## 開発サーバーの起動

このプロジェクトはDocker上で完結する構成のため、ホストにNode.jsのインストールは不要。

```sh
# リポジトリルートで
make setup
make build dev
docker compose -f docker/docker-compose.yml up frontend
```

http://localhost:3000 で確認できる。`src/app/page.tsx` を編集すると自動でリロードされる。

## よく使うコマンド

```sh
make build dev   # 開発イメージのビルド
make build prod  # 本番イメージのビルド
make lint         # ESLint / Prettier チェック
make test         # フロントエンドテスト実行
```

いずれも `frontend/` 配下で実行する（内部的に `docker compose run --rm frontend ...` を呼ぶ）。

## この版のNext.jsについて

このリポジトリのNext.jsは学習データより新しいバージョンを使用しており、API・規約が
異なる場合がある。コードを書く前に[AGENTS.md](./AGENTS.md)の指示に従い、
`node_modules/next/dist/docs/` 配下の該当ガイドを確認すること。
