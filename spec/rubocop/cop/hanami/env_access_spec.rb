# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::EnvAccess, :config do
  it "registers an offense for a read with a literal key and names it" do
    expect_offense(<<~RUBY)
      ENV.fetch("MAIL_FROM")
      ^^^^^^^^^^^^^^^^^^^^^^ Read `MAIL_FROM` through settings, not `ENV`.
      ::ENV["MAIL_FROM"]
      ^^^^^^^^^^^^^^^^^^ Read `MAIL_FROM` through settings, not `ENV`.
    RUBY
  end

  it "registers an offense for a write" do
    expect_offense(<<~RUBY)
      ENV["TZ"] = "UTC"
      ^^^^^^^^^^^^^^^^^ Read `TZ` through settings, not `ENV`.
    RUBY
  end

  it "registers an offense without naming a key that is not a literal string" do
    expect_offense(<<~RUBY)
      ENV.key?(name)
      ^^^^^^^^^^^^^^ Read settings, not `ENV`.
      ENV.to_h
      ^^^^^^^^ Read settings, not `ENV`.
      use(ENV)
          ^^^ Read settings, not `ENV`.
    RUBY
  end

  it "accepts Hanami.env and other ENV constants" do
    expect_no_offenses(<<~RUBY)
      Hanami.env
      Config::ENV["MAIL_FROM"]
    RUBY
  end
end
