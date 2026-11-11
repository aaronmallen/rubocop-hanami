# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::SliceExports, :config do
  let(:cop_config) do
    {
      "AllowedExports" => ["repos.queries", /\Aoperations\./],
      "ForbiddenExports" => ["repos.mutations"],
      "ParentClasses" => ["Hanami::Slice"],
      "RequireExport" => true,
    }
  end

  it "registers an offense when a slice never calls export" do
    expect_offense(<<~RUBY)
      class Admin::Slice < Hanami::Slice
            ^^^^^^^^^^^^ Call `export`; a slice without it lets other slices import every key.
      end
    RUBY
  end

  it "registers an offense when export takes something other than a literal array" do
    expect_offense(<<~RUBY)
      class Admin::Slice < Hanami::Slice
        export(
          KEYS,
          ^^^^ Export a literal array of strings.
        )
      end
    RUBY
  end

  it "registers an offense for each key that is not a string" do
    expect_offense(<<~RUBY)
      class Admin::Slice < Hanami::Slice
        export [
          "repos.queries",
          key,
          ^^^ Export a literal array of strings.
        ]
      end
    RUBY
  end

  it "registers an offense for a forbidden key" do
    expect_offense(<<~RUBY)
      class Admin::Slice < Hanami::Slice
        export ["repos.mutations"]
                ^^^^^^^^^^^^^^^^^ `repos.mutations` matches ForbiddenExports.
      end
    RUBY
  end

  it "registers an offense for a key no allowed pattern matches" do
    expect_offense(<<~RUBY)
      class Admin::Slice < Hanami::Slice
        export ["views.index"]
                ^^^^^^^^^^^^^ `views.index` matches none of AllowedExports.
      end
    RUBY
  end

  it "accepts keys that match an allowed string or pattern" do
    expect_no_offenses(<<~RUBY)
      module Admin
        class Slice < ::Hanami::Slice
          export ["repos.queries", "operations.create"]
        end
      end
    RUBY
  end

  it "ignores classes that are not slices" do
    expect_no_offenses(<<~RUBY)
      class Admin::Action < Hanami::Action
      end
    RUBY
  end

  context "with a custom ParentClasses" do
    let(:cop_config) { { "ParentClasses" => ["MyApp::Slice"], "RequireExport" => true } }

    it "registers an offense for a slice that inherits from one of them" do
      expect_offense(<<~RUBY)
        class Admin::Slice < MyApp::Slice
              ^^^^^^^^^^^^ Call `export`; a slice without it lets other slices import every key.
        end
      RUBY
    end

    it "ignores a class that inherits from Hanami::Slice" do
      expect_no_offenses(<<~RUBY)
        class Admin::Slice < Hanami::Slice
        end
      RUBY
    end
  end

  context "with RequireExport off" do
    let(:cop_config) do
      { "ForbiddenExports" => ["repos.mutations"], "ParentClasses" => ["Hanami::Slice"], "RequireExport" => false }
    end

    it "accepts a slice that never calls export" do
      expect_no_offenses(<<~RUBY)
        class Admin::Slice < Hanami::Slice
        end
      RUBY
    end

    it "still registers an offense for a forbidden key" do
      expect_offense(<<~RUBY)
        class Admin::Slice < Hanami::Slice
          export ["repos.mutations"]
                  ^^^^^^^^^^^^^^^^^ `repos.mutations` matches ForbiddenExports.
        end
      RUBY
    end
  end

  context "with an empty AllowedExports" do
    let(:cop_config) { { "AllowedExports" => [], "ParentClasses" => ["Hanami::Slice"] } }

    it "accepts any key" do
      expect_no_offenses(<<~RUBY)
        class Admin::Slice < Hanami::Slice
          export ["views.index"]
        end
      RUBY
    end
  end
end
