# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for `Hanami.app` in a slice. A slice should depend only on its own container and what
      # it imports. `Hanami.app` ties it to the host app, so it can't be moved, extracted or loaded
      # alone.
      #
      # When `Hanami/ContainerLookup` is on, this cop leaves a lookup such as `Hanami.app["logger"]`
      # to it, so a line isn't flagged twice. `AppNamespaces` names top-level constants that belong
      # to the host app, such as `MyApp`, to flag those as well. It is empty by default because the
      # cop can't learn the app's name from one file.
      #
      # @example
      #   # bad
      #   class Admin::Actions::Users::Index < Admin::Action
      #     def handle(request, response)
      #       Hanami.app.settings.page_size
      #     end
      #   end
      #
      #   # good
      #   class Admin::Actions::Users::Index < Admin::Action
      #     include Deps["settings"]
      #
      #     def handle(request, response)
      #       settings.page_size
      #     end
      #   end
      #
      # @example AppNamespaces: ['MyApp']
      #   # bad
      #   MyApp::Types::String
      class AppReferenceInSlice < Base
        MSG = "Don't reference `%<name>s` from a slice; use `Deps` or `import`."
        RESTRICT_ON_SEND = %i[app].freeze

        def_node_matcher :hanami_app?, "(send (const {nil? cbase} :Hanami) :app)"

        def_node_matcher :container_lookup?, <<~PATTERN
          (send {#hanami_app? (send (send #hanami_app? :slices) :[] _)} :[] str)
        PATTERN

        def on_const(node)
          return unless node.namespace.nil? || node.namespace.cbase_type?
          return unless Array(cop_config["AppNamespaces"]).include?(node.short_name.to_s)

          add_offense(node, message: format(MSG, name: node.short_name))
        end

        def on_send(node)
          return unless hanami_app?(node)
          return if left_to_container_lookup?(node)

          add_offense(node, message: format(MSG, name: "Hanami.app"))
        end

        private

        def left_to_container_lookup?(node)
          return false unless config.cop_enabled?("Hanami/ContainerLookup")

          [node.parent, node.parent&.parent&.parent].any? { |lookup| lookup && container_lookup?(lookup) }
        end
      end
    end
  end
end
