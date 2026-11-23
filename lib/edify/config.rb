require "fileutils"
require "yaml"

module Edify
  # The server URL and API token the CLI uses. They are saved by `edify login` to
  # $XDG_CONFIG_HOME/edify/config.yml (normally ~/.config/edify/config.yml) in a directory only the owner can enter
  # and a file only the owner can read, since the token can read the user's ward data. The EDIFY_URL and EDIFY_TOKEN
  # environment variables take precedence over the file, for scripts and coding agents. With no URL from either, the
  # CLI uses the production Edify server.
  class Config
    # The www host, because the bare domain redirects to it and the client does not follow redirects.
    DEFAULT_URL = "https://www.edifyapp.org".freeze

    # @param env [Hash] the environment, ENV by default
    # @return [String]
    def self.default_path(env = ENV)
      base = env["XDG_CONFIG_HOME"].to_s.empty? ? File.join(Dir.home, ".config") : env["XDG_CONFIG_HOME"]
      File.join(base, "edify", "config.yml")
    end

    attr_reader :path

    def initialize(path: nil, env: ENV)
      @env = env
      @path = path || self.class.default_path(env)
    end

    # @return [String]
    def url
      present(env["EDIFY_URL"]) || stored["url"] || DEFAULT_URL
    end

    # @return [String, nil]
    def token
      present(env["EDIFY_TOKEN"]) || stored["token"]
    end

    # A URL always has a value, so a token is all a login needs.
    def configured?
      !token.nil?
    end

    # @return [Symbol] :env (EDIFY_URL), :saved (the saved login) or :default
    def url_source
      return :env if present(env["EDIFY_URL"])

      stored["url"] ? :saved : :default
    end

    # @return [Symbol, nil] :env (EDIFY_TOKEN), :saved (the saved login), or nil when there is no token
    def token_source
      return :env if present(env["EDIFY_TOKEN"])

      :saved if stored["token"]
    end

    def saved?
      File.exist?(path)
    end

    # @return [Time, nil] when the login was last saved
    def saved_at
      File.mtime(path) if saved?
    end

    # Removes the saved login. EDIFY_URL and EDIFY_TOKEN are untouched.
    # @return [Boolean] whether there was a saved login to remove
    def delete
      return false unless saved?

      File.delete(path)
      @stored = nil
      true
    end

    # Writes the URL and token, creating the file with owner-only permissions and tightening them if it already
    # existed with looser ones.
    def save(url:, token:)
      directory = File.dirname(path)
      FileUtils.mkdir_p(directory, mode: 0o700)
      File.chmod(0o700, directory)
      File.open(path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
        file.write(YAML.dump("url" => url, "token" => token))
      end
      File.chmod(0o600, path)
      @stored = nil
    end

    private

    attr_reader :env

    def stored
      @stored ||= File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
    end

    def present(value)
      value unless value.to_s.strip.empty?
    end
  end
end
