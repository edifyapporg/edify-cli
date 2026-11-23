RSpec.describe Edify::Commands::Meetings do
  let(:url) { "https://edify.example.org" }
  let(:api) { "#{url}/api/v1" }

  before { Edify::Config.new.save(url: url, token: "edify_good") }

  describe "meetings list" do
    let(:body) do
      {
        from: "2026-11-01", to: "2027-01-24",
        meetings: [
          { date: "2026-11-08", meeting_type: "sacrament_meeting", speakers: ["Smith, Jane", "Jones, Sam"] },
          { date: "2026-11-15", meeting_type: "testimony_meeting", speakers: [] },
        ]
      }
    end

    it "prints a table of the API's answer" do
      stub_request(:get, "#{api}/meetings").with(headers: { "Authorization" => "Bearer edify_good" })
                                           .to_return(status: 200, body: body.to_json)

      out, err, status = run_cli("meetings", "list")

      expect([status, err]).to eq([0, ""])
      expect(out).to eq(<<~TABLE)
        Meetings from 2026-11-01 through 2027-01-24:
        DATE        TYPE               SPEAKERS
        2026-11-08  Sacrament meeting  Smith, Jane; Jones, Sam
        2026-11-15  Testimony meeting
      TABLE
    end

    it "passes --from and --to through" do
      stub_request(:get, "#{api}/meetings?from=2026-10-01&to=2026-10-31")
        .to_return(status: 200, body: { from: "2026-10-01", to: "2026-10-31", meetings: [] }.to_json)

      out, _err, status = run_cli("meetings", "list", "--from", "2026-10-01", "--to", "2026-10-31")

      expect(status).to eq(0)
      expect(out).to eq("Meetings from 2026-10-01 through 2026-10-31:\nNo meetings in that time.\n")
    end

    it "prints the API's JSON with --json" do
      stub_request(:get, "#{api}/meetings").to_return(status: 200, body: body.to_json)

      out, _err, status = run_cli("meetings", "list", "--json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to eq(JSON.parse(body.to_json))
    end

    it "rejects a malformed date before calling the API" do
      _out, err, status = run_cli("meetings", "list", "--from", "11/1/2026")

      expect(status).to eq(1)
      expect(err.strip).to eq("--from must be a date written as YYYY-MM-DD.")
      expect(a_request(:get, /meetings/)).not_to have_been_made
    end
  end

  describe "meetings show" do
    let(:body) do
      {
        date: "2026-11-08", meeting_type: "sacrament_meeting",
        contributors: { presider: "Bishop Young", conductor: "Brother Ruiz", chorister: nil, organist: "Sister Park",
                        opening_prayer: nil, closing_prayer: "Brother Diaz" },
        talks: [
          { position: 1, speaker: "Smith, Jane", purpose: "Youth Speaker", topic: "Gratitude" },
          { position: 2, speaker: "Jones, Sam", purpose: nil, topic: nil },
        ],
        songs: [
          { song_type: "opening_hymn", title: "Come, Follow Me #116" },
          { song_type: "sacrament_hymn", title: "As Bread Is Broken #1007" },
        ]
      }
    end

    it "prints the meeting's program, talks and songs" do
      stub_request(:get, "#{api}/meetings/2026-11-08").to_return(status: 200, body: body.to_json)

      out, err, status = run_cli("meetings", "show", "2026-11-08")

      expect([status, err]).to eq([0, ""])
      expect(out).to eq(<<~TEXT)
        2026-11-08  Sacrament meeting

        Program:
          Presiding: Bishop Young
          Conducting: Brother Ruiz
          Organist: Sister Park
          Closing prayer: Brother Diaz

        Talks:
          Smith, Jane - Youth Speaker - "Gratitude"
          Jones, Sam

        Songs:
          Opening hymn: Come, Follow Me #116
          Sacrament hymn: As Bread Is Broken #1007
      TEXT
    end

    it "marks empty sections" do
      stub_request(:get, "#{api}/meetings/2026-11-08")
        .to_return(status: 200, body: body.merge(contributors: {}, talks: [], songs: []).to_json)

      out, _err, _status = run_cli("meetings", "show", "2026-11-08")

      expect(out).to include("Program:\n  (none)", "Talks:\n  (none)", "Songs:\n  (none)")
    end

    it "prints the API's JSON with --json" do
      stub_request(:get, "#{api}/meetings/2026-11-08").to_return(status: 200, body: body.to_json)

      out, _err, status = run_cli("meetings", "show", "2026-11-08", "--json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to eq(JSON.parse(body.to_json))
    end

    it "says when there is no meeting that day" do
      stub_request(:get, "#{api}/meetings/2026-11-23")
        .to_return(status: 404, body: { error: { code: "not_found", message: "Not found." } }.to_json)

      _out, err, status = run_cli("meetings", "show", "2026-11-23")

      expect([err.strip, status]).to eq(["No meeting on 2026-11-23.", 1])
    end

    ["11/8/2026", "../speakers/stale", "2026-11-08?x=1"].each do |date|
      it "refuses #{date.inspect} without making any request" do
        _out, err, status = run_cli("meetings", "show", date)

        expect(status).to eq(1)
        expect(err.strip).to eq("DATE must be a date written as YYYY-MM-DD.")
        expect(a_request(:any, /edify\.example\.org/)).not_to have_been_made
      end
    end
  end
end
