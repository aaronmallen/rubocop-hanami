# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::SliceNamespace, :config do
  let(:cop_config) { { "Inflections" => {} } }

  it "registers an offense for a top-level class outside the slice's namespace" do
    expect_offense(<<~RUBY, "slices/admin/actions/users/index.rb")
      class Backoffice::Actions::Users::Index
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Files in `slices/admin` belong in the `Admin` namespace.
      end
    RUBY
  end

  it "camelizes the slice and checks the first segment of each name" do
    expect_offense(<<~RUBY, "slices/admin_panel/action.rb")
      class AdminPanel::Action < MyApp::Action
      end

      class ::Admin::Panel
            ^^^^^^^^^^^^^^ Files in `slices/admin_panel` belong in the `AdminPanel` namespace.
      end
    RUBY
  end

  it "uses the innermost slice" do
    expect_offense(<<~RUBY, "slices/admin/slices/billing/repo.rb")
      class Admin::Repo
            ^^^^^^^^^^^ Files in `slices/billing` belong in the `Billing` namespace.
      end
    RUBY
  end

  it "accepts the slice class, files with no module or class, and files outside slices" do
    expect_no_offenses(<<~RUBY, "slices/admin/config/slice.rb")
      class Admin::Slice < Hanami::Slice
      end
    RUBY
    expect_no_offenses(<<~RUBY, "slices/admin/db/migrate/1_create_users.rb")
      ROM::SQL.migration { change { create_table(:users) } }
    RUBY
    expect_no_offenses("module Other; end", "app/actions/home.rb")
  end

  context "with Inflections" do
    let(:cop_config) { { "Inflections" => { "api" => "API" } } }

    it "uses the inflected name" do
      expect_offense(<<~RUBY, "slices/api/action.rb")
        class API::Action < MyApp::Action
        end

        class Api::Other
              ^^^^^^^^^^ Files in `slices/api` belong in the `API` namespace.
        end
      RUBY
    end
  end
end
