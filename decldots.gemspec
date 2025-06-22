# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
    spec.name = "decldots"
    spec.version = Decldots::VERSION
    spec.authors = ["dec"]
    spec.email = ["gavind2559@gmail.com"]

    spec.summary = "Declarative dotfile management framework"
    spec.description = "Decldots is a declarative, extensible dotfile management framework that provides the flexibility of Nix's declarative configuration model without its immutable constraints."
    spec.homepage = "https://github.com/declspecl/decldots"
    spec.license = "MIT"
    spec.required_ruby_version = ">= 3.1.0"

    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/declspecl/decldots"
    spec.metadata["changelog_uri"] = "https://github.com/declspecl/decldots/blob/main/CHANGELOG.md"

    # Specify which files should be added to the gem when it is released.
    spec.files = Dir.chdir(__dir__) do
        `git ls-files -z`.split("\x0").reject do |f|
            (File.expand_path(f) == __FILE__) ||
                f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
        end
    end
    spec.bindir = "exe"
    spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
    spec.require_paths = ["lib"]

    # Runtime dependencies
    # (No external dependencies for MVP - using only Ruby stdlib)

    # Development dependencies
    spec.add_development_dependency "minitest", "~> 5.0"
    spec.add_development_dependency "rake", "~> 13.0"
end
