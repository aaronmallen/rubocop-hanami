# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::ProviderTopLevelRequire, :config do
  it "registers an offense for a require at the top level" do
    expect_offense(<<~RUBY)
      require "sidekiq"
      ^^^^^^^^^^^^^^^^^ Move `require "sidekiq"` into `prepare`.
      require_relative "../sidekiq"
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Move `require_relative "../sidekiq"` into `prepare`.
    RUBY
  end

  it "registers an offense for a require in the register_provider block" do
    expect_offense(<<~RUBY)
      Admin::Slice.register_provider(:sidekiq) do
        require "sidekiq"
        ^^^^^^^^^^^^^^^^^ Move `require "sidekiq"` into `prepare`.

        stop do
          require "sidekiq/api"
          ^^^^^^^^^^^^^^^^^^^^^ Move `require "sidekiq/api"` into `prepare`.
        end
      end
    RUBY
  end

  it "accepts a require in prepare or start" do
    expect_no_offenses(<<~RUBY)
      Hanami.app.register_provider(:sidekiq) do
        prepare do
          require "sidekiq"
        end

        start { require "sidekiq/api" }
      end
    RUBY
  end

  it "accepts require on a receiver" do
    expect_no_offenses(<<~RUBY)
      Kernel.require "sidekiq"
    RUBY
  end
end
