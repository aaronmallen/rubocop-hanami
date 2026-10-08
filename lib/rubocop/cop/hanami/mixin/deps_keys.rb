# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Reads the keys of `include Deps[...]`.
      module DepsKeys
        extend NodePattern::Macros

        # The accessor name dry-auto_inject gives a plain key, from Dry::AutoInject::DependencyMap.
        NAME = /([a-z_][a-zA-Z_0-9]*)\z/

        def_node_matcher :deps_arguments, "(send nil? :include (send (const {nil? cbase} :Deps) :[] $...))"

        private

        # Yields each literal key string in `arguments`, with the name of the accessor it defines. A
        # trailing hash sets aliases: `mailer: "mailers.welcome"` defines `mailer`.
        def each_deps_key(arguments)
          arguments.each do |argument|
            if argument.str_type?
              yield argument, argument.value[NAME, 1]
            elsif argument.hash_type?
              argument.pairs.each { |pair| yield pair.value, pair.key.value.to_s if literal_alias?(pair) }
            end
          end
        end

        def literal_alias?(pair)
          pair.key.type?(:sym, :str) && pair.value.str_type?
        end
      end
    end
  end
end
