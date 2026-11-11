# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Hanami::RelationOutsideRepo, :config do
  let(:cop_config) { { "RelationKeyPrefixes" => ["relations."], "ROMKeys" => ["db.rom", "persistence.rom"] } }

  it "registers an offense for a relation key" do
    expect_offense(<<~RUBY)
      class Operations::ListUsers
        include ::Deps["repos.user_repo", "relations.users"]
                                          ^^^^^^^^^^^^^^^^^ Use `relations.users` only from a repo.
      end
    RUBY
  end

  it "registers an offense for the ROM container, under an alias too" do
    expect_offense(<<~RUBY)
      include Deps["repos.a", "db.rom", mapper: "persistence.rom"]
                              ^^^^^^^^ Use `db.rom` only from a repo.
                                                ^^^^^^^^^^^^^^^^^ Use `persistence.rom` only from a repo.
    RUBY
  end

  it "accepts other keys" do
    expect_no_offenses(<<~RUBY)
      include Deps["repos.user_repo", "search.relations.users", rom: KEY]
      include Other["relations.users"]
    RUBY
  end

  context "with custom settings" do
    let(:cop_config) { { "RelationKeyPrefixes" => ["db.relations."], "ROMKeys" => ["rom"] } }

    it "registers an offense for keys they name" do
      expect_offense(<<~RUBY)
        include Deps["repos.a", "db.relations.users", "rom", "relations.users"]
                                ^^^^^^^^^^^^^^^^^^^^ Use `db.relations.users` only from a repo.
                                                      ^^^^^ Use `rom` only from a repo.
      RUBY
    end
  end
end
