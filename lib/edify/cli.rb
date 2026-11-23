require "thor"

require_relative "version"
require_relative "config"
require_relative "client"

module Edify
  # The `edify` command. Every command reads from the Edify API with a personal access token, created in Edify under
  # Settings > API Tokens, and only formats what the API returns.
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "Show the edify-cli version"
    def version
      say VERSION
    end
  end
end
