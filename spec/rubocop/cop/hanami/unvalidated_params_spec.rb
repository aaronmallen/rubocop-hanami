# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::UnvalidatedParams, :config do
  let(:cop_config) { { "AllowedParentClasses" => [] } }

  it "registers an offense for each key read in an action with no schema" do
    expect_offense(<<~RUBY)
      class Actions::Users::Show < App::Action
        def handle(req, res)
          req.params[:id]
          ^^^^^^^^^^^^^^^ Declare `params` or `contract` before reading `request.params`.
          req.params.fetch(:name)
          ^^^^^^^^^^^^^^^^^^^^^^^ Declare `params` or `contract` before reading `request.params`.
        end
      end
    RUBY
  end

  it "registers an offense for dig" do
    expect_offense(<<~RUBY)
      class Actions::Users::Show < App::Action
        def handle(req, res)
          req.params.dig(:user, :email)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Declare `params` or `contract` before reading `request.params`.
        end
      end
    RUBY
  end

  it "accepts reads that are not a key" do
    expect_no_offenses(<<~RUBY)
      class Actions::Users::Show < App::Action
        def handle(request, response)
          request.params.valid?
          request.params.to_h
          request.params.errors
          response.params[:id]
        end
      end
    RUBY
  end

  ["params { required(:id) }", "params Params::Show", "contract { required(:id) }", "contract Contracts::Show"]
    .each do |schema|
      it "accepts reads in an action that declares `#{schema}`" do
        expect_no_offenses(<<~RUBY)
          class Actions::Users::Show < App::Action
            #{schema}

            def handle(request, response)
              request.params[:id]
            end
          end
        RUBY
      end
    end

  it "accepts handle outside a class" do
    expect_no_offenses(<<~RUBY)
      module Helpers
        def handle(request, response)
          request.params[:id]
        end
      end
    RUBY
  end

  it "accepts handle with no arguments" do
    expect_no_offenses(<<~RUBY)
      class Actions::Home::Show < App::Action
        def handle
        end
      end
    RUBY
  end

  context "with AllowedParentClasses" do
    let(:cop_config) { { "AllowedParentClasses" => ["Admin::Action"] } }

    it "skips subclasses of an allowed class" do
      expect_no_offenses(<<~RUBY)
        class Admin::Actions::Users::Show < Admin::Action
          def handle(request, response)
            request.params[:id]
          end
        end
      RUBY
    end
  end
end
