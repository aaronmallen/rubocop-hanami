# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for an action that depends on a repo or relation through `include Deps[...]`. Some
      # teams want actions to do only HTTP work and hand the rest to an operation, so persistence and
      # business rules live in one place that tests can call without a request. This cop is off by
      # default.
      #
      # `ForbiddenKeyPrefixes` match at the start of any segment of the key, so an imported key such
      # as `search.repos.index` counts too. `AllowedKeys` takes strings, matched exactly, and regular
      # expressions, for keys such as a read-only query repo.
      #
      # @example
      #   # bad
      #   class Actions::Users::Create < App::Action
      #     include Deps["repos.user_repo"]
      #
      #     def handle(request, response)
      #       user_repo.create(request.params[:user])
      #     end
      #   end
      #
      #   # good
      #   class Actions::Users::Create < App::Action
      #     include Deps["operations.create_user"]
      #
      #     def handle(request, response)
      #       create_user.call(request.params[:user])
      #     end
      #   end
      #
      # @example AllowedKeys: ['repos.user_queries']
      #   # good
      #   include Deps["repos.user_queries"]
      class PersistenceInAction < Base
        include DepsKeys

        MSG = "Call an operation instead of `%<key>s` from an action."
        RESTRICT_ON_SEND = %i[include].freeze

        def on_send(node)
          deps_arguments(node) do |arguments|
            each_deps_key(arguments) do |key_node, _name|
              add_offense(key_node, message: format(MSG, key: key_node.value)) if forbidden?(key_node.value)
            end
          end
        end

        private

        def allowed?(key)
          Array(cop_config["AllowedKeys"]).any? do |pattern|
            pattern.is_a?(Regexp) ? pattern.match?(key) : pattern == key
          end
        end

        def forbidden?(key)
          return false if allowed?(key)

          Array(cop_config["ForbiddenKeyPrefixes"]).any? do |prefix|
            key.start_with?(prefix) || key.include?(".#{prefix}")
          end
        end
      end
    end
  end
end
