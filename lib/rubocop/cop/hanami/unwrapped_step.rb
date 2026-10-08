# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for a call to a method that returns a Result, in an operation's flow, that isn't
      # passed to `step`. dry-operation halts on failure only through `step`. A bare call drops the
      # `Failure` and the flow carries on as if it worked.
      #
      # With no types to go on, the cop works within one class. A method returns a Result when its
      # last expression, or a `return`, is `Success(...)` or `Failure(...)`. A flow method is one of
      # `FlowMethods` or a name the class passes to `operate_on`. The cop skips a call whose value
      # is assigned, used as a receiver or passed on. It can't see Results from injected
      # dependencies.
      #
      # @example
      #   # bad
      #   class Operations::CreateUser < App::Operation
      #     def call(input)
      #       validate(input)
      #       user_repo.create(input)
      #     end
      #
      #     private
      #
      #     def validate(input)
      #       input[:email] ? Success(input) : Failure(:no_email)
      #     end
      #   end
      #
      #   # good
      #   class Operations::CreateUser < App::Operation
      #     def call(input)
      #       attrs = step validate(input)
      #       step create(attrs)
      #     end
      #   end
      class UnwrappedStep < Base
        MSG = "`%<name>s` returns a Result; wrap it in `step`."

        def_node_matcher :result?, "(send nil? {:Success :Failure} ...)"
        def_node_search :operate_on, "(send nil? :operate_on $...)"

        def on_class(node)
          defs = node.each_descendant(:def).to_a
          results = defs.select { |defn| returns_result?(defn) }.to_set(&:method_name)
          return if results.empty?

          flows = flow_methods(node)
          defs.select { |defn| flows.include?(defn.method_name) }.each { |defn| check_flow(defn, results) }
        end

        private

        def check_flow(defn, results)
          defn.each_descendant(:send) do |send|
            next unless send.receiver.nil? && results.include?(send.method_name) && statement?(send)

            add_offense(send, message: format(MSG, name: send.method_name))
          end
        end

        def flow_methods(node)
          names = operate_on(node).flat_map { |arguments| arguments.select(&:sym_type?).map(&:value) }
          (Array(cop_config["FlowMethods"]).map(&:to_sym) + names).to_set
        end

        def returns_result?(defn)
          defn.each_descendant(:return).any? { |ret| ret.children.first && result?(ret.children.first) } ||
            tail_result?(defn.body)
        end

        def statement?(send)
          parent = send.parent
          parent.type?(:begin, :kwbegin) || (parent.type?(:def, :any_block) && parent.body.equal?(send))
        end

        def tail_result?(node)
          return result?(node) if node&.send_type?

          case node&.type
          when :begin, :kwbegin then tail_result?(node.children.last)
          when :if, :case then node.branches.any? { |branch| tail_result?(branch) }
          else false
          end
        end
      end
    end
  end
end
