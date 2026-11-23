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

    desc "logout", "Remove the saved login"
    long_desc <<~DESC
      Deletes the login saved by `edify login`. The token itself keeps working until you revoke it in Edify under
      Settings > API Tokens. An EDIFY_TOKEN set in your environment is not affected.
    DESC
    def logout
      if config.delete
        say "Logged out. Removed #{config.path}."
        say "The token still works until you revoke it in Edify under Settings > API Tokens."
      else
        say "No saved login to remove (#{config.path})."
      end
      say "EDIFY_TOKEN is still set in this environment, so commands keep using it." if config.token_source == :env
    end

    desc "status", "Show which server and token the CLI uses, and whether the server accepts the token"
    long_desc <<~DESC
      Shows the Edify server the CLI talks to and where that comes from, where its token comes from (never the token
      itself), and whether the server accepts the token. Exits 0 when it does and 1 otherwise.
    DESC
    def status
      say "Server: #{config.url} (#{URL_SOURCES.fetch(config.url_source)})"
      return not_logged_in_status unless config.configured?

      say "Token:  #{token_description}"
      result = verify_token(config.url, config.token)
      say(result == :accepted ? "Check:  accepted" : "Check:  accepted, though your role cannot list speakers")
    rescue Client::Error => e
      say "Check:  not accepted. #{e.message}"
      exit 1
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

    URL_SOURCES = { env: "from EDIFY_URL", saved: "from the saved login", default: "the default" }.freeze

    private

    def check_login(url, token)
      raise Thor::Error, "Both a URL and a token are needed." if url.empty? || token.empty?

      verify_token(url, token)
    rescue Client::Error => e
      raise Thor::Error, e.message
    end

    # The API has no "who am I" endpoint yet, so a one-row request stands in. A valid token whose role cannot see
    # speakers still counts, since it may be meant for other commands.
    # @return [Symbol] :accepted, or :accepted_without_speakers
    # @raise [Client::Error] when the server refuses the token or cannot be reached
    def verify_token(url, token)
      Client.new(url: url, token: token).get("speakers/stale", limit: 1)
      :accepted
    rescue Client::Error => e
      raise unless e.code == "forbidden"

      :accepted_without_speakers
    end

    def token_description
      return "from EDIFY_TOKEN" if config.token_source == :env

      "from #{config.path}, saved #{config.saved_at.strftime('%Y-%m-%d')}"
    end

    def not_logged_in_status
      say "Token:  none. Run `edify login`, or set EDIFY_TOKEN."
      exit 1
    end
  end
end
