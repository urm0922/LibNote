# LibNote テーブル定義書

## 1. 文書情報

| 項目 | 内容 |
|:---|:---|
| 対象 | LibNote 現行データベース |
| 基準スキーマ | `db/schema.rb` |
| スキーマバージョン | `2026_08_01_073923` |
| 作成日 | 2026-08-07 |
| 開発・テストDB | SQLite3 |
| 本番DB | PostgreSQL（`DATABASE_URL`） |

本書は `db/schema.rb` を物理定義の正とし、列の用途、enum、アプリケーション上の制約について `app/models` とマイグレーションを補助資料として作成しています。型はRailsの論理型で記載しています。

## 2. 記号

| 記号 | 意味 |
|:---|:---|
| PK | 主キー |
| FK | データベース外部キー |
| UQ | 一意インデックス |
| IDX | 非一意インデックス |
| — | 指定なし |

## 3. テーブル一覧

| No. | テーブル名 | 区分 | 概要 |
|---:|:---|:---|:---|
| 1 | `users` | 業務 | ログインユーザー、権限、有効・論理削除状態を管理する |
| 2 | `categories` | 業務 | 問い合わせとナレッジの分類を管理する |
| 3 | `inquiries` | 業務 | 問い合わせ、投稿者、分類、対応・承認状態を管理する |
| 4 | `comments` | 業務 | 問い合わせに対する回答・補足コメントを管理する |
| 5 | `knowledge_articles` | 業務 | 承認済み問い合わせから作成するナレッジ記事を管理する |
| 6 | `faq_entries` | 業務 | ナレッジ記事に属するFAQを管理する |
| 7 | `active_storage_blobs` | Rails標準 | 添付ファイル本体のメタデータを管理する |
| 8 | `active_storage_attachments` | Rails標準 | Active RecordとBlobのポリモーフィックな紐付けを管理する |
| 9 | `active_storage_variant_records` | Rails標準 | 画像変換バリアントを管理する |

## 4. テーブル定義

### 4.1 `users`

ログインユーザーと権限を管理します。`deleted_at` と `active` を使った論理削除・利用停止に対応しています。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | ユーザーID |
| 2 | `email` | string | 不可 | `""` | UQ | ログイン用メールアドレス |
| 3 | `encrypted_password` | string | 不可 | `""` | — | Deviseの暗号化済みパスワード |
| 4 | `reset_password_token` | string | 可 | — | UQ | パスワード再設定トークン |
| 5 | `reset_password_sent_at` | datetime | 可 | — | — | パスワード再設定メール送信日時 |
| 6 | `remember_created_at` | datetime | 可 | — | — | ログイン保持情報の作成日時 |
| 7 | `name` | string | 不可 | `""` | — | 表示名 |
| 8 | `role` | string | 不可 | `"staff"` | — | 権限。`staff` / `manager` / `admin` |
| 9 | `created_at` | datetime | 不可 | — | — | 作成日時 |
| 10 | `updated_at` | datetime | 不可 | — | — | 更新日時 |
| 11 | `active` | boolean | 不可 | `true` | — | 利用可能フラグ |
| 12 | `deleted_at` | datetime | 可 | — | — | 論理削除日時 |

アプリケーション制約: `name` と `role` は必須です。Deviseによりメールアドレス形式・一意性等が検証されます。認証可能条件は `active = true` かつ `deleted_at IS NULL` です。

### 4.2 `categories`

問い合わせとナレッジ記事のカテゴリを管理します。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | カテゴリID |
| 2 | `name` | string | 不可 | — | UQ | カテゴリ名 |
| 3 | `created_at` | datetime | 不可 | — | — | 作成日時 |
| 4 | `updated_at` | datetime | 不可 | — | — | 更新日時 |

アプリケーション制約: `name` は必須かつ一意です。問い合わせまたはナレッジ記事から参照されているカテゴリは、モデル経由では削除できません。

### 4.3 `inquiries`

ユーザーが投稿する問い合わせと、その対応・承認状態を管理します。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | 問い合わせID |
| 2 | `title` | string | 不可 | — | — | タイトル |
| 3 | `body` | text | 不可 | — | — | 本文 |
| 4 | `user_id` | integer | 不可 | — | FK | 投稿者。`users.id` を参照 |
| 5 | `category_id` | integer | 不可 | — | FK | カテゴリ。`categories.id` を参照 |
| 6 | `status` | integer | 不可 | `0` | — | 状態。`draft` / `open` / `answered` / `approved` / `rejected` |
| 7 | `created_at` | datetime | 不可 | — | — | 作成日時 |
| 8 | `updated_at` | datetime | 不可 | — | — | 更新日時 |
| 9 | `approver_id` | bigint | 可 | — | FK, IDX | 承認者。`users.id` を参照 |
| 10 | `approved_at` | datetime | 可 | — | — | 承認日時 |

アプリケーション制約: `title`、`body`、`status` は必須です。`status = approved` の場合は `approved_at` も必須です。`images` という名前で画像を最大3枚添付でき、1枚5MB以下、JPEG・PNG・WebPに制限されています。添付はActive Storageの各テーブルに保存されます。

