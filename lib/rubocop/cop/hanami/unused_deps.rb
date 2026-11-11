# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for a key in `include Deps[...]` whose accessor the class never reads. A stale
      # dependency still gets resolved, still boots its provider and still shows up as a constructor
      # argument.
      #
      # A read is a bare call or a call on `self`, the instance variable the kwargs strategy sets,
      # `send`, `public_send`, `__send__` or `method` with a literal symbol, or a keyword argument
      # of `initialize` read outside `super`. The cop skips a class
      # that passes `Deps` anything but literal keys, or calls `send` with a name it can't read. It
      # skips modules, since `include Deps` in a module serves whatever class includes it.
      #
      # A dependency also counts as used when a parent class, a subclass at any depth, or a mixin of
      # either reads it. The cop indexes the classes and modules under `app`, `lib` and `slices` to
      # follow them, and stops at constants the project doesn't define, such as `Hanami::Action`. It
      # skips the class if one of them calls `send` with a name it can't read.
      #
      # It still flags a dependency read somewhere it can't follow. Disable it with a comment on that
      # key, or name it in `AllowedNames` to never flag it.
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
      #
      # @example AllowedNames: [contract]
      #   # good
      #   class Operations::SaveTask < MyApp::Operation
      #     include Deps[contract: "contracts.task"]
      #   end
      class UnusedDeps < Base
        include DepsKeys

        MSG = "`%<name>s` from `Deps[\"%<key>s\"]` is never used."

        def_node_matcher :dynamic_send?, "(send _ {:send :public_send :__send__} !sym ...)"
        def_node_search :initializers, "(def :initialize ...)"
        def_node_matcher :literal_send, "(send _ {:send :public_send :__send__ :method} (sym $_) ...)"

        # Lets RuboCop's result cache drop stale results when a parent class or mixin changes.
        def external_dependency_checksum
          RuboCop::Hanami::ClassIndex.checksum(config.base_dir_for_path_parameters)
        end

        def on_class(node)
          arguments = deps_arguments_in(node)
          return unless checkable?(node, arguments)

          unused = unused_keys(arguments, used_names(node) + Array(cop_config["AllowedNames"]))
          return if unused.empty?

          related = related_reads(node)
          return unless related

          unused.each do |key_node, name|
            add_offense(key_node, message: format(MSG, name: name, key: key_node.value)) unless related.include?(name)
          end
        end

        private

        def checkable?(node, arguments)
          return false if arguments.empty? || !arguments.all? { |argument| literal?(argument) }

          node.each_descendant(:send).none? { |send| dynamic_send?(send) }
        end

        def class_index
          RuboCop::Hanami::ClassIndex.for(config.base_dir_for_path_parameters, processed_source) do |node|
            used_names(node) if node.each_descendant(:send).none? { |send| dynamic_send?(send) }
          end
        end

        def deps_arguments_in(node)
          body = node.body
          children = body&.begin_type? ? body.children : [body]
          children.compact.filter_map { |child| deps_arguments(child) }.flatten
        end

        # Passing a keyword on to `super` doesn't count, since the kwargs strategy needs that to inject it.
        def keyword_reads(method)
          keywords = method.arguments.select { |argument| argument.type?(:kwarg, :kwoptarg) }.map(&:name)
          reads = method.each_descendant(:lvar).select { |lvar| lvar.each_ancestor(:super).none? }.map(&:name)
          (keywords & reads).map(&:to_s)
        end

        def literal?(argument)
          argument.str_type? || (argument.hash_type? && argument.pairs.all? { |pair| literal_alias?(pair) })
        end

        def read_name(read)
          return read.children.first.to_s.delete_prefix("@") if read.ivar_type?

          literal_send(read)&.to_s || (read.method_name.to_s if read.receiver.nil? || read.receiver.self_type?)
        end

        # The names every parent, child and mixin of `node` reads, or nil when one of them reads names
        # the cop can't see.
        def related_reads(node)
          index = class_index
          reads = index.related(index.definition(node, nil)).map(&:reads)
          reads.sum(Set[]) if reads.all?
        end

        def unused_keys(arguments, used)
          unused = []
          each_deps_key(arguments) do |key_node, name|
            unused << [key_node, name] unless name.nil? || used.include?(name)
          end
          unused
        end

        def used_names(node)
          reads = node.each_descendant(:send, :ivar).to_set { |read| read_name(read) }
          reads.merge(initializers(node).flat_map { |method| keyword_reads(method) })
        end
      end
    end
  end
end
