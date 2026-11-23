require "json"

module Edify
  module Commands
    # Shared by every command class: reading the saved login, calling the API, and printing JSON. Errors become
    # Thor::Error, which Thor prints to stderr before exiting with status 1.
    module Helpers
      NOT_LOGGED_IN = "Not logged in. Run `edify login`, or set EDIFY_URL and EDIFY_TOKEN.".freeze
      RELOGIN_HINT = "Your token may have been revoked or expired. Create a new one in Edify under " \
                     "Settings > API Tokens, then run `edify login`.".freeze

      private

      def config
        @config ||= Config.new
      end

      def client
        raise Thor::Error, NOT_LOGGED_IN unless config.configured?

        @client ||= Client.new(url: config.url, token: config.token)
      rescue Client::Error => e
        raise Thor::Error, e.message
      end

      # @return [Hash] the API's response body
      def api_get(path, params = {})
        client.get(path, params)
      rescue Client::Error => e
        raise Thor::Error, e.code == "invalid_token" ? "#{e.message}\n#{RELOGIN_HINT}" : e.message
      end

      def print_json(body)
        say JSON.pretty_generate(body)
      end
    end
  end
end
