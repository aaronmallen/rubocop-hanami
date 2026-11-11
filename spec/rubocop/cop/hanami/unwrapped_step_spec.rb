# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::UnwrappedStep, :config do
  let(:cop_config) { { "FlowMethods" => ["call"] } }
  let(:ruby_version) { 3.3 }

  it "registers an offense for a bare call to a method that returns a Result" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input)
          validate(input)
          ^^^^^^^^^^^^^^^ `validate` returns a Result; wrap it in `step`.
          user_repo.create(input)
        end

        def validate(input) = input[:email] ? Success(input) : Failure(:no_email)
      end
    RUBY
  end

  it "registers an offense for a call in steps" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input)
          steps { check(input) }
                  ^^^^^^^^^^^^ `check` returns a Result; wrap it in `step`.
        end

        def check(input) = Success(input)
      end
    RUBY
  end

  it "registers an offense for the last expression of the flow" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input) = check(input)
                          ^^^^^^^^^^^^ `check` returns a Result; wrap it in `step`.

        def check(input) = (Success(input))
      end
    RUBY
  end

  it "registers an offense for a method that returns a Result through return" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input) = a(input)
                          ^^^^^^^^ `a` returns a Result; wrap it in `step`.

        def a(input)
          return Failure(:empty) if input.empty?

          input
        end
      end
    RUBY
  end

  it "registers an offense for a method that returns a Result from a case" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input) = a(input)
                          ^^^^^^^^ `a` returns a Result; wrap it in `step`.

        def a(input)
          case input when 1 then Success(1) end
        end
      end
    RUBY
  end

  it "accepts a call passed to step, assigned, used as a receiver or passed on" do
    expect_no_offenses(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input)
          attrs = step validate(input)
          result = validate(attrs)
          return log(validate(attrs)) if validate(attrs).failure?
        end

        def validate(input) = Success(input)
      end
    RUBY
  end

  it "accepts calls outside flow methods" do
    expect_no_offenses(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def helper(input)
          validate(input)
        end

        def validate(input) = Success(input)
      end
    RUBY
  end

  it "accepts calls to methods that return no Result" do
    expect_no_offenses(<<~RUBY)
      class Operations::CreateUser < App::Operation
        def call(input)
          log(input)
        end

        def log(input)
          return if input.nil?
        end
      end
    RUBY
  end

  it "reads flow methods from operate_on" do
    expect_offense(<<~RUBY)
      class Operations::CreateUser < App::Operation
        operate_on :run, "other"

        def run(args) = validate(args)
                        ^^^^^^^^^^^^^^ `validate` returns a Result; wrap it in `step`.

        def validate(input) = Success(input)
      end
    RUBY
  end
end
