# token_manager.rb

require 'httparty'
require 'json'
require 'dotenv/load'
require 'fileutils'
require 'base64'

require 'pry'

class TokenManager
  TOKEN_FILE = 'tokens.json'.freeze

  def initialize
    @client_id = ENV['CLIENT_ID'].freeze
    @client_secret = ENV['CLIENT_SECRET'].freeze
    @token_endpoint = ENV['TOKEN_ENDPOINT'].freeze
    raise "CLIENT_ID is not set in .env" if @client_id.nil? || @client_id.empty?
    raise "CLIENT_SECRET is not set in .env" if @client_secret.nil? || @client_secret.empty?

    load_tokens
  end

  # アクセストークンを取得（必要に応じて更新）
  def access_token
    if access_token_expired?
      refresh_access_token
    else
      @tokens['access_token']
    end
  end

  private

  # トークンファイルを読み込む
  def load_tokens
    if File.exist?(TOKEN_FILE)
      file_content = File.read(TOKEN_FILE)
      @tokens = JSON.parse(file_content)
      p @tokens
    else
      @tokens = { 'access_token' => '', 'refresh_token' => '', 'expires_at' => 0 }
      save_tokens
    end
  end

  # トークンファイルを保存する
  def save_tokens
    File.open(TOKEN_FILE, 'w') do |file|
      file.write(JSON.pretty_generate(@tokens))
    end
  end

  # アクセストークンが期限切れかどうかを確認する
  def access_token_expired?
    current_time = Time.now.to_i
    @tokens['access_token'].nil? || @tokens['access_token'].empty? || current_time >= @tokens['expires_at'].to_i
  end

  # リフレッシュトークンを使用してアクセストークンを更新する
  def refresh_access_token
    if @tokens['refresh_token'].nil? || @tokens['refresh_token'].empty?
      raise "Refresh token is missing. Please authenticate first."
    end

    body = {
      grant_type: 'refresh_token',
      redirect_uri: ENV['REDIRECT_URI'],
      refresh_token: @tokens['refresh_token'],
      code_verifier: ENV['CODE_VERIFIER']
    }
    response = HTTParty.post(@token_endpoint, {
      body:,
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Authorization' => "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
      }
    })

    if response.success?
      data = JSON.parse(response.body)
      @tokens['access_token'] = data['access_token']
      @tokens['refresh_token'] = data['refresh_token'] # 新しいリフレッシュトークンに更新
      @tokens['expires_at'] = Time.now.to_i + data['expires_in'].to_i
      save_tokens
      puts "アクセストークンが更新されました。"
      @tokens['access_token']
    else
      puts "アクセストークンの更新に失敗しました。ステータスコード: #{response.code}"
      puts "メッセージ: #{response.body}"
      raise "Failed to refresh access token."
    end
  end
end
