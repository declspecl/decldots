# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "sorbet-runtime"
gem "webrick", "~> 1.9"
gem "xdg", "~> 9.2"

group :development, :test do
    gem "irb"
    gem "ruby_parser", "~> 3.21"

    gem "rake", "~> 13.0"
    gem "rspec", "~> 3.0"

    gem "sorbet", "~> 0.5", require: false
    gem "tapioca", require: false

    gem "rubocop", "~> 1.21", require: false
    gem "rubocop-minitest", "~> 0.38.1", require: false
    gem "rubocop-performance", "~> 1.25", require: false
    gem "rubocop-rake", "~> 0.7.1", require: false
    gem "rubocop-rspec", "~> 3.6", require: false
    gem "rubocop-sorbet", "~> 0.10.3", require: false
    gem "rubocop-thread_safety", "~> 0.6.0", require: false
end
