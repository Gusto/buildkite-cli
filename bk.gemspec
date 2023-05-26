# frozen_string_literal: true

require_relative "lib/bk/version"

Gem::Specification.new do |spec|
  spec.name = "buildkite-cli"
  spec.version = Bk::VERSION
  spec.licenses = ["MIT"]
  spec.authors = ["Josh Nichols"]
  spec.email = ["josh.nichols@gusto.com"]

  spec.summary = "CLI for Buildkite, similar to gh for GitHub"
  spec.homepage = "https://github.com/gusto/bk"
  spec.required_ruby_version = ">= 2.6.0"

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
  spec.add_dependency "json"
  spec.add_dependency "tty-pager"
  spec.add_dependency "tty-markdown"
  spec.add_dependency "tty-spinner"
  spec.add_dependency "tty-box"
  spec.add_dependency "graphql-client"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "dry-cli"
  spec.add_dependency "parallel"
  spec.add_dependency "ruby-progressbar"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "ruby-lsp"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "sorbet"
end
