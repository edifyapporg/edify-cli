RSpec.describe Edify::CLI do
  let(:url) { "https://edify.example.org" }
  let(:check) { "#{url}/api/v1/speakers/stale?limit=1" }
  let(:config) { Edify::Config.new }

  def api_error(status, code)
    { status: status, body: { error: { code: code, message: "The #{code} message." } }.to_json }
  end

  describe "login" do
    it "checks the token and saves it" do
      stub_request(:get, check).with(headers: { "Authorization" => "Bearer edify_good" })
                               .to_return(status: 200, body: '{"speakers":[]}')

      out, err, status = run_cli("login", "--url", "#{url}/", "--token", "edify_good")

      expect([status, err]).to eq([0, ""])
      expect(out).to include("Logged in to #{url}.")
      expect([config.url, config.token]).to eq([url, "edify_good"])
    end

    it "asks for the URL when it is not given" do
      stub_request(:get, check).to_return(status: 200, body: '{"speakers":[]}')

      _out, _err, status = run_cli("login", "--token", "edify_good", stdin: "#{url}\n")

      expect(status).to eq(0)
      expect(config.url).to eq(url)
    end

    it "uses the production server when the URL prompt is left blank" do
      stub_request(:get, "#{Edify::Config::DEFAULT_URL}/api/v1/speakers/stale?limit=1")
        .to_return(status: 200, body: '{"speakers":[]}')

      out, _err, status = run_cli("login", "--token", "edify_good", stdin: "\n")

      expect(status).to eq(0)
      expect(out).to include("(#{Edify::Config::DEFAULT_URL})", "Logged in to #{Edify::Config::DEFAULT_URL}.")
      expect(config.url).to eq(Edify::Config::DEFAULT_URL)
    end

    it "saves a valid token even when its role cannot list speakers" do
      stub_request(:get, check).to_return(api_error(403, "forbidden"))

      _out, _err, status = run_cli("login", "--url", url, "--token", "edify_music")

      expect(status).to eq(0)
      expect(config.token).to eq("edify_music")
    end

    %w[invalid_token no_unit insufficient_scope].each do |code|
      it "refuses a token the server answers with #{code}, and saves nothing" do
        stub_request(:get, check).to_return(api_error(code == "invalid_token" ? 401 : 403, code))

        _out, err, status = run_cli("login", "--url", url, "--token", "edify_bad")

        expect(status).to eq(1)
        expect(err).to include("The #{code} message.")
        expect(config).not_to be_configured
      end
    end

    it "refuses plain http to another machine without contacting it" do
      _out, err, status = run_cli("login", "--url", "http://edify.example.org", "--token", "edify_good")

      expect(status).to eq(1)
      expect(err).to include("Use an https:// URL")
      expect(config).not_to be_configured
    end
  end

  describe "version" do
    it "prints the version" do
      out, _err, status = run_cli("version")
      expect([out.strip, status]).to eq([Edify::VERSION, 0])
    end
  end
end
