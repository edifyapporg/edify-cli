require "thor"

require_relative "version"
require_relative "config"
require_relative "client"
require_relative "table"
require_relative "commands/helpers"
require_relative "commands/meetings"
require_relative "commands/songs"
require_relative "commands/speakers"

module Edify
  # The `edify` command. Every command reads from the Edify API with a personal access token, created in Edify under
  # Settings > API Tokens, and only formats what the API returns.
  class CLI < Thor
    include Commands::Helpers

    def self.exit_on_failure?
      true
    end

    desc "login", "Save your Edify server URL and API token"
    long_desc <<~DESC
      Asks for your Edify server's URL (press Enter for #{Config::DEFAULT_URL}) and a personal access token (create one
      in Edify under Settings > API Tokens), checks them against the server, and saves them where only you can read
      them. Use --url and --token to skip the prompts.
    DESC
    option :url, desc: "Your Edify server (default #{Config::DEFAULT_URL})"
    option :token, desc: "A personal access token from Settings > API Tokens"
    def login
      url = options[:url] || ask("Edify URL:", default: Config::DEFAULT_URL)
      token = options[:token] || ask("API token (from Settings > API Tokens):", echo: false)
      say "" unless options[:token]

      check_login(url.to_s.strip, token.to_s.strip)
      config.save(url: url.to_s.strip.chomp("/"), token: token.to_s.strip)
      say "Logged in to #{url.to_s.strip.chomp('/')}. Saved to #{config.path}."
    end

    desc "version", "Show the edify-cli version"
    def version
      say VERSION
    end

    desc "speakers SUBCOMMAND", "Questions about speakers"
    subcommand "speakers", Commands::Speakers

    desc "songs SUBCOMMAND", "Questions about songs"
    subcommand "songs", Commands::Songs

    desc "meetings SUBCOMMAND", "Questions about meetings"
    subcommand "meetings", Commands::Meetings

    private

    # The API has no "who am I" endpoint yet, so a one-row request stands in. An invalid token is refused. A valid
    # token whose role cannot see speakers is still saved, since it may be meant for other commands.
    def check_login(url, token)
      raise Thor::Error, "Both a URL and a token are needed." if url.empty? || token.empty?

      Client.new(url: url, token: token).get("speakers/stale", limit: 1)
    rescue Client::Error => e
      raise Thor::Error, e.message unless e.code == "forbidden"
    end
  end
end
