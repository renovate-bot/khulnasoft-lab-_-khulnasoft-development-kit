# frozen_string_literal: true

module KDK
  # ConfigRedactor provides functionality to securely redact sensitive
  # information from configuration data.  It processes YAML-compatible Hash
  # structures and masks values based on key patterns and value content.
  #
  # The redactor identifies sensitive data through:
  # 1. Key pattern matching (e.g. keys ending in _secret, _token) case-insensitive
  # 2. Value pattern matching (e.g. KhulnaSoft/GitHub tokens, UUIDs)
  # 3. Explicit allowlist exceptions
  #
  # @example Basic usage with a hash
  #   config = {
  #     'api_token' => 'secret123',
  #     'public_url' => 'http://example.com'
  #   }
  #   redacted = KDK::ConfigRedactor.redact(config)
  #   redacted['api_token'] # => "[redacted]"
  #   redacted['public_url'] # => "http://example.com"
  #
  # @example Handling nested structures
  #   nested_config = {
  #     'credentials' => {
  #       'khulnasoft_token' => 'glpat-abc123',
  #       'github_key' => 'gh_xyz789'
  #     }
  #   }
  #   redacted = KDK::ConfigRedactor.redact(nested_config)
  #   # Results in:
  #   # {
  #   #   'credentials' => {
  #   #     'khulnasoft_token' => '[redacted]',
  #   #     'github_key' => '[redacted]'
  #   #   }
  #   # }
  class ConfigRedactor
    # Block the config keys. String or Regexp.
    BLOCK_KEYS = [
      # Inspired by Rails' filter_parameters
      /_key$/i,
      /_pass(?:word)?$/i,
      /_secret$/i,
      /token$/i
    ].freeze

    # Explicitly allow the config keys. String or Regexp.
    ALLOW_KEYS = %w[
      cookie_key
      version
    ].freeze

    # Block the config values. String or Regexp.
    BLOCK_VALUES = [
      # https://docs.gitlab.com/security/tokens/#token-prefixes
      /^gl\w+-/,
      # https://github.blog/engineering/platform-security/behind-githubs-new-authentication-token-formats/#identifiable-prefixes
      /^gh\w_/,
      # Hex hashes
      /^\h{8,}+$/,
      # UUIDs
      /^\h+-([\h-]+)$/
    ].freeze

    REDACT_WITH = '[redacted]'
    HOME_REDACT_WITH = '$HOME'

    def self.redact(yaml)
      new.redact(yaml)
    end

    def redact(yaml, redacted = {})
      yaml.each do |key, value|
        redact_kv!(key, value, redacted)
      end

      redacted
    end

    def redact_logfile(content)
      content.gsub(Dir.home, '$HOME')
    end

    private

    def redact_kv!(key, value, redacted)
      new_value =
        case value
        when Hash
          value.each { |k, v| redact_kv!(k, v, value) }
        when Array
          value.each.with_index { |v, i| redact_kv!(i, v, value) }
        else
          redact_single!(key, value)
        end

      redacted[key] = new_value
    end

    def redact_single!(key, value)
      if value.is_a?(String)
        return REDACT_WITH if redact?(key, value)

        value.gsub(Dir.home, HOME_REDACT_WITH)
      else
        value
      end
    end

    def redact?(key, value)
      return false if value.empty?

      key = key.to_s

      (ALLOW_KEYS.none? { |allow| allow === key } &&
        BLOCK_KEYS.any? { |block| block === key }) ||
        BLOCK_VALUES.any? { |block| block === value }
    end
  end
end
