require "edify/cli"
require "stringio"
require "tmpdir"
require "webmock/rspec"

module CliHelpers
  # Runs the edify command in-process.
  # @return [Array(String, String, Integer)] stdout, stderr and the exit status
  def run_cli(*args, stdin: "")
    # Where Readline is available (Ruby 3.3 and 3.4 ship it), Thor prompts through it, which reads the terminal
    # rather than $stdin. The basic editor reads $stdin, so prompts can be answered from the test.
    allow(Thor::LineEditor).to receive(:best_available).and_return(Thor::LineEditor::Basic)
    out = StringIO.new
    err = StringIO.new
    status = 0
    original = [$stdout, $stderr, $stdin]
    $stdout = out
    $stderr = err
    $stdin = StringIO.new(stdin)
    begin
      Edify::CLI.start(args)
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout, $stderr, $stdin = original
    end
    [out.string, err.string, status]
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = ".rspec_status"
  config.include CliHelpers

  # Every example gets its own config directory and no EDIFY_* variables, so no test reads or writes a real login.
  config.around do |example|
    saved = ENV.to_h.slice("XDG_CONFIG_HOME", "EDIFY_URL", "EDIFY_TOKEN")
    Dir.mktmpdir do |dir|
      ENV["XDG_CONFIG_HOME"] = dir
      ENV.delete("EDIFY_URL")
      ENV.delete("EDIFY_TOKEN")
      example.run
    ensure
      %w[XDG_CONFIG_HOME EDIFY_URL EDIFY_TOKEN].each { |key| ENV.delete(key) }
      ENV.update(saved)
    end
  end
end
