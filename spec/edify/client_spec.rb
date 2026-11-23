RSpec.describe Edify::Client do
  subject(:client) { described_class.new(url: "https://edify.example.org/", token: "edify_secret") }

  let(:endpoint) { "https://edify.example.org/api/v1/speakers/stale" }

  describe "#get" do
    it "sends the token as a Bearer header and returns the parsed body" do
      stub_request(:get, "#{endpoint}?months=6")
        .with(headers: { "Authorization" => "Bearer edify_secret", "Accept" => "application/json" })
        .to_return(status: 200, body: '{"speakers":[]}', headers: { "Content-Type" => "application/json" })

      expect(client.get("speakers/stale", months: 6, group: nil)).to eq("speakers" => [])
    end

    it "raises the API's error code and message" do
      stub_request(:get, endpoint).to_return(
        status: 401, body: '{"error":{"code":"invalid_token","message":"Send a valid API token."}}'
      )

      expect { client.get("speakers/stale") }.to raise_error(
        an_instance_of(described_class::Error).and(having_attributes(code: "invalid_token",
                                                                     message: "Send a valid API token."))
      )
    end

    it "explains a response that is not from the Edify API" do
      stub_request(:get, endpoint).to_return(status: 502, body: "<html>Bad Gateway</html>")

      expect { client.get("speakers/stale") }.to raise_error(described_class::Error, /HTTP 502 without an API error/)
    end

    it "explains a server it cannot reach" do
      stub_request(:get, endpoint).to_raise(Errno::ECONNREFUSED)

      expect { client.get("speakers/stale") }.to raise_error(
        an_instance_of(described_class::Error).and(having_attributes(code: "connection_failed"))
      )
    end
  end

  describe "the server URL" do
    it "allows plain http only for the local machine" do
      expect { described_class.new(url: "http://localhost:3000", token: "t") }.not_to raise_error
      expect { described_class.new(url: "http://127.0.0.1:3000", token: "t") }.not_to raise_error
      expect { described_class.new(url: "http://edify.example.org", token: "t") }.to raise_error(
        an_instance_of(described_class::Error).and(having_attributes(code: "insecure_url"))
      )
    end

    it "rejects something that is not a URL" do
      expect { described_class.new(url: "edify", token: "t") }.to raise_error(
        an_instance_of(described_class::Error).and(having_attributes(code: "invalid_url"))
      )
    end
  end
end
