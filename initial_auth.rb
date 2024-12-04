require 'httparty'
require 'json'
require 'dotenv/load'
require 'fileutils'
require 'base64'
require 'digest'

class InitialAuth
  def initialize
    @token_endpoint = ENV['TOKEN_ENDPOINT']
    @client_id = ENV['CLIENT_ID']
    @client_secret = ENV['CLIENT_SECRET']
    @authorization_endpoint = ENV['AUTHORIZATION_ENDPOINT']
    @redirect_uri = ENV['REDIRECT_URI']
    @scope = ENV['SCOPE']
    @code_verifier = ENV['CODE_VERIFIER']
    if @token_endpoint.nil? || @token_endpoint.empty? ||
      @client_id.nil? || @client_id.empty? ||
      @client_secret.nil? || @client_secret.empty? ||
      @redirect_uri.nil? || @redirect_uri.empty? ||
      @authorization_endpoint.nil? || @authorization_endpoint.empty?
      puts "Error: TOKEN_ENDPOINT, CLIENT_ID, CLIENT_SECRET, AUTHORIZATION_ENDPOINT, SCOPE, CODE_VERIFIER, and REDIRECT_URI must be set in .env"
      exit 1
    end
  end

  def get_authorization_code
    code_verifier = ENV['CODE_VERIFIER']
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub('=', '')
    authorization_url = "#{@authorization_endpoint}?" +
      "response_type=code&" +
      "client_id=#{@client_id}&" +
      "redirect_uri=#{@redirect_uri}&" +
      "scope=#{@scope}&" +
      "state=#{SecureRandom.hex(5)}&" +
      "code_challenge=#{code_challenge}&" +
      "code_challenge_method=S256"

    # 認証コードを取得
    puts "以下のURLにアクセスして連携を許可してください。"
    puts authorization_url
    print "許可後にリダイレクトされたページのURLを貼り付けてください。"
    print "リダイレクトURL: "
    @authorization_code = Hash[URI::decode_www_form(URI.parse(gets.chomp).query)]['code']
  end

  def save_token
    # Basic認証ヘッダーの作成
    basic_auth = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    response = HTTParty.post(@token_endpoint, {
      body: {
        grant_type: 'authorization_code',
        code: @authorization_code,
        redirect_uri: @redirect_uri,
        code_verifier: @code_verifier
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
      return tokens
    else
      puts "認証に失敗しました。ステータスコード: #{response.code}"
      puts "メッセージ: #{response.body}"
    end
  rescue StandardError => e
    puts "例外が発生しました: #{e.message}"
  end
end

