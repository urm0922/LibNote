# カテゴリ管理画面・CRUD 実装の学びメモ

作成日: 2026-07-30

## 今回の実装範囲

- 管理者専用のカテゴリ管理画面
- カテゴリの一覧・登録・編集・削除
- 空欄・重複の入力検証
- 問い合わせ・ナレッジで使用中のカテゴリの削除拒否
- 管理者向けヘッダーリンク
- 問い合わせ件数・ナレッジ件数の表示
- カテゴリ名検索
- 名前・作成日時による並び替え
- Kaminariによるページネーション
- モデルテスト・コントローラテスト

## 設計で意識したこと

### 管理機能を名前空間で分離する

管理画面は`/admin/categories`配下とし、`Admin::BaseController`で認証と管理者判定を共通化した。

これにより、今後ユーザー／ロール管理を追加する場合も、同じ管理者向けの基盤を再利用できる。

```ruby
namespace :admin do
  resources :categories, except: :show
end
```

カテゴリは名前以外の詳細情報を持たないため、Readは一覧画面で満たし、詳細画面は作らなかった。

### 使用中のカテゴリを連鎖削除しない

カテゴリを削除したときに、関連する問い合わせやナレッジまで削除されるのは危険である。そのため、関連データが存在する場合は削除を拒否する方針にした。

```ruby
has_many :inquiries, dependent: :restrict_with_error
has_many :knowledge_articles, dependent: :restrict_with_error
```

画面上の削除ボタン制御だけでは、URLへの直接リクエストを防げない。モデル側でも削除を拒否することが重要だった。

## 実装中につまずいた点

### 編集フォームの送信先

新規登録用URLを明示すると、編集時もIDなしのURLへ`PATCH`されてしまった。

```erb
<%# 問題があった指定 %>
<%= form_with model: category, url: admin_categories_path %>
```

名前空間を含むモデルを渡すことで、Railsが新規・編集に応じた送信先を判定できる。

```erb
<%= form_with model: [:admin, category] %>
```

- 新規: `POST /admin/categories`
- 編集: `PATCH /admin/categories/:id`

### `group.count`の戻り値

次の集計結果は数値ではなく、カテゴリIDをキーにしたHashになる。

```ruby
Inquiry.group(:category_id).count
# => { 1 => 3, 2 => 5 }
```

したがって、Hash自体に`zero?`は呼べない。カテゴリIDで件数を取り出し、該当データがない場合は`0`として扱う必要がある。

```ruby
@inquiry_counts[category.id].to_i.zero?
```

メソッド名と戻り値の意味も一致させる必要がある。例えば「両方0件ならtrue」という判定なら、`category_used?`より`category_unused?`の方が意図を正確に表せる。

### 検索・並び替え・ページネーションの適用順

Relationを一つずつ組み立てると整理しやすかった。

```ruby
categories = Category.search_keyword(params[:q])
categories = categories.latest # 選択された並び順を適用
@categories = categories.page(params[:page])
```

基本の順序は次のとおり。

1. 検索で対象を絞る
2. 並び順を決める
3. 最後にページネーションする

`page`を途中で複数回呼んだり、最後に無条件の`order`を追加したりすると、どの並び順が有効なのか分かりにくくなる。

### GETパラメータによる状態の引き継ぎ

検索条件と並び順は、ActiveRecordが自動的に画面間で保持するものではない。URLに必要なGETパラメータを残す必要がある。

```text
/admin/categories?q=general&sort=latest&page=2
```

並び替えリンクでは検索条件を渡す。

```erb
<%= link_to "新しい順",
    admin_categories_path(q: params[:q], sort: "latest") %>
```

検索フォームでは現在の並び順をhidden fieldで渡す。

```erb
<%= form.hidden_field :sort, value: params[:sort] if params[:sort].present? %>
```

並び順は任意のカラム名をSQLへ渡さず、`case`などの許可リストで処理する。

## テストで学んだこと

### DBの取得順ではなく、画面の表示順を調べる

コントローラへGETしても、DB内のレコード順が変更されるわけではない。GET後に`Category.pluck(:name)`を実行しても、画面の表示順は検証できない。

表示順はレスポンスHTMLから取得する。

```ruby
displayed_names =
  css_select(".category-card h2").map { |element| element.text.strip }

assert_equal expected_names, displayed_names
```

### scopeはモデルテストで直接確認する

scope自体の並び順は、モデルテストで`pluck`した配列を比較する。

```ruby
assert_equal(
  %w[used_by_knowledge unused special general],
  Category.latest.pluck(:name)
)
```

`assert_equal`は配列の要素だけでなく順番も比較する。日時順のテストでは、fixtureの`created_at`を重複させないことも重要だった。

### ページネーションはページサイズを超えるデータが必要

1ページ10件の場合、10件ではページネーションは表示されない。最低11件を用意する必要がある。

また、POST直後のレスポンスはリダイレクトなので、一覧HTMLを調べる前にGETする。

最低限の検証は次の3点とした。

- ページネーションUIが表示される
- 1ページ目に10件表示される
- 2ページ目に残り1件表示される

### 権限は直接リクエストで確認する

管理者向けリンクが非表示でも、直接URLへアクセスできる可能性がある。GETだけでなく、POST・PATCH・DELETEについても非管理者が実行できないことを確認した。

## テスト結果

カテゴリ関連:

```text
25 runs, 68 assertions
0 failures, 0 errors
```

全体:

```text
90 runs, 270 assertions
0 failures, 0 errors
```

テスト実行環境によっては、Windowsの絶対パス列挙の制約により、実在するビューやfixtureを一時的に検出できないことがあった。`MissingTemplate`が出た場合は、ファイルの有無だけでなく、実行環境やパス解決も切り分ける必要がある。

## 今後の小さな改善候補

- `category_used?`の名前と戻り値の意味を一致させる
- 未ログインユーザーとmanagerの権限テストを追加する
- `:unprocessable_entity`の非推奨警告への対応を確認する
- ブラウザ操作によるカテゴリCRUDのE2Eテストを追加する
- 作成日時が同一の場合も表示順が安定するよう、必要ならIDを第2ソート条件にする

## 次回使えるチェックリスト

- 管理画面は名前空間と共通の認可基盤を使っているか
- 画面上の制御だけでなく、モデルとコントローラでも操作を制限しているか
- `form_with`は名前空間を含む正しいルートを生成しているか
- 集計結果の型が数値かHashかを確認したか
- 検索・並び替え・ページ番号をGETパラメータで引き継いでいるか
- Relationは検索、並び替え、ページネーションの順に構築しているか
- 表示順テストではレスポンスHTMLの順番を確認しているか
- ページネーションテストでは1ページの件数を超えるデータを用意したか
- 非管理者による直接のPOST・PATCH・DELETEをテストしたか
- 対象テストだけでなく全体テストも実行したか
