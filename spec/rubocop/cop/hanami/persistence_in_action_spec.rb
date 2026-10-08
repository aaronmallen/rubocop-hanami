# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::PersistenceInAction, :config do
  let(:cop_config) { { "AllowedKeys" => [], "ForbiddenKeyPrefixes" => ["repos.", "relations."] } }

  it "registers an offense for a repo or relation key" do
    expect_offense(<<~RUBY)
      class Actions::Users::Create < App::Action
        include Deps["a", "repos.user_repo", users: "relations.users"]
                          ^^^^^^^^^^^^^^^^^ Call an operation instead of `repos.user_repo` from an action.
                                                    ^^^^^^^^^^^^^^^^^ Call an operation instead of `relations.users` from an action.
      end
    RUBY
  end

  it "registers an offense for an imported repo" do
    expect_offense(<<~RUBY)
      include Deps["a", "search.repos.index"]
                        ^^^^^^^^^^^^^^^^^^^^ Call an operation instead of `search.repos.index` from an action.
    RUBY
  end

  it "accepts other keys" do
    expect_no_offenses(<<~RUBY)
      include Deps["operations.create_user", "views.repos", "myrepos.user"]
    RUBY
  end

  context "with AllowedKeys" do
    let(:cop_config) do
      { "AllowedKeys" => ["repos.user_queries", /\.queries\z/], "ForbiddenKeyPrefixes" => ["repos."] }
    end

    it "accepts a key that matches an allowed string or pattern" do
      expect_no_offenses(<<~RUBY)
        include Deps["repos.user_queries", "repos.post.queries"]
      RUBY
    end

    it "still registers an offense for other keys" do
      expect_offense(<<~RUBY)
        include Deps["a", "repos.user_repo"]
                          ^^^^^^^^^^^^^^^^^ Call an operation instead of `repos.user_repo` from an action.
      RUBY
    end
  end
end
