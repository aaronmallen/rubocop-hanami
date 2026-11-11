# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::ActionCallOverride, :config do
  let(:cop_config) { { "ParentClasses" => ["Hanami::Action"] } }

  it "registers an offense for call in a class under actions" do
    expect_offense(<<~RUBY, "app/actions/home/show.rb")
      class Actions::Home::Show < App::Action
        def call(env)
        ^^^^^^^^ Define `handle` instead of `call` in an action.
          [200, {}, ["hi"]]
        end
      end
    RUBY
  end

  it "registers an offense for call in a subclass of ParentClasses" do
    expect_offense(<<~RUBY, "app/action.rb")
      class Action < ::Hanami::Action
        def call(env)
        ^^^^^^^^ Define `handle` instead of `call` in an action.
        end
      end
    RUBY
  end

  it "accepts a call that calls super" do
    expect_no_offenses(<<~RUBY, "app/action.rb")
      class Action < Hanami::Action
        def call(env)
          log(env)
          super
        end
      end
    RUBY
  end

  it "accepts handle, and call outside an action" do
    expect_no_offenses(<<~RUBY, "app/operations/create_user.rb")
      class Actions::Home::Show < App::Action
        def handle(request, response)
        end
      end

      class Operations::CreateUser < App::Operation
        def call(input)
        end
      end
    RUBY
  end

  it "accepts a call defined on the class" do
    expect_no_offenses(<<~RUBY, "app/actions/home/show.rb")
      class Actions::Home::Show < App::Action
        class << self
          def call(env)
          end
        end
      end
    RUBY
  end

  it "accepts a call outside a class" do
    expect_no_offenses(<<~RUBY, "app/actions/helpers.rb")
      module Helpers
        def call
        end
      end
    RUBY
  end
end
