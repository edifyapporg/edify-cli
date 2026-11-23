RSpec.describe Edify::CLI do
  let(:url) { "https://edify.example.org" }
  let(:token) { "edify_secret_token_value" }
  let(:check) { "#{url}/api/v1/speakers/stale?limit=1" }
  let(:config) { Edify::Config.new }

  def api_error(status, code, message = "The #{code} message.")
    { status: status, body: { error: { code: code, message: message } }.to_json }
  end

  describe "status" do
    context "with a saved login the server accepts" do
      before do
        config.save(url: url, token: token)
        stub_request(:get, check).with(headers: { "Authorization" => "Bearer #{token}" })
                                 .to_return(status: 200, body: '{"speakers":[]}')
      end

      it "shows the server, where the token comes from, and that it is accepted" do
        out, err, status = run_cli("status")

        expect([status, err]).to eq([0, ""])
        expect(out).to eq(<<~TEXT)
          Server: #{url} (from the saved login)
          Token:  from #{config.path}, saved #{File.mtime(config.path).strftime('%Y-%m-%d')}
          Check:  accepted
        TEXT
      end

      it "never prints the token" do
        out, err, _status = run_cli("status")
        expect(out + err).not_to include(token)
      end
    end

    it "reports a valid token whose role cannot list speakers as accepted" do
      config.save(url: url, token: token)
      stub_request(:get, check).to_return(api_error(403, "forbidden"))

      out, _err, status = run_cli("status")

      expect(status).to eq(0)
      expect(out).to include("Check:  accepted, though your role cannot list speakers")
    end

    it "reports a rejected token with the server's message and exits 1" do
      config.save(url: url, token: token)
      stub_request(:get, check).to_return(api_error(401, "invalid_token", "Send a valid API token."))

      out, _err, status = run_cli("status")

      expect(status).to eq(1)
      expect(out).to include("Check:  not accepted. Send a valid API token.")
      expect(out).not_to include(token)
    end

    it "uses EDIFY_URL and EDIFY_TOKEN and says so" do
      ENV["EDIFY_URL"] = "https://other.example.org"
      ENV["EDIFY_TOKEN"] = token
      stub_request(:get, "https://other.example.org/api/v1/speakers/stale?limit=1")
        .to_return(status: 200, body: '{"speakers":[]}')

      out, _err, status = run_cli("status")

      expect(status).to eq(0)
      expect(out).to start_with("Server: https://other.example.org (from EDIFY_URL)\nToken:  from EDIFY_TOKEN\n")
    end

    it "says when there is no token, with the default server, and exits 1 without calling the API" do
      out, _err, status = run_cli("status")

      expect(status).to eq(1)
      expect(out).to eq(<<~TEXT)
        Server: #{Edify::Config::DEFAULT_URL} (the default)
        Token:  none. Run `edify login`, or set EDIFY_TOKEN.
      TEXT
      expect(a_request(:any, //)).not_to have_been_made
    end
  end

  describe "logout" do
    it "removes the saved login and reminds you to revoke the token" do
      config.save(url: url, token: token)

      out, _err, status = run_cli("logout")

      expect(status).to eq(0)
      expect(File.exist?(config.path)).to be(false)
      expect(out).to eq(<<~TEXT)
        Logged out. Removed #{config.path}.
        The token still works until you revoke it in Edify under Settings > API Tokens.
      TEXT
    end

    it "says when there is nothing to remove" do
      out, _err, status = run_cli("logout")

      expect(status).to eq(0)
      expect(out).to eq("No saved login to remove (#{config.path}).\n")
    end

    it "warns that EDIFY_TOKEN still applies" do
      config.save(url: url, token: token)
      ENV["EDIFY_TOKEN"] = "edify_env"

      out, _err, _status = run_cli("logout")

      expect(out).to include("EDIFY_TOKEN is still set in this environment, so commands keep using it.")
    end
  end
end
