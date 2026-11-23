require_relative "lib/edify/version"

Gem::Specification.new do |spec|
  spec.name = "edify-cli"
  spec.version = Edify::VERSION
  spec.authors = ["Mark Oveson"]
  spec.summary = "Command-line client for the Edify API"
  spec.description = "Ask an Edify server about speakers and music from the command line, " \
                     "using a personal access token. Readable tables by default, JSON with --json."
  spec.homepage = "https://github.com/edifyapporg/edify-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "exe/*", "LICENSE.md", "README.md"]
  spec.bindir = "exe"
  spec.executables = ["edify"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.3"
end