### 4.4 `comments`

問い合わせに対する回答・補足コメントを管理します。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | コメントID |
| 2 | `inquiry_id` | bigint | 不可 | — | FK, IDX | 対象問い合わせ。`inquiries.id` を参照 |
| 3 | `user_id` | bigint | 不可 | — | FK, IDX | 投稿ユーザー。`users.id` を参照 |
| 4 | `body` | text | 不可 | — | — | コメント本文 |
| 5 | `created_at` | datetime | 不可 | — | — | 作成日時 |
| 6 | `updated_at` | datetime | 不可 | — | — | 更新日時 |

アプリケーション制約: `body` は必須です。問い合わせをモデル経由で削除すると、紐づくコメントも削除されます。

### 4.5 `knowledge_articles`

問い合わせをもとに作成・公開するナレッジ記事を管理します。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | ナレッジ記事ID |
| 2 | `inquiry_id` | bigint | 不可 | — | FK, IDX | 元問い合わせ。`inquiries.id` を参照 |
| 3 | `category_id` | bigint | 不可 | — | FK, IDX | カテゴリ。`categories.id` を参照 |
| 4 | `author_id` | bigint | 不可 | — | FK, IDX | 作成者。`users.id` を参照 |
| 5 | `title` | string | 不可 | — | — | 記事タイトル |
| 6 | `body` | text | 不可 | — | — | 記事本文 |
| 7 | `status` | integer | 不可 | `0` | — | 状態。`draft` / `published` / `archived` |
| 8 | `faq_enabled` | boolean | 不可 | `false` | — | FAQ公開連動フラグ |
| 9 | `published_at` | datetime | 可 | — | — | 公開日時 |
| 10 | `created_at` | datetime | 不可 | — | — | 作成日時 |
| 11 | `updated_at` | datetime | 不可 | — | — | 更新日時 |
| 12 | `generated_by_ai` | boolean | 不可 | `false` | — | AI生成フラグ |

アプリケーション制約: `title`、`body`、`status` は必須です。`status = published` の場合は `published_at` も必須です。問い合わせ側のモデルは記事を0または1件と想定していますが、DBには `inquiry_id` の一意制約がありません。

### 4.6 `faq_entries`

ナレッジ記事から作成するFAQを管理します。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | FAQ ID |
| 2 | `knowledge_article_id` | bigint | 不可 | — | FK, IDX | 所属ナレッジ記事。`knowledge_articles.id` を参照 |
| 3 | `question` | text | 不可 | — | — | 質問文 |
| 4 | `answer` | text | 不可 | — | — | 回答文 |
| 5 | `status` | integer | 不可 | `0` | — | 状態。`draft` / `published` / `archived` |
| 6 | `generated_by_ai` | boolean | 不可 | `false` | — | AI生成フラグ |
| 7 | `published_at` | datetime | 可 | — | — | 公開日時 |
| 8 | `created_at` | datetime | 不可 | — | — | 作成日時 |
| 9 | `updated_at` | datetime | 不可 | — | — | 更新日時 |

アプリケーション制約: `question`、`answer`、`status` は必須です。公開対象は、FAQ自身が `published`、親記事も `published`、かつ親記事の `faq_enabled = true` をすべて満たすレコードです。

### 4.7 `active_storage_blobs`

Active Storageが管理するファイル本体の識別情報とメタデータです。実ファイルは設定されたストレージサービスに保存されます。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | Blob ID |
| 2 | `key` | string | 不可 | — | UQ | ストレージ上の一意キー |
| 3 | `filename` | string | 不可 | — | — | ファイル名 |
| 4 | `content_type` | string | 可 | — | — | MIMEタイプ |
| 5 | `metadata` | text | 可 | — | — | ファイルメタデータ |
| 6 | `service_name` | string | 不可 | — | — | 保存先サービス名 |
| 7 | `byte_size` | bigint | 不可 | — | — | ファイルサイズ（バイト） |
| 8 | `checksum` | string | 可 | — | — | チェックサム |
| 9 | `created_at` | datetime | 不可 | — | — | 作成日時 |

### 4.8 `active_storage_attachments`

Active RecordのレコードとBlobを結び付けます。`record_type` と `record_id` はポリモーフィック参照であり、DB外部キーではありません。現行アプリでは `Inquiry#images` に利用されています。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | 添付ID |
| 2 | `name` | string | 不可 | — | UQ構成列 | 添付関連名。現行用途は `images` |
| 3 | `record_type` | string | 不可 | — | UQ構成列 | 添付先モデル名。現行用途は `Inquiry` |
| 4 | `record_id` | bigint | 不可 | — | UQ構成列 | 添付先レコードID（DB外部キーなし） |
| 5 | `blob_id` | bigint | 不可 | — | FK, IDX, UQ構成列 | Blob。`active_storage_blobs.id` を参照 |
| 6 | `created_at` | datetime | 不可 | — | — | 作成日時 |

### 4.9 `active_storage_variant_records`

Active Storageによる画像変換結果の識別情報を管理します。

