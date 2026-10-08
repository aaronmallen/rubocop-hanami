# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for a key read from `request.params` in an action that declares no `params` or
      # `contract`. Without a schema, `request.params` holds raw input: strings, any keys, no
      # coercion.
      #
      # The cop reads `[]`, `fetch` and `dig` on the params of the first argument of `handle`,
      # whatever it is named. It can't see a `params` declared in a parent action, so
      # `AllowedParentClasses` names validated base classes whose subclasses it skips.
      #
      # @example
      #   # bad
      #   class Actions::Users::Show < App::Action
      #     def handle(request, response)
      #       id = request.params[:id]
      #     end
      #   end
      #
      #   # good
      #   class Actions::Users::Show < App::Action
      #     params do
      #       required(:id).filled(:integer)
      #     end
      #
      #     def handle(request, response)
      #       halt 422 unless request.params.valid?
      #
      #       id = request.params[:id]
      #     end
      #   end
      class UnvalidatedParams < Base
        MSG = "Declare `params` or `contract` before reading `request.params`."

        def_node_matcher :schema?, "{(send nil? {:params :contract} _) (block (send nil? {:params :contract}) ...)}"
        def_node_matcher :params_read?, "(send (send (lvar %1) :params) {:[] :fetch :dig} ...)"

        def on_def(node)
          request = node.arguments.first if node.method?(:handle)
          return unless request&.arg_type? && unvalidated?(node.each_ancestor(:class, :module, :sclass).first)

          node.each_descendant(:send) { |send| add_offense(send) if params_read?(send, request.name) }
        end

        private

        def allowed_parent?(scope)
          parent = scope.parent_class
          parent&.const_type? && Array(cop_config["AllowedParentClasses"]).include?(parent.const_name)
        end

        def declares_schema?(scope)
          body = scope.body
          (body&.begin_type? ? body.children : [body]).any? { |child| child && schema?(child) }
        end

        def unvalidated?(scope)
          scope&.class_type? && !allowed_parent?(scope) && !declares_schema?(scope)
        end
      end
    end
  end
end
