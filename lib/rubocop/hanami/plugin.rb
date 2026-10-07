# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Hanami
    # Hands RuboCop the default configuration for every cop in the Hanami department.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-hanami",
          version: Gem.loaded_specs["rubocop-hanami"].version.to_s,
          homepage: "https://github.com/aaronmallen/rubocop-hanami",
          description: "A collection of RuboCop cops for Hanami.",
        )
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml"),
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end
    end
  end
end
