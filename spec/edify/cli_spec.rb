RSpec.describe Edify::CLI do
  describe "version" do
    it "prints the version" do
      out, _err, status = run_cli("version")
      expect([out.strip, status]).to eq([Edify::VERSION, 0])
    end
  end
end
