# mf_invoice_creator

## 使い方

- MFクラウドのアプリポータルへ登録する
  - https://developers.biz.moneyforward.com/docs/tutorial/step-1
- .env.sampleをコピーして.envを作成し、各種環境変数をセットする
- patterns/sample.rbを複製し、patterns/以下に請求パターンごとのスクリプトを作成する
  - `cp patterns/sample.rb patterns/company_a.rb`
- 複製したスクリプト内の変数を編集する
- 初期認証を行う
  - `bundle exec ruby initial_auth.rb`
- スクリプトを実行する
  - `bundle exec ruby patterns/company_a.rb`
