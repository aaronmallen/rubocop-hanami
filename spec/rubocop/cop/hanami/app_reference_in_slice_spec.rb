# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::AppReferenceInSlice, :config do
  let(:cop_config) { { "AppNamespaces" => [] } }

  it "registers an offense for Hanami.app and anything chained on it" do
    expect_offense(<<~RUBY)
      def handle(request, response)
        Hanami.app.settings.page_size
        ^^^^^^^^^^ Don't reference `Hanami.app` from a slice; use `Deps` or `import`.
        ::Hanami.app.slices[:search]
        ^^^^^^^^^^^^ Don't reference `Hanami.app` from a slice; use `Deps` or `import`.
      end
    RUBY
  end

  it "accepts other methods on Hanami" do
    expect_no_offenses(<<~RUBY)
      Hanami.app?
      Hanami.env
      Hanami.env?(:test)
      app
    RUBY
  end

  it "accepts constants outside AppNamespaces" do
    expect_no_offenses(<<~RUBY)
      MyApp::Types::String
    RUBY
  end

  context "with Hanami/ContainerLookup on" do
    let(:other_cops) { { "Hanami/ContainerLookup" => { "Enabled" => true } } }

    it "leaves container lookups to it" do
      expect_no_offenses(<<~RUBY)
        Hanami.app["logger"]
        Hanami.app.slices[:search]["index_entity"]
      RUBY
    end

    it "still registers an offense for a lookup ContainerLookup skips" do
      expect_offense(<<~RUBY)
        Hanami.app[key]
        ^^^^^^^^^^ Don't reference `Hanami.app` from a slice; use `Deps` or `import`.
      RUBY
    end
  end

  context "with Hanami/ContainerLookup off" do
    let(:other_cops) { { "Hanami/ContainerLookup" => { "Enabled" => false } } }

    it "registers an offense for container lookups" do
      expect_offense(<<~RUBY)
        Hanami.app["logger"]
        ^^^^^^^^^^ Don't reference `Hanami.app` from a slice; use `Deps` or `import`.
      RUBY
    end
  end

  context "with AppNamespaces" do
    let(:cop_config) { { "AppNamespaces" => ["MyApp"] } }

    it "registers an offense for a constant in the app's namespace" do
      expect_offense(<<~RUBY)
        class Admin::Action < MyApp::Action
                              ^^^^^ Don't reference `MyApp` from a slice; use `Deps` or `import`.
        end

        ::MyApp::Types::String
        ^^^^^^^ Don't reference `MyApp` from a slice; use `Deps` or `import`.
      RUBY
    end

    it "accepts a nested constant with the same name" do
      expect_no_offenses(<<~RUBY)
        Admin::MyApp
      RUBY
    end
  end
end
