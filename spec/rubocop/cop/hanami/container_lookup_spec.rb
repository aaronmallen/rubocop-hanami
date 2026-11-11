# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::ContainerLookup, :config do
  let(:cop_config) { { "AllowedReceivers" => [] } }

  it "registers an offense for a lookup on a slice" do
    expect_offense(<<~RUBY)
      users = Admin::Slice["repos.user_repo"].all
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `include Deps["repos.user_repo"]` instead of a container lookup.
    RUBY
  end

  it "registers an offense for a lookup on the app" do
    expect_offense(<<~RUBY)
      class Mailers::Welcome
        LOG = ::Hanami.app["logger"]
              ^^^^^^^^^^^^^^^^^^^^^^ Use `include Deps["logger"]` instead of a container lookup.
      end
    RUBY
  end

  it "registers an offense for a lookup on a slice found through the app" do
    expect_offense(<<~RUBY)
      Hanami.app.slices[:search]["index_entity"]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `include Deps["index_entity"]` instead of a container lookup.
    RUBY
  end

  it "accepts a lookup with a key that is not a literal string" do
    expect_no_offenses(<<~RUBY)
      Admin::Slice[key]
      Hanami.app["repos.\#{name}"]
    RUBY
  end

  it "accepts a slice found through the app with no key" do
    expect_no_offenses(<<~RUBY)
      Hanami.app.slices[:admin]
    RUBY
  end

  it "accepts [] on other receivers" do
    expect_no_offenses(<<~RUBY)
      ENV["HOME"]
      Admin::Slices["x"]
      Hanami.env["x"]
    RUBY
  end

  context "with AllowedReceivers" do
    let(:cop_config) { { "AllowedReceivers" => ["Admin::Slice"] } }

    it "accepts a lookup on an allowed constant" do
      expect_no_offenses(<<~RUBY)
        Admin::Slice["repos.user_repo"]
      RUBY
    end

    it "still registers an offense for other slices" do
      expect_offense(<<~RUBY)
        Search::Slice["index_entity"]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `include Deps["index_entity"]` instead of a container lookup.
      RUBY
    end
  end
end
