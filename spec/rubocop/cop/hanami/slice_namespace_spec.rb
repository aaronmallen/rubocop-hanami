# frozen_string_literal: true

require "tmpdir"

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

  context "with Inflections keyed by word" do
    let(:cop_config) { { "Inflections" => { "tmas" => "TMAS" } } }

    it "inflects each word of the slice" do
      expect_offense(<<~RUBY, "slices/tmas_gate_counts/summarize_entry.rb")
        module TMASGateCounts
        end

        class TmasGateCounts
              ^^^^^^^^^^^^^^ Files in `slices/tmas_gate_counts` belong in the `TMASGateCounts` namespace.
        end
      RUBY
    end
  end

  context "with acronyms in config/app.rb" do
    let(:root) { Dir.mktmpdir }
    let(:app_config) { File.join(root, "config", "app.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(app_config))
      File.write(app_config, <<~RUBY)
        module MyApp
          class App < Hanami::App
            config.inflections do |inflections|
              inflections.acronym "TMAS", :API
            end
          end
        end
      RUBY
      allow(config).to receive(:base_dir_for_path_parameters).and_return(root)
    end

    after { FileUtils.remove_entry(root) }

    it "uses the app's acronyms" do
      expect_offense(<<~RUBY, "slices/tmas_gate_counts/summarize_entry.rb")
        module TMASGateCounts
        end

        class TmasGateCounts
              ^^^^^^^^^^^^^^ Files in `slices/tmas_gate_counts` belong in the `TMASGateCounts` namespace.
        end
      RUBY
      expect_no_offenses("class API::Action; end", "slices/api/action.rb")
    end

    it "changes the cache checksum with the app config" do
      expect(cop.external_dependency_checksum).to eq(Digest::SHA1.file(app_config).hexdigest)
    end
  end
end
