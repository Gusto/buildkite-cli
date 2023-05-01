# frozen_string_literal: true

require_relative "lib/bk/version"

Gem::Specification.new do |spec|
  spec.name = "bk"
  spec.version = Bk::VERSION
  spec.authors = ["Josh Nichols"]
  spec.email = ["josh.nichols@gusto.com"]

  spec.summary = "CLI for Buildkite, similar to gh for GitHub"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/technicalpickles/bk"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty"
  spec.add_dependency "docopt"
  spec.add_dependency "json"
  spec.add_dependency "tty-pager"
  spec.add_dependency "tty-markdown"
end
