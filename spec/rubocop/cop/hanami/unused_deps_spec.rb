# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::UnusedDeps, :config do
  it "registers an offense for a key the class never reads" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser
        include Deps["repos.user_repo", "mailers.welcome"]
                                        ^^^^^^^^^^^^^^^^^ `welcome` from `Deps["mailers.welcome"]` is never used.

        def call(input)
          user_repo.create(input)
        end
      end
    RUBY
  end

  it "registers an offense for an alias the class never reads" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser
        include Deps["a", mailer: "mailers.welcome"]
                                  ^^^^^^^^^^^^^^^^^ `mailer` from `Deps["mailers.welcome"]` is never used.

        def call
          a
        end
      end
    RUBY
  end

  it "checks every include Deps line in the class" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser
        include Deps["repos.user_repo"]
        include ::Deps["log", "settings"]
                              ^^^^^^^^^^ `settings` from `Deps["settings"]` is never used.

        def call
          log.info(user_repo)
        end
      end
    RUBY
  end

  it "accepts calls with no receiver or self as the receiver" do
    expect_no_offenses(<<~RUBY)
      class Operations::CreateUser
        include Deps["a.bare", "a.receiver", "a.on_self", m: "mailers.welcome"]

        def call
          [bare, receiver.find(1), self.on_self, m]
        end
      end
    RUBY
  end

  it "accepts the instance variable and sends with a literal name" do
    expect_no_offenses(<<~RUBY)
      class Operations::CreateUser
        include Deps["a.ivar", "a.sent", "a.method"]

        def call
          [@ivar, public_send(:sent), method(:method)]
        end
      end
    RUBY
  end

  it "skips a class that passes Deps anything but literal keys" do
    expect_no_offenses(<<~RUBY)
      class A
        include Deps["a", *KEYS]
      end

      class B
        include Deps["a", m: KEY]
      end
    RUBY
  end

  it "skips a class that calls send with a name it can't read" do
    expect_no_offenses(<<~RUBY)
      class Operations::CreateUser
        include Deps["repos.user_repo"]

        def call(name)
          send(name)
        end
      end
    RUBY
  end

  it "skips modules and classes without Deps" do
    expect_no_offenses(<<~RUBY)
      module Helpers
        include Deps["repos.user_repo"]
      end

      class Empty
      end

      class Other
        include Comparable
      end
    RUBY
  end
end
