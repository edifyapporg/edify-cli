RSpec.describe Edify::Commands::Talks do
  let(:url) { "https://edify.example.org" }
  let(:endpoint) { "#{url}/api/v1/talks" }
  let(:long_topic) { "Finding peace through daily scripture study and sincere prayer in hard times" }
  let(:body) do
    {
      speaker: nil, purpose: nil, from: nil, to: nil, limit: 50,
      talks: [
        { date: "2027-03-07", speaker: "Smith, Jane", purpose: nil, topic: long_topic },
        { date: "2027-01-10", speaker: "Jones, Sam", purpose: "Departing Missionary", topic: "Faith" },
      ]
    }
  end

  before { Edify::Config.new.save(url: url, token: "edify_good") }

  describe "talks list" do
    it "prints a table, shortening long topics" do
      stub_request(:get, endpoint).with(headers: { "Authorization" => "Bearer edify_good" })
                                  .to_return(status: 200, body: body.to_json)

      out, err, status = run_cli("talks", "list")

      expect([status, err]).to eq([0, ""])
      expect(out).to eq(<<~TABLE)
        DATE        SPEAKER      PURPOSE               TOPIC
        2027-03-07  Smith, Jane                        Finding peace through daily scripture study and...
        2027-01-10  Jones, Sam   Departing Missionary  Faith
      TABLE
    end

    it "passes every filter through" do
      stub_request(:get, "#{endpoint}?speaker=jane+smith&purpose=missionary&from=2027-01-01&to=2027-12-31&limit=5")
        .to_return(status: 200, body: body.to_json)

      _out, _err, status = run_cli("talks", "list", "--speaker", "jane smith", "--purpose", "missionary",
                                   "--from", "2027-01-01", "--to", "2027-12-31", "--limit", "5")

      expect(status).to eq(0)
    end

    it "prints the API's JSON, with whole topics, with --json" do
      stub_request(:get, endpoint).to_return(status: 200, body: body.to_json)

      out, _err, status = run_cli("talks", "list", "--json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to eq(JSON.parse(body.to_json))
    end

    it "says when nothing matches" do
      stub_request(:get, "#{endpoint}?speaker=nobody").to_return(status: 200, body: body.merge(talks: []).to_json)

      out, _err, status = run_cli("talks", "list", "--speaker", "nobody")

      expect([out, status]).to eq(["No talks match.\n", 0])
    end

    it "rejects a malformed date before calling the API" do
      _out, err, status = run_cli("talks", "list", "--to", "2027/12/31")

      expect(status).to eq(1)
      expect(err.strip).to eq("--to must be a date written as YYYY-MM-DD.")
      expect(a_request(:any, //)).not_to have_been_made
    end

    it "explains which roles can list talks when the API refuses the user's role" do
      stub_request(:get, endpoint).to_return(
        status: 403, body: { error: { code: "forbidden", message: "Your role does not have access to this." } }.to_json
      )

      _out, err, status = run_cli("talks", "list")

      expect([err.strip, status]).to eq([Edify::Commands::Talks::FORBIDDEN, 1])
    end

    it "prints the API's message for other errors" do
      stub_request(:get, "#{endpoint}?speaker=z").to_return(
        status: 422,
        body: { error: { code: "invalid_request", message: "speaker must be from 2 to 100 characters." } }.to_json
      )

      _out, err, status = run_cli("talks", "list", "--speaker", "z")

      expect([err.strip, status]).to eq(["speaker must be from 2 to 100 characters.", 1])
    end
  end
end
