RSpec.describe Edify::Commands::Members do
  let(:url) { "https://edify.example.org" }
  let(:endpoint) { "#{url}/api/v1/members" }
  let(:body) do
    {
      query: "jane smith", limit: 25,
      members: [
        { name: "Smith, Jane", gender: "female", group: "adult" },
        { name: "Smithson, Jane Ann", gender: "female", group: "youth" },
      ]
    }
  end

  before { Edify::Config.new.save(url: url, token: "edify_good") }

  describe "members search" do
    it "joins the words into one query and prints a table" do
      stub_request(:get, "#{endpoint}?q=jane+smith").with(headers: { "Authorization" => "Bearer edify_good" })
                                                    .to_return(status: 200, body: body.to_json)

      out, err, status = run_cli("members", "search", "jane", "smith")

      expect([status, err]).to eq([0, ""])
      expect(out).to eq(<<~TABLE)
        NAME                GENDER  GROUP
        Smith, Jane         female  adult
        Smithson, Jane Ann  female  youth
      TABLE
    end

    it "passes --limit through" do
      stub_request(:get, "#{endpoint}?q=smith&limit=1").to_return(status: 200, body: body.merge(limit: 1).to_json)

      _out, _err, status = run_cli("members", "search", "smith", "--limit", "1")

      expect(status).to eq(0)
    end

    it "says when nothing matches" do
      stub_request(:get, "#{endpoint}?q=nobody").to_return(status: 200,
                                                           body: { query: "nobody", limit: 25, members: [] }.to_json)

      out, _err, status = run_cli("members", "search", "nobody")

      expect([out, status]).to eq(["No members match \"nobody\".\n", 0])
    end

    it "prints the API's JSON with --json" do
      stub_request(:get, "#{endpoint}?q=jane+smith").to_return(status: 200, body: body.to_json)

      out, _err, status = run_cli("members", "search", "jane", "smith", "--json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to eq(JSON.parse(body.to_json))
    end

    it "explains which roles can search when the API refuses the user's role" do
      stub_request(:get, "#{endpoint}?q=smith").to_return(
        status: 403, body: { error: { code: "forbidden", message: "Your role does not have access to this." } }.to_json
      )

      _out, err, status = run_cli("members", "search", "smith")

      expect(status).to eq(1)
      expect(err.strip).to eq(Edify::Commands::Members::FORBIDDEN)
    end

    it "prints the API's message for other errors" do
      stub_request(:get, "#{endpoint}?q=a").to_return(
        status: 422, body: { error: { code: "invalid_request", message: "q must be from 2 to 100 characters." } }.to_json
      )

      _out, err, status = run_cli("members", "search", "a")

      expect([err.strip, status]).to eq(["q must be from 2 to 100 characters.", 1])
    end

    it "asks for a name before calling the API" do
      _out, err, status = run_cli("members", "search")

      expect(status).to eq(1)
      expect(err).to include("Give part of a name to search for")
      expect(a_request(:any, //)).not_to have_been_made
    end
  end
end
