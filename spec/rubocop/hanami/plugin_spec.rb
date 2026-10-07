# frozen_string_literal: true

RSpec.describe RuboCop::Hanami::Plugin do
  subject(:plugin) { described_class.new }

  let(:context) { LintRoller::Context.new(engine: :rubocop) }
  let(:gemspec) { Gem::Specification.load(File.expand_path("../../../rubocop-hanami.gemspec", __dir__)) }

  it "is the plugin the gemspec names, so `plugins: - rubocop-hanami` finds it" do
    expect(gemspec.metadata["default_lint_roller_plugin"]).to eq(described_class.name)
  end

  it "supports RuboCop only" do
    expect([plugin.supported?(context), plugin.supported?(LintRoller::Context.new(engine: :standard))])
      .to eq([true, false])
  end

  it "hands RuboCop the default config, with an entry for every cop" do
    rules = plugin.rules(context)
    config = YAML.safe_load_file(rules.value, permitted_classes: [Regexp])

    expect([rules.type, rules.config_format]).to eq(%i[path rubocop])
    expect(config.keys).to match_array(RuboCop::Cop::Registry.global.with_department(:Hanami).cops.map(&:cop_name))
  end

  it "reports the gem's name and version" do
    expect(plugin.about).to have_attributes(name: "rubocop-hanami", version: gemspec.version.to_s)
  end
end
