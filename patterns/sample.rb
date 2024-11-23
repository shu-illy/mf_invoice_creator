# patterns/pattern_a.rb

#!/usr/bin/env ruby

require 'yaml'
require 'dotenv/load'
require 'optparse'
require 'date'
require_relative '../invoice_creator'

# 下記の変数の値を編集してください
# -----------------------------------
department_id = 'xxxxxxxxxx'
billing_date = Date.today.strftime('%Y-%m-%d') # 請求日（例: 今日の日付）
due_date = Date.new(Date.today.year, Date.today.month, -1).strftime('%Y-%m-%d') # 振込期限（例: 今月末）
sales_date = Date.new(Date.today.last_month, Time.now.month, -1).strftime('%Y-%m-%d') # 売上計上日（例: 先月末）
item_name = 'システム開発費用' # 品目名
item_price = 5000 # 単価
download_path = '/path/to/download.pdf' # 請求書PDFの保存先
consumption_tax_display_type = 'internal' # 内税 or 外税（'internal' or 'external'）
# -----------------------------------

# コマンドの引数でパラメータを渡したい場合は、以下のオプションを有効にしてください
# -----------------------------------
# options = {}
# OptionParser.new do |opts|
#   opts.banner = "Usage: sample.rb [options]"
#
#   opts.on("-q", "--quantity ITEM_QUANTITY", "数量") do |q|
#     options[:quantity] = q
#   end
#
#   opts.on("-h", "--help", "ヘルプ表示") do
#     puts opts
#     exit
#   end
# end.parse!

# 必須項目のチェック
# [:quantity].each do |param|
#   if options[param].nil?
#     puts "Error: #{param} is required."
#     exit 1
#   end
# end
# -----------------------------------

# InvoiceCreatorの初期化
invoice_creator = InvoiceCreator.new

# リクエストボディの構築
params = {
  department_id:,
  billing_date:,
  due_date:,
  sales_date:,
  items: [
    {
      name: item_name,
      price: item_price,
      quantity: options[:quantity],
      excise: 'ten_percent'
    }
  ],
  config: {
    consumption_tax_display_type:
  }
}

# 請求書の作成
invoice = invoice_creator.create_invoice(params)

# PDFのダウンロード
invoice_creator.download_pdf(invoice['pdf_url'], download_path)
invoice_creator.update_to_before_billing(invoice['id'])
