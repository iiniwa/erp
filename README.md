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

```sh
git clone <このリポジトリ>
cd erp
make setup   # .env を作成し、イメージをビルドする
```

`.env` の `RAILS_MASTER_KEY` は各自ローカルで発行する（詳しくは
[backend/config/master.key の発行](#railsの認証情報) を参照）。値が空でも
開発環境では動作するが、Active Storage 等の暗号化情報を扱う場合は必須になる。

```sh
make up      # フロントエンド／バックエンド／DB／SFTPGoを起動
```

- フロントエンド: http://localhost:3000
- バックエンドAPI: http://localhost:3001 （ヘルスチェック: `/up`, `/api/v1/health`）
- SFTPGo管理画面: http://localhost:8080

## よく使うコマンド

ルート直下:

```sh
make up       # 全コンテナ起動
make down     # 全コンテナ停止・削除
make build    # イメージ再ビルド
make logs     # ログ追跡
make ps       # コンテナ状態確認
```

`frontend/` 配下:

```sh
make setup    # イメージビルド（依存パッケージインストール）
make dev      # 開発サーバー起動
make lint     # ESLint / Prettier チェック
make test     # フロントエンドテスト実行
make build    # 本番ビルド
```

`backend/` 配下:

```sh
make setup       # bundle install、DBセットアップ
make dev         # Railsサーバー起動
make db-migrate  # マイグレーション実行
make db-seed     # シード投入（管理ユーザーのみ）
make lint        # RuboCop チェック
make test        # RSpec実行
```

いずれも内部的に `docker compose` を呼び出すため、ローカルにNode.js/Rubyの
インストールは不要（Dockerさえあれば動作する）。

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
