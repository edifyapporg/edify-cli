RSpec.describe Edify::Commands::Songs do
  let(:url) { "https://edify.example.org" }
  let(:endpoint) { "#{url}/api/v1/songs/recent" }
  let(:body) do
    {
      weeks: 12, song_type: nil, since: "2026-08-31",
      songs: [
        { title: "Come, Follow Me #116", times_sung: 2, last_sung: "2026-11-08",
          song_types: %w[opening_hymn closing_hymn] },
        { title: "As Bread Is Broken #1007", times_sung: 1, last_sung: "2026-11-22", song_types: %w[sacrament_hymn] },
      ]
    }
  end

  before { Edify::Config.new.save(url: url, token: "edify_good") }

  describe "songs recent" do
    it "prints a table of the API's answer" do
      stub_request(:get, endpoint).with(headers: { "Authorization" => "Bearer edify_good" })
                                  .to_return(status: 200, body: body.to_json)

      out, err, status = run_cli("songs", "recent")

      expect([status, err]).to eq([0, ""])
      expect(out).to eq(<<~TABLE)
        Sung since 2026-08-31, the last 12 weeks:
        TITLE                     TIMES  LAST_SUNG   TYPES
        Come, Follow Me #116      2      2026-11-08  opening_hymn, closing_hymn
        As Bread Is Broken #1007  1      2026-11-22  sacrament_hymn
      TABLE
    end

    it "passes the options through and names the song type" do
      stub_request(:get, "#{endpoint}?weeks=4&limit=5&song_type=sacrament_hymn")
        .to_return(status: 200, body: body.merge(weeks: 4, song_type: "sacrament_hymn", songs: []).to_json)

      out, _err, status = run_cli("songs", "recent", "--weeks", "4", "--limit", "5", "--song-type", "sacrament_hymn")

      expect(status).to eq(0)
      expect(out).to eq("Sung since 2026-08-31, the last 4 weeks (sacrament_hymn only):\nNothing sung in that time.\n")
    end

    it "prints the API's JSON with --json" do
      stub_request(:get, endpoint).to_return(status: 200, body: body.to_json)

      out, _err, status = run_cli("songs", "recent", "--json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to eq(JSON.parse(body.to_json))
    end

    it "rejects an unknown song type before calling the API" do
      _out, err, status = run_cli("songs", "recent", "--song-type", "prelude")

      expect(status).to eq(1)
      expect(err).to include("Expected '--song-type' to be one of opening_hymn, sacrament_hymn")
    end

    it "prints the API's error message and exits 1" do
      stub_request(:get, "#{endpoint}?weeks=500").to_return(
        status: 422, body: { error: { code: "invalid_request", message: "weeks must be a whole number from 1 to 104." } }.to_json
      )

      _out, err, status = run_cli("songs", "recent", "--weeks", "500")

      expect([err.strip, status]).to eq(["weeks must be a whole number from 1 to 104.", 1])
    end
  end
end
