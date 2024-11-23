# invoice_creator_class.rb

require 'httparty'
require 'json'
require 'fileutils'
require_relative 'token_manager'

class InvoiceCreator
  API_URL = 'https://invoice.moneyforward.com/api/v3/invoice_template_billings'.freeze

  def initialize
    token_manager = TokenManager.new
    @access_token = token_manager.access_token
  end

  # 請求書を作成するメソッド
  # params: Hash - 請求書作成に必要なパラメータ
  def create_invoice(params)
    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "Bearer #{@access_token}"
    }

    response = HTTParty.post(API_URL, headers: headers, body: params.to_json)

    if response.success?
      invoice = JSON.parse(response.body)
      invoice_id = invoice['id']
      puts "請求書が正常に作成されました。請求書ID: #{invoice_id}"
      invoice
    else
      puts "エラーが発生しました。ステータスコード: #{response.code}"
      puts "メッセージ: #{response.body}"
      nil
    end
  rescue StandardError => e
    puts "例外が発生しました: #{e.message}"
    nil
  end

  # 請求書のPDFをダウンロードするメソッド
  # pdf_url: String - PDFのURL
  # pdf_path: String - 保存先のパス
  def download_pdf(pdf_url, pdf_path)
    headers = {
      "Authorization" => "Bearer #{@access_token}"
    }
    pdf_url = "#{pdf_url}"

    response = HTTParty.get(pdf_url, headers: headers)

    if response.success?
      pdf_data = response.body
      FileUtils.mkdir_p(File.dirname(pdf_path))
      File.open(pdf_path, 'wb') do |file|
        file.write(pdf_data)
      end
      puts "請求書PDFが保存されました: #{pdf_path}"
    else
      puts "PDFのダウンロードに失敗しました。ステータスコード: #{response.code}"
      puts "メッセージ: #{response.body}"
    end
  rescue StandardError => e
    puts "例外が発生しました: #{e.message}"
  end

  def update_to_before_billing(billing_id)
    url = "https://invoice.moneyforward.com/api/v3/billings/#{billing_id}/payment_status".freeze

    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{@access_token}"
    }
    response = HTTParty.put(url, headers: headers, body: { payment_status: '1' }.to_json)
    if response.success?
      puts 'ステータスが未入金に変更されました'
    else
      puts "ステータス更新に失敗しました。ステータスコード: #{response.code}"
      puts "メッセージ: #{response.body}"
    end
  rescue StandardError => e
    puts "例外が発生しました: #{e.message}"
  end
end