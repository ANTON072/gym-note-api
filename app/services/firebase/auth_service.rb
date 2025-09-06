require "jwt"
require "net/http"
require "json"

module Firebase
  class AuthService
    # Firebase公開鍵のURL
    PUBLIC_KEYS_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

    # トークンの発行者
    ISSUER_PREFIX = "https://securetoken.google.com/"

    # キャッシュの有効期限（秒）
    CACHE_EXPIRY = 3600 # 1時間

    class << self
      def verify_id_token(token, project_id)
        raise ArgumentError, "Token is required" if token.nil? || token.empty?
        raise ArgumentError, "Project ID is required" if project_id.nil? || project_id.empty?

        # トークンのデコード（検証なし）でヘッダーを取得
        header = JWT.decode(token, nil, false).last
        kid = header["kid"]

        # Firebase Emulator使用時かつ署名なしトークンの場合
        if using_emulator? && header["alg"] == "none"
          return verify_emulator_token(token, project_id)
        end

        # 公開鍵を取得
        public_keys = fetch_public_keys
        public_key = public_keys[kid]

        raise JWT::VerificationError, "No matching public key found" unless public_key

        # トークンを検証
        options = {
          algorithm: "RS256",
          verify_iss: true,
          iss: "#{ISSUER_PREFIX}#{project_id}",
          verify_aud: true,
          aud: project_id,
          verify_iat: true,
          verify_exp: true
        }

        payload, _ = JWT.decode(token, public_key, true, options)

        # 追加の検証
        validate_auth_time(payload)
        validate_subject(payload)

        payload
      rescue JWT::DecodeError => e
        raise JWT::VerificationError, "Invalid token: #{e.message}"
      end

      private

      def fetch_public_keys
        # TODO: 本番環境ではRedisなどでキャッシュすることを推奨
        @public_keys_cache ||= {}
        @cache_expires_at ||= Time.now

        if @cache_expires_at > Time.now && !@public_keys_cache.empty?
          return @public_keys_cache
        end

        uri = URI(PUBLIC_KEYS_URL)
        response = Net::HTTP.get_response(uri)

        unless response.is_a?(Net::HTTPSuccess)
          raise "Failed to fetch public keys: #{response.code} #{response.message}"
        end

        keys_data = JSON.parse(response.body)

        @public_keys_cache = keys_data.transform_values do |cert_string|
          OpenSSL::X509::Certificate.new(cert_string).public_key
        end

        # Cache-Controlヘッダーから有効期限を取得
        cache_control = response["cache-control"]
        max_age = cache_control&.match(/max-age=(\d+)/)&.captures&.first&.to_i || CACHE_EXPIRY
        @cache_expires_at = Time.now + max_age

        @public_keys_cache
      end

      def validate_auth_time(payload)
        # auth_timeが存在し、過去の時刻であることを確認
        auth_time = payload["auth_time"]
        if auth_time.nil? || auth_time > Time.now.to_i
          raise JWT::VerificationError, "Invalid auth_time"
        end
      end

      def validate_subject(payload)
        # subjectが存在し、空でないことを確認
        subject = payload["sub"]
        if subject.nil? || subject.empty?
          raise JWT::VerificationError, "Invalid subject"
        end
      end

      def using_emulator?
        ActiveModel::Type::Boolean.new.cast(ENV["USE_FIREBASE_EMULATOR"])
      end

      def verify_emulator_token(token, project_id)
        # 署名検証なしでデコード
        payload, _ = JWT.decode(token, nil, false)

        # 手動で検証を実施
        now = Time.now.to_i

        # 発行者の確認
        expected_issuer = "#{ISSUER_PREFIX}#{project_id}"
        unless payload["iss"] == expected_issuer
          raise JWT::VerificationError, "Invalid issuer. Expected #{expected_issuer}, got #{payload["iss"]}"
        end

        # 対象者の確認
        unless payload["aud"] == project_id
          raise JWT::VerificationError, "Invalid audience. Expected #{project_id}, got #{payload["aud"]}"
        end

        # 有効期限の確認
        if payload["exp"] && payload["exp"] < now
          raise JWT::VerificationError, "Token has expired"
        end

        # 発行時刻の確認
        if payload["iat"] && payload["iat"] > now
          raise JWT::VerificationError, "Invalid issued at time"
        end

        # 追加の検証
        validate_auth_time(payload)
        validate_subject(payload)

        Rails.logger.info "Firebase Emulator token verified for user: #{payload["sub"]}"

        payload
      end
    end
  end
end
