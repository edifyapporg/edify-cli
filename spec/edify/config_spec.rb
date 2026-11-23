RSpec.describe Edify::Config do
  subject(:config) { described_class.new }

  let(:directory) { File.join(ENV.fetch("XDG_CONFIG_HOME"), "edify") }

  describe ".default_path" do
    it "uses XDG_CONFIG_HOME when it is set" do
      expect(described_class.default_path("XDG_CONFIG_HOME" => "/tmp/xdg")).to eq("/tmp/xdg/edify/config.yml")
    end

    it "falls back to ~/.config" do
      expect(described_class.default_path({})).to eq(File.join(Dir.home, ".config", "edify", "config.yml"))
    end
  end

  describe "#save" do
    it "stores the URL and token where only the owner can read them" do
      config.save(url: "https://edify.example.org", token: "edify_secret")

      expect(File.stat(directory).mode & 0o777).to eq(0o700)
      expect(File.stat(config.path).mode & 0o777).to eq(0o600)
      reloaded = described_class.new
      expect([reloaded.url, reloaded.token]).to eq(["https://edify.example.org", "edify_secret"])
    end

    it "tightens the permissions of an existing file" do
      FileUtils.mkdir_p(directory)
      File.write(config.path, "url: old\n")
      File.chmod(0o644, config.path)

      config.save(url: "https://edify.example.org", token: "edify_secret")

      expect(File.stat(config.path).mode & 0o777).to eq(0o600)
    end
  end

  describe "reading" do
    it "is not configured before login" do
      expect(config).not_to be_configured
    end

    it "lets EDIFY_URL and EDIFY_TOKEN override the saved values" do
      config.save(url: "https://saved.example.org", token: "edify_saved")
      env = { "XDG_CONFIG_HOME" => ENV.fetch("XDG_CONFIG_HOME"), "EDIFY_URL" => "https://env.example.org",
              "EDIFY_TOKEN" => "edify_env" }

      overridden = described_class.new(env: env)

      expect([overridden.url, overridden.token]).to eq(["https://env.example.org", "edify_env"])
    end

    it "ignores blank environment variables" do
      config.save(url: "https://saved.example.org", token: "edify_saved")
      env = { "XDG_CONFIG_HOME" => ENV.fetch("XDG_CONFIG_HOME"), "EDIFY_URL" => " ", "EDIFY_TOKEN" => "" }

      expect(described_class.new(env: env).token).to eq("edify_saved")
    end
  end
end
