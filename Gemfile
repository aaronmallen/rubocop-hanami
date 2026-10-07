# frozen_string_literal: true

source "https://gem.coop"

gemspec

group :development do
  gem "irb"
end

group :development, :test do
  gem "rspec", "~> 3"
  gem "simplecov", "~> 1", require: false
end

group :lint do
  gem "rubocop-ordered_methods", "~> 0.14"
  gem "rubocop-performance", "~> 1"
  gem "rubocop-rspec", "~> 3"
end
