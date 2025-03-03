require 'dotenv/load'
require 'httparty'

class ChatworkUploader
  include HTTParty
  base_uri 'https://api.chatwork.com/v2'
  
  def initialize
    @api_key = ENV['CHATWORK_API_KEY']
    raise 'CHATWORK_API_KEY is not set' unless @api_key
    
    # HTTPartyのデフォルトヘッダーを設定
    self.class.headers 'X-ChatWorkToken' => @api_key
  end
  
  def call(room_id:, file_path:, message: nil)
    raise "File not found: #{file_path}" unless File.exist?(file_path)

    # マルチパートフォームデータの準備
    form_data = {
      multipart: true,
      file: File.open(file_path)
    }
    
    # メッセージが指定されている場合は追加
    form_data[:message] = message if message

    # POSTリクエストの実行
    response = self.class.post("/rooms/#{room_id}/files", body: form_data)
    
    unless response.success?
      raise "Failed to upload file: #{response.body}"
    end
    
    puts 'Chatworkにファイルが投稿されました'
    response
  end
end