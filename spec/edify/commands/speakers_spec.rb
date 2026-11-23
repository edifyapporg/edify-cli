RSpec.describe Edify::Commands::Speakers do
  let(:url) { "https://edify.example.org" }
  let(:endpoint) { "#{url}/api/v1/speakers/stale" }
  let(:body) do
    {
      months: 12, group: nil, spoken_before: "2025-11-23",
      speakers: [
        { name: "Doe, Jane", gender: "female", group: "adult", last_talk_date: nil },
        { name: "Roe, Samuel", gender: "male", group: "youth", last_talk_date: "2024-06-02" },
      ]
    }
  end

  before { Edify::Config.new.save(url: url, token: "edify_good") }

  describe "speakers stale" do
    it "prints a table of the API's answer" do
      stub_request(:get, endpoint).with(headers: { "Authorization" => "Bearer edify_good" })
                                  .to_return(status: 200, body: body.to_json)

      out, err, status = run_cli("speakers", "stale")

      expect([status, err]).to eq([0, ""])
      expect(out).to eq(<<~TABLE)
        Not spoken since 2025-11-23, the last 12 months:
        NAME         GENDER  GROUP  LAST_TALK
        Doe, Jane    female  adult  never
        Roe, Samuel  male    youth  2024-06-02
      TABLE
    end

    it "passes the options through as query parameters and names the group" do
      stub_request(:get, "#{endpoint}?months=6&limit=5&group=youth")
        .to_return(status: 200, body: body.merge(months: 6, group: "youth", speakers: []).to_json)

      out, _err, status = run_cli("speakers", "stale", "--months", "6", "--limit", "5", "--group", "youth")

      expect(status).to eq(0)
      expect(out).to eq("Not spoken since 2025-11-23, the last 6 months (youth only):\nNobody to list.\n")
    end

    it "prints the API's JSON with --json" do
      stub_request(:get, endpoint).to_return(status: 200, body: body.to_json)

      out, _err, status = run_cli("speakers", "stale", "--json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to eq(JSON.parse(body.to_json))
    end

    it "rejects an unknown group before calling the API" do
      _out, err, status = run_cli("speakers", "stale", "--group", "child")

      expect(status).to eq(1)
      expect(err).to include("Expected '--group' to be one of primary, youth, adult")
    end

    it "prints the API's error message and exits 1" do
      stub_request(:get, "#{endpoint}?months=500").to_return(
        status: 422, body: { error: { code: "invalid_request", message: "months must be a whole number from 1 to 120." } }.to_json
      )

      out, err, status = run_cli("speakers", "stale", "--months", "500")

      expect([out, status]).to eq(["", 1])
      expect(err.strip).to eq("months must be a whole number from 1 to 120.")
    end

    it "suggests logging in again when the token is refused" do
      stub_request(:get, endpoint).to_return(
        status: 401, body: { error: { code: "invalid_token", message: "Send a valid API token." } }.to_json
      )

      _out, err, status = run_cli("speakers", "stale")

      expect(status).to eq(1)
      expect(err).to include("Send a valid API token.", "may have been revoked or expired", "run `edify login`")
    end

    it "asks the user to log in first" do
      File.delete(Edify::Config.new.path)

      _out, err, status = run_cli("speakers", "stale")

      expect(status).to eq(1)
      expect(err).to include("Not logged in. Run `edify login`")
    end

    it "uses the production server with only EDIFY_TOKEN and no saved login" do
      File.delete(Edify::Config.new.path)
      ENV["EDIFY_TOKEN"] = "edify_env"
      stub_request(:get, "#{Edify::Config::DEFAULT_URL}/api/v1/speakers/stale")
        .with(headers: { "Authorization" => "Bearer edify_env" })
        .to_return(status: 200, body: body.to_json)

      _out, _err, status = run_cli("speakers", "stale")

      expect(status).to eq(0)
    end

    it "uses EDIFY_URL and EDIFY_TOKEN instead of the saved login" do
      ENV["EDIFY_URL"] = "https://other.example.org"
      ENV["EDIFY_TOKEN"] = "edify_env"
      stub_request(:get, "https://other.example.org/api/v1/speakers/stale")
        .with(headers: { "Authorization" => "Bearer edify_env" })
        .to_return(status: 200, body: body.to_json)

      _out, _err, status = run_cli("speakers", "stale")

      expect(status).to eq(0)
    end
  end
end
