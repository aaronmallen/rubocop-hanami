# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for `require` and `require_relative` in a provider file outside `prepare` and
      # `start`. A top-level `require` runs when the file loads. Inside `prepare`, it runs only when
      # the provider prepares, as the Hanami guides show.
      #
      # @example
      #   # bad
      #   require "sidekiq"
      #
      #   Hanami.app.register_provider(:sidekiq) do
      #     start do
      #       register "sidekiq", Sidekiq
      #     end
      #   end
      #
      #   # good
      #   Hanami.app.register_provider(:sidekiq) do
      #     prepare do
      #       require "sidekiq"
      #     end
      #
      #     start do
      #       register "sidekiq", Sidekiq
      #     end
      #   end
      class ProviderTopLevelRequire < Base
        MSG = "Move `%<require>s` into `prepare`."
        RESTRICT_ON_SEND = %i[require require_relative].freeze

        def on_send(node)
          return unless node.receiver.nil?

          block = node.each_ancestor(:any_block).first
          return if block && %i[prepare start].include?(block.method_name)

          add_offense(node, message: format(MSG, require: node.source))
        end
      end
    end
  end
end
