# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for a container lookup by key where `include Deps[...]` would do. Each lookup hides a
      # dependency from the constructor, so a test can't pass a stub through `new` and the class
      # header no longer says what the class needs.
      #
      # The cop flags `[]` with a literal string on `Hanami.app`, on `Hanami.app.slices[...]` and on
      # any constant that ends in `Slice`. It skips a key that isn't a literal string, since the
      # message can't name it. `AllowedReceivers` names constants to skip, for an app that wraps
      # the container on purpose.
      #
      # @example
      #   # bad
      #   class Admin::Actions::Users::Show < Admin::Action
      #     def handle(request, response)
      #       user = Admin::Slice["repos.user_repo"].find(request.params[:id])
      #     end
      #   end
      #
      #   # good
      #   class Admin::Actions::Users::Show < Admin::Action
      #     include Deps["repos.user_repo"]
      #
      #     def handle(request, response)
      #       user = user_repo.find(request.params[:id])
      #     end
      #   end
      #
      # @example AllowedReceivers: ['Admin::Slice']
      #   # good
      #   Admin::Slice["repos.user_repo"]
      class ContainerLookup < Base
        MSG = "Use `include Deps[\"%<key>s\"]` instead of a container lookup."
        RESTRICT_ON_SEND = %i[[]].freeze

        def_node_matcher :hanami_app?, "(send (const {nil? cbase} :Hanami) :app)"

        def_node_matcher :container_lookup, <<~PATTERN
          (send ${(const _ :Slice) #hanami_app? (send (send #hanami_app? :slices) :[] _)} :[] (str $_))
        PATTERN

        def on_send(node)
          container_lookup(node) do |receiver, key|
            return if receiver.const_type? && Array(cop_config["AllowedReceivers"]).include?(receiver.const_name)

            add_offense(node, message: format(MSG, key: key))
          end
        end
      end
    end
  end
end
