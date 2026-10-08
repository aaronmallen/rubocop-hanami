# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "rubocop-hanami"
  spec.version = "0.2.0"
  spec.authors = ["Aaron Allen"]
  spec.email = ["hello@aaronmallen.me"]

  spec.summary = "RuboCop cops for Hanami"
  spec.description = "A collection of RuboCop cops that check Hanami apps and slices."
  spec.homepage = "https://github.com/aaronmallen/rubocop-hanami"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "default_lint_roller_plugin" => "RuboCop::Hanami::Plugin",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage,
  }

  spec.files = Dir["config/**/*", "lib/**/*", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller", "~> 1.1"
  spec.add_dependency "rubocop", "~> 1.72"
end
