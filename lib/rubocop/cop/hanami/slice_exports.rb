# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks that every slice calls `export` with a literal array of keys, and that each key
      # passes `AllowedExports` and `ForbiddenExports`. A slice that never calls `export` lets
      # every other slice import any key from its container.
      #
      # Both settings take strings, matched exactly, and regular expressions. `ParentClasses` names
      # the superclasses that mark a class as a slice, for an app whose slices inherit from a base
      # class of its own. Set `RequireExport` to false to let a slice leave out `export` and check
      # only the keys of the slices that call it.
      #
      # @example
      #   # bad
      #   class Admin::Slice < Hanami::Slice
      #   end
      #
      #   # bad
      #   class Admin::Slice < Hanami::Slice
      #     export KEYS
      #   end
      #
      #   # good
      #   class Admin::Slice < Hanami::Slice
      #     export ["repos.queries"]
      #   end
      #
      # @example AllowedExports: ['repos.queries', !ruby/regexp /\Aoperations\./]
      #   # bad
      #   export ["repos.mutations"]
      #
      #   # good
      #   export ["repos.queries", "operations.create"]
      #
      # @example ParentClasses: ['MyApp::Slice']
      #   # bad
      #   class Admin::Slice < MyApp::Slice
      #   end
      #
      # @example RequireExport: false
      #   # good
      #   class Admin::Slice < Hanami::Slice
      #   end
      #
      # @example ForbiddenExports: ['repos.mutations']
      #   # bad
      #   export ["repos.mutations"]
      class SliceExports < Base
        MSG_FORBIDDEN = "`%<key>s` matches ForbiddenExports."
        MSG_LITERAL = "Export a literal array of strings."
        MSG_MISSING = "Call `export`; a slice without it lets other slices import every key."
        MSG_NOT_ALLOWED = "`%<key>s` matches none of AllowedExports."

        def_node_matcher :export_argument, "(send nil? :export $_)"

        def on_class(node)
          return unless slice_class?(node)

          arguments = node.each_descendant(:send).filter_map { |send| export_argument(send) }
          return add_offense(node.identifier, message: MSG_MISSING) if arguments.empty? && cop_config["RequireExport"]

          arguments.each { |argument| check(argument) }
        end

        private

        def check(argument)
          return add_offense(argument, message: MSG_LITERAL) unless argument.array_type?

          argument.each_value do |value|
            next add_offense(value, message: MSG_LITERAL) unless value.str_type?

            message = message_for(value.value)
            add_offense(value, message: format(message, key: value.value)) if message
          end
        end

        def matches?(setting, key)
          Array(cop_config[setting]).any? { |pattern| pattern.is_a?(Regexp) ? pattern.match?(key) : pattern == key }
        end

        def message_for(key)
          return MSG_FORBIDDEN if matches?("ForbiddenExports", key)

          MSG_NOT_ALLOWED if cop_config.key?("AllowedExports") && !matches?("AllowedExports", key)
        end

        def slice_class?(node)
          parent = node.parent_class
          parent&.const_type? && Array(cop_config["ParentClasses"]).include?(parent.const_name)
        end
      end
    end
  end
end
