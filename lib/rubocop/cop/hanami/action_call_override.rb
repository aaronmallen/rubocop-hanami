# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for `def call` in an action. `Hanami::Action#call(env)` is the Rack entry point. It
      # builds the request and response, runs callbacks and params validation, then calls
      # `handle`. Defining `call` replaces all of that.
      #
      # A class counts as an action when it inherits from one of `ParentClasses` or lives in a file
      # under `actions`. The cop skips a `call` that calls `super`, as a base action may wrap `call`
      # on purpose.
      #
      # @example
      #   # bad
      #   class Actions::Home::Show < App::Action
      #     def call(env)
      #       [200, {}, ["hi"]]
      #     end
      #   end
      #
      #   # good
      #   class Actions::Home::Show < App::Action
      #     def handle(request, response)
      #       response.body = "hi"
      #     end
      #   end
      class ActionCallOverride < Base
        MSG = "Define `handle` instead of `call` in an action."

        def on_def(node)
          return unless node.method?(:call) && action?(node.each_ancestor(:class, :module, :sclass).first)
          return if node.each_descendant(:super, :zsuper).any?

          add_offense(node.loc.keyword.join(node.loc.name))
        end

        private

        def action?(scope)
          return false unless scope&.class_type?
          return true if %r{(\A|/)actions/}.match?(processed_source.file_path)

          parent = scope.parent_class
          parent&.const_type? && Array(cop_config["ParentClasses"]).include?(parent.const_name)
        end
      end
    end
  end
end
