# ERPシステム

ログイン機能・従業員管理・アドレス帳を中心としたERPシステム（第一フェーズ）。
仕様の詳細は [docs/ERP_phase1_spec.md](docs/ERP_phase1_spec.md) を参照。

## 構成

```
/repo-root
 ├─ frontend/    Next.js（Tailwind CSS, PWA対応）
 ├─ backend/     Ruby on Rails（APIモード）
 ├─ docker/      Docker Compose定義
 └─ docs/        ドキュメント
```

- フロントエンド: Next.js + Tailwind CSS
- バックエンド: Ruby on Rails（APIモード）
- DB: MariaDB
- ファイルストレージ: SFTPGo（S3互換API）

## 初回セットアップ

必要なもの: Docker / Docker Compose

Makefileは**環境構築（イメージのビルド）専任**。起動・停止は `docker compose`
を直接使う。`docker/.env` はcompose fileと同じディレクトリに置いており、
Composeが自動で読み込むため `docker compose` 実行時に `--env-file` の指定は不要。

```sh
git clone <このリポジトリ>
cd erp
make setup        # docker/.env を作成
make build dev    # 開発環境イメージをビルド
```

`docker/.env` の `RAILS_MASTER_KEY` は各自ローカルで発行する（詳しくは
[Railsの認証情報](#railsの認証情報) を参照）。値が空でも開発環境では動作するが、
本番環境（`docker-compose.prod.yml`）では必須。

```sh
docker compose -f docker/docker-compose.yml up
```

- フロントエンド: http://localhost:3000
- バックエンドAPI: http://localhost:3001 （ヘルスチェック: `/up`, `/api/v1/health`）
- SFTPGo管理画面: http://localhost:8080

本番相当のイメージ（`backend/Dockerfile`, `frontend/Dockerfile`）で動作確認したい場合:

```sh
make build prod
docker compose -f docker/docker-compose.prod.yml up
```

## よく使うコマンド

ルート直下:

```sh
make setup       # docker/.env作成
make build dev    # 開発環境イメージのビルド
make build prod   # 本番環境イメージのビルド
```

`frontend/` 配下:

```sh
make setup       # 開発イメージビルド
make build dev    # 開発環境イメージのビルド
make build prod   # 本番環境イメージのビルド
make lint         # ESLint / Prettier チェック
make test         # フロントエンドテスト実行
```

`backend/` 配下:

```sh
make setup        # 開発イメージビルド + DBセットアップ
make build dev     # 開発環境イメージのビルド
make build prod    # 本番環境イメージのビルド
make db-migrate    # マイグレーション実行
make db-seed       # シード投入（管理ユーザーのみ）
make lint          # RuboCop チェック
make test          # RSpec実行
```

`lint`/`test`/`db-*` は `docker compose run --rm` 経由で開発イメージ上で実行するため、
ローカルにNode.js/Rubyのインストールは不要（Dockerさえあれば動作する）。

## Railsの認証情報

`backend/config/master.key` はGit管理対象外（公開リポジトリのため）。
ローカルで新規に鍵ペアを作りたい場合は、`backend/config/credentials.yml.enc`
を削除した上で以下を実行する。

```sh
cd backend
EDITOR="tee" bin/rails credentials:edit
```

チームで鍵を共有する場合は、`config/master.key` の内容をパスワードマネージャー等
Git以外の経路で受け渡すこと。

## コーディング規約

- フロントエンド: ESLint + Prettier（`frontend/eslint.config.mjs`, `.prettierrc.json`）
- バックエンド: RuboCop（`rubocop-rails-omakase`ベース、`backend/.rubocop.yml`）
- 詳細は [docs/ERP_phase1_spec.md](docs/ERP_phase1_spec.md) の12章を参照