| No. | 列名 | 型 | NULL | デフォルト | キー | 説明 |
|---:|:---|:---|:---:|:---|:---|:---|
| 1 | `id` | bigint | 不可 | 自動採番 | PK | バリアントID |
| 2 | `blob_id` | bigint | 不可 | — | FK, UQ構成列 | 元Blob。`active_storage_blobs.id` を参照 |
| 3 | `variation_digest` | string | 不可 | — | UQ構成列 | 変換内容のダイジェスト |

## 5. enum定義

### 5.1 `users.role`

| DB値 | Rails名 | 用途 |
|:---|:---|:---|
| `staff` | `staff` | 一般スタッフ |
| `manager` | `manager` | 回答・運用担当者 |
| `admin` | `admin` | 管理者 |

### 5.2 `inquiries.status`

| DB値 | Rails名 | 用途 |
|---:|:---|:---|
| 0 | `draft` | 下書き |
| 1 | `open` | 未回答・受付中 |
| 2 | `answered` | 回答済み |
| 3 | `approved` | 承認済み |
| 4 | `rejected` | 差し戻し |

### 5.3 `knowledge_articles.status` / `faq_entries.status`

| DB値 | Rails名 | 用途 |
|---:|:---|:---|
| 0 | `draft` | 下書き |
| 1 | `published` | 公開済み |
| 2 | `archived` | アーカイブ済み |

## 6. 外部キー一覧

削除時動作はすべてスキーマで明示されていないため、DBの既定動作（参照行がある場合は削除を拒否）です。モデル経由の削除では、各関連の `dependent` 設定が先に適用されます。

| 子テーブル.列 | 親テーブル.列 | NULL | 備考 |
|:---|:---|:---:|:---|
| `comments.inquiry_id` | `inquiries.id` | 不可 | — |
| `comments.user_id` | `users.id` | 不可 | — |
| `faq_entries.knowledge_article_id` | `knowledge_articles.id` | 不可 | — |
| `inquiries.category_id` | `categories.id` | 不可 | 子列は`integer` |
| `inquiries.user_id` | `users.id` | 不可 | 子列は`integer` |
| `inquiries.approver_id` | `users.id` | 可 | 任意の承認者 |
| `knowledge_articles.category_id` | `categories.id` | 不可 | — |
| `knowledge_articles.inquiry_id` | `inquiries.id` | 不可 | DB上は複数記事を許容 |
| `knowledge_articles.author_id` | `users.id` | 不可 | — |
| `active_storage_attachments.blob_id` | `active_storage_blobs.id` | 不可 | — |
| `active_storage_variant_records.blob_id` | `active_storage_blobs.id` | 不可 | — |

`active_storage_attachments.record_type` / `record_id` は論理的には添付先を参照しますが、ポリモーフィック関連のためDB外部キーはありません。

## 7. インデックス一覧

| テーブル | インデックス名 | 列 | 一意 |
|:---|:---|:---|:---:|
| `users` | `index_users_on_email` | `email` | はい |
| `users` | `index_users_on_reset_password_token` | `reset_password_token` | はい |
| `categories` | `index_categories_on_name` | `name` | はい |
| `comments` | `index_comments_on_inquiry_id` | `inquiry_id` | いいえ |
| `comments` | `index_comments_on_user_id` | `user_id` | いいえ |
| `faq_entries` | `index_faq_entries_on_knowledge_article_id` | `knowledge_article_id` | いいえ |
| `inquiries` | `index_inquiries_on_approver_id` | `approver_id` | いいえ |
| `knowledge_articles` | `index_knowledge_articles_on_author_id` | `author_id` | いいえ |
| `knowledge_articles` | `index_knowledge_articles_on_category_id` | `category_id` | いいえ |
| `knowledge_articles` | `index_knowledge_articles_on_inquiry_id` | `inquiry_id` | いいえ |
| `active_storage_attachments` | `index_active_storage_attachments_on_blob_id` | `blob_id` | いいえ |
| `active_storage_attachments` | `index_active_storage_attachments_uniqueness` | `record_type`, `record_id`, `name`, `blob_id` | はい |
| `active_storage_blobs` | `index_active_storage_blobs_on_key` | `key` | はい |
| `active_storage_variant_records` | `index_active_storage_variant_records_uniqueness` | `blob_id`, `variation_digest` | はい |

## 8. 現行定義上の確認事項

1. `Inquiry` モデルは `has_one :knowledge_article` ですが、`knowledge_articles.inquiry_id` のインデックスは一意ではありません。物理DBは同じ問い合わせに複数記事を登録できます。
2. `inquiries.user_id` と `inquiries.category_id` には外部キーがありますが、検索・JOIN用のインデックスがありません。
3. `inquiries.user_id` / `category_id` は `integer`、参照先の主キーはRails既定の `bigint` です。SQLiteでは運用できますが、本番PostgreSQLへマイグレーションを適用する際は型の整合性確認が必要です。
4. `inquiries.approved_at` と `knowledge_articles.published_at` の条件付き必須はRailsモデルだけで保証され、DBのCHECK制約はありません。
5. `active_storage_attachments.record_id` はポリモーフィック参照のため、添付先レコードの存在をDB外部キーでは保証しません。
