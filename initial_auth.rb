# initial_auth.rb

#!/usr/bin/env ruby

require 'httparty'
require 'json'
require 'dotenv/load'
require 'fileutils'
require 'base64'

class InitialAuth
  def initialize
    @token_endpoint = ENV['TOKEN_ENDPOINT']
    @client_id = ENV['CLIENT_ID']
    @client_secret = ENV['CLIENT_SECRET']
    @authorization_code = ENV['AUTHORIZATION_CODE'] # 初回の認証コード
    @redirect_uri = ENV['REDIRECT_URI'] # 必要に応じて設定

    if @token_endpoint.nil? || @token_endpoint.empty? ||
      @client_id.nil? || @client_id.empty? ||
      @client_secret.nil? || @client_secret.empty? ||
      @authorization_code.nil? || @authorization_code.empty? ||
      @redirect_uri.nil? || @redirect_uri.empty?
      puts "Error: TOKEN_ENDPOINT, CLIENT_ID, CLIENT_SECRET, AUTHORIZATION_CODE, and REDIRECT_URI must be set in .env"
      exit 1
    end
  end

  def authenticate
    # Basic認証ヘッダーの作成
    basic_auth = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    response = HTTParty.post(@token_endpoint, {
      body: {
        grant_type: 'authorization_code',
        code: @authorization_code,
        redirect_uri: @redirect_uri
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Authorization' => "Basic #{basic_auth}"
      }
    })

    if response.success?
      data = JSON.parse(response.body)
      tokens = {
        'access_token' => data['access_token'],
        'refresh_token' => data['refresh_token'],
        'expires_at' => Time.now.to_i + data['expires_in'].to_i
      }
      File.open('tokens.json', 'w') do |file|
        file.write(JSON.pretty_generate(tokens))
      end
      puts "認証に成功しました。tokens.jsonを更新しました。"
    else
      puts "認証に失敗しました。ステータスコード: #{response.code}"
      puts "メッセージ: #{response.body}"
    end
  rescue StandardError => e
    puts "例外が発生しました: #{e.message}"
  end
end

auth = InitialAuth.new
auth.authenticate
