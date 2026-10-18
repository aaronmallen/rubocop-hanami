# frozen_string_literal: true

require "tmpdir"

RSpec.describe RuboCop::Cop::Hanami::UnusedDeps, :config do
  let(:ruby_version) { 3.3 }

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

  it "accepts a keyword of initialize read in its body" do
    expect_no_offenses(<<~RUBY)
      class Operations::Build
        include Deps["operations.build_document"]

        def initialize(build_document:, **)
          @descriptor = build_document.descriptor(:foo)
          super(build_document:, **)
        end
      end
    RUBY
  end

  it "registers an offense for a keyword of initialize only passed to super" do
    expect_offense(<<~RUBY)
      class Operations::Build
        include Deps["log", "operations.build_document"]
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ `build_document` from `Deps["operations.build_document"]` is never used.

        def initialize(build_document:, **)
          log.info("building")
          super(build_document:, **)
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

  context "with AllowedNames" do
    let(:cop_config) { { "AllowedNames" => ["contract"] } }

    it "accepts a name in the list" do
      expect_offense(<<~RUBY)
        class Operations::SaveTask < MyApp::Operation
          include Deps[contract: "contracts.task", log: "log"]
                                                        ^^^^^ `log` from `Deps["log"]` is never used.
        end
      RUBY
    end
  end

  context "with parents and mixins in other files" do
    let(:root) { Dir.mktmpdir }

    before do
      write "lib/blog/operation.rb", <<~RUBY
        module Blog
          class Operation < Dry::Operation
            def validate(input) = contract.call(input)
          end
        end
      RUBY
      write "lib/blog/logged_operation.rb", <<~RUBY
        module Blog
          class LoggedOperation < Operation
          end
        end
      RUBY
      write "app/threads.rb", <<~RUBY
        module MyApp
          module Threads
            def threads = thread_queries.all
          end
        end
      RUBY
      allow(config).to receive(:base_dir_for_path_parameters).and_return(root)
    end

    after { FileUtils.remove_entry(root) }

    def write(path, source)
      FileUtils.mkdir_p(File.dirname(File.join(root, path)))
      File.write(File.join(root, path), source)
    end

    it "accepts a name a parent reads" do
      expect_no_offenses(<<~RUBY)
        module Tasks
          module Operations
            class SaveTask < Blog::Operation
              include Deps[contract: "contracts.task_contract"]
            end
          end
        end
      RUBY
    end

    it "accepts a name a grandparent reads" do
      expect_no_offenses(<<~RUBY)
        class LogTask < Blog::LoggedOperation
          include Deps[contract: "contracts.task_contract"]
        end
      RUBY
    end

    it "accepts a name an included module reads" do
      expect_no_offenses(<<~RUBY)
        module MyApp
          module Actions
            class Index < MyApp::Action
              include Threads
              include Deps["queries.thread_queries"]
            end
          end
        end
      RUBY
    end

    it "registers an offense for a name no parent reads" do
      expect_offense(<<~RUBY)
        class SaveTask < Blog::Operation
        include Deps[contract: "contracts.task_contract", logger: "log"]
                                                                  ^^^^^ `logger` from `Deps["log"]` is never used.
        end
      RUBY
    end

    it "skips a class whose parent calls send with a name it can't read" do
      write "lib/blog/dynamic.rb", "class Blog::Dynamic; def call(name) = send(name); end"

      expect_no_offenses(<<~RUBY)
        class SaveTask < Blog::Dynamic
          include Deps["log"]
        end
      RUBY
    end

    it "changes the cache checksum when a file changes" do
      checksum = cop.external_dependency_checksum
      File.utime(Time.now, Time.now + 10, File.join(root, "lib/blog/operation.rb"))

      expect(cop.external_dependency_checksum).not_to eq(checksum)
    end
  end
end
