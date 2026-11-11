# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for a relation, or the ROM container that hands them out, in `include Deps[...]`
      # outside a repo. Repos are the boundary to the database. When an action, operation or view
      # queries a relation, query logic spreads across layers and the repo stops being the one place
      # to change it.
      #
      # `RelationKeyPrefixes` names the start of a relation's key, and `ROMKeys` names the keys of
      # the ROM container.
      #
      # @example
      #   # bad
      #   class Operations::ListUsers
      #     include Deps["relations.users"]
      #
      #     def call = users.where(active: true).to_a
      #   end
      #
      #   # good
      #   class Operations::ListUsers
      #     include Deps["repos.user_repo"]
      #
      #     def call = user_repo.active
      #   end
      class RelationOutsideRepo < Base
        include DepsKeys

        MSG = "Use `%<key>s` only from a repo."
        RESTRICT_ON_SEND = %i[include].freeze

        def on_send(node)
          deps_arguments(node) do |arguments|
            each_deps_key(arguments) do |key_node, _name|
              add_offense(key_node, message: format(MSG, key: key_node.value)) if relation?(key_node.value)
            end
          end
        end

        private

        def relation?(key)
          Array(cop_config["RelationKeyPrefixes"]).any? { |prefix| key.start_with?(prefix) } ||
            Array(cop_config["ROMKeys"]).include?(key)
        end
      end
    end
  end
end
