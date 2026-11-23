require "json"
require "net/http"
require "openssl"
require "uri"

module Edify
  # A thin client for Edify's JSON API (`/api/v1`). It sends the token as a Bearer header and turns the API's
  # `{ "error": { "code", "message" } }` responses, and network failures, into Client::Error. It holds no business
  # logic: what a command shows is exactly what the API returned.
  class Client
    class Error < StandardError
      attr_reader :code

      def initialize(message, code:)
        super(message)
        @code = code
      end
    end

    # Plain HTTP would send the token in the clear, so it is allowed only to the local machine.
    LOCAL_HOSTS = %w[localhost 127.0.0.1 ::1 [::1]].freeze

    attr_reader :base_url

    def initialize(url:, token:)
      @base_url = url.to_s.strip.chomp("/")
      @token = token
      check_url!
    end

    # @param path [String] relative to /api/v1, e.g. "speakers/stale"
    # @param params [Hash] query parameters; nil values are left out
    # @return [Hash] the parsed JSON body of a successful response
    # @raise [Error] for an error response or a network failure
    def get(path, params = {})
      uri = URI("#{base_url}/api/v1/#{path}")
      query = params.compact
      uri.query = URI.encode_www_form(query) unless query.empty?
      handle(perform(uri))
    end

    private

    attr_reader :token

    def check_url!
      uri = URI(base_url)
      raise Error.new("#{base_url} is not a valid Edify URL.", code: "invalid_url") unless uri.host
      return if uri.scheme == "https" || (uri.scheme == "http" && LOCAL_HOSTS.include?(uri.host))

      raise Error.new("Use an https:// URL. Plain http is allowed only for localhost, so the token is never " \
                      "sent unencrypted.", code: "insecure_url")
    rescue URI::InvalidURIError
      raise Error.new("#{base_url} is not a valid Edify URL.", code: "invalid_url")
    end

    def perform(uri)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Accept"] = "application/json"
      request["User-Agent"] = "edify-cli/#{VERSION}"

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.request(request)
      end
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      raise Error.new("Could not reach #{base_url}: #{e.message}", code: "connection_failed")
    end

    def handle(response)
      body = parse(response)
      return body if response.is_a?(Net::HTTPSuccess) && body

      error = body.is_a?(Hash) ? body["error"] : nil
      raise Error.new(error["message"], code: error["code"]) if error.is_a?(Hash) && error["message"]

      raise Error.new("Edify answered HTTP #{response.code} without an API error. Is #{base_url} an Edify server?",
                      code: "http_#{response.code}")
    end

    def parse(response)
      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      nil
    end
  end
end
