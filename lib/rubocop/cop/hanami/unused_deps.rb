# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for a key in `include Deps[...]` whose accessor the class never reads. A stale
      # dependency still gets resolved, still boots its provider and still shows up as a constructor
      # argument.
      #
      # A read is a bare call or a call on `self`, the instance variable the kwargs strategy sets, or
      # `send`, `public_send`, `__send__` or `method` with a literal symbol. The cop skips a class
      # that passes `Deps` anything but literal keys, or calls `send` with a name it can't read. It
      # skips modules, since `include Deps` in a module serves whatever class includes it.
      #
      # The cop sees one file, so it flags a dependency that only a subclass reads. Disable it with a
      # comment on that key.
      #
      # @example
      #   # bad
      #   class Operations::CreateUser
      #     include Deps["repos.user_repo", "mailers.welcome"]
      #
      #     def call(input)
      #       user_repo.create(input)
      #     end
      #   end
      #
      #   # good
      #   class Operations::CreateUser
      #     include Deps["repos.user_repo"]
      #
      #     def call(input)
      #       user_repo.create(input)
      #     end
      #   end
      class UnusedDeps < Base
        include DepsKeys

        MSG = "`%<name>s` from `Deps[\"%<key>s\"]` is never used."

        def_node_matcher :dynamic_send?, "(send _ {:send :public_send :__send__} !sym ...)"
        def_node_matcher :literal_send, "(send _ {:send :public_send :__send__ :method} (sym $_) ...)"

        def on_class(node)
          arguments = deps_arguments_in(node)
          return unless checkable?(node, arguments)

          used = used_names(node)
          each_deps_key(arguments) do |key_node, name|
            next if name.nil? || used.include?(name)

            add_offense(key_node, message: format(MSG, name: name, key: key_node.value))
          end
        end

        private

        def checkable?(node, arguments)
          return false if arguments.empty? || !arguments.all? { |argument| literal?(argument) }

          node.each_descendant(:send).none? { |send| dynamic_send?(send) }
        end

        def deps_arguments_in(node)
          body = node.body
          children = body&.begin_type? ? body.children : [body]
          children.compact.filter_map { |child| deps_arguments(child) }.flatten
        end

        def literal?(argument)
          argument.str_type? || (argument.hash_type? && argument.pairs.all? { |pair| literal_alias?(pair) })
        end

        def used_names(node)
          node.each_descendant(:send, :ivar).to_set do |read|
            next read.children.first.to_s.delete_prefix("@") if read.ivar_type?

            literal_send(read)&.to_s || (read.method_name.to_s if read.receiver.nil? || read.receiver.self_type?)
          end
        end
      end
    end
  end
end
