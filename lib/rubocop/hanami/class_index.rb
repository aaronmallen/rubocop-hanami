# frozen_string_literal: true

module RuboCop
  module Hanami
    # Indexes the classes and modules defined under a project's `app`, `lib` and `slices`, so a cop can
    # follow a class to the parents and mixins it inherits from, and to the classes that inherit from
    # it, across files.
    class ClassIndex
      extend NodePattern::Macros

      GLOB = "{app,lib,slices}/**/*.rb"
      # ponytail: rescans at most once a second, so a language server may lint against a one second old
      # project. Watch files instead if that ever matters.
      TTL = 1

      # `parents` holds each superclass or mixin as written, with the lexical scopes to resolve it in.
      # `reads` is the set of names the body reads, or nil when it reads names the cop can't see.
      Definition = Struct.new(:name, :parents, :reads)

      def_node_matcher :mixin_arguments, "(send nil? {:include :prepend} $...)"

      @indexes = {}

      class << self
        # Changes whenever a file under the indexed roots is added, removed or touched.
        def checksum(root)
          Digest::SHA1.hexdigest(Dir.glob(GLOB, base: root).sort.map { |path| "#{path}#{mtime(root, path)}" }.join)
        end

        # One index per project root, shared by every file in the run. `reads` takes a class or module
        # node and returns its Definition#reads.
        def for(root, processed_source, &reads)
          index = @indexes[root] ||= new(root, processed_source, reads)
          index.refresh
          index
        end

        def mtime(root, path)
          File.mtime(File.join(root, path)).to_f
        rescue Errno::ENOENT
          nil
        end

        # The constant's full name, as Module#name would give it.
        def name_of(node)
          name = node.identifier.source
          return name.delete_prefix("::") if name.start_with?("::")

          outer = node.each_ancestor(:class, :module).first
          outer ? "#{name_of(outer)}::#{name}" : name
        end

        # The full names of the classes and modules around `node`, innermost first.
        def scopes_of(node)
          node.each_ancestor(:class, :module).map { |scope| name_of(scope) }
        end
      end

      def initialize(root, processed_source, reads)
        @root = root
        @ruby_version = processed_source.ruby_version
        @parser_engine = processed_source.parser_engine
        @reads = reads
        @files = {}
      end

      # Every definition `definition` inherits from, through superclasses and mixins, that the project
      # defines. A constant from outside the project, such as `Hanami::Action`, ends the walk.
      def ancestors(definition, seen = Set[definition.name])
        definition.parents.flat_map do |constant, scopes|
          name = resolve(constant, scopes, definition.name)
          next [] unless name && seen.add?(name)

          @definitions[name].flat_map { |parent| [parent, *ancestors(parent, seen)] }
        end
      end

      # Every definition that inherits from `name`, at any depth.
      def descendants(name, seen = Set[name])
        @children.fetch(name, []).flat_map do |child|
          seen.add?(child.name) ? [child, *descendants(child.name, seen)] : []
        end
      end

      def definition(node, reads = @reads.call(node))
        name = self.class.name_of(node)
        scopes = self.class.scopes_of(node)
        parents = mixins(node).map { |constant| [constant.source, [name, *scopes]] }
        parents.unshift([node.parent_class.source, scopes]) if node.class_type? && node.parent_class&.const_type?
        Definition.new(name, parents, reads)
      end

      # Parses only the files added or touched since the last scan.
      def refresh
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        return if @checked_at && now - @checked_at < TTL

        @checked_at = now
        @files = Dir.glob(GLOB, base: @root).to_h { |path| [path, file_entry(path)] }
        definitions = @files.values.flat_map(&:last)
        @definitions = definitions.group_by(&:name)
        @children = children_of(definitions)
      end

      # Everything whose reads count for `definition`: its ancestors, its descendants, and the ancestors
      # of those descendants, such as a mixin a subclass includes.
      def related(definition)
        family = [definition, *descendants(definition.name)]
        (family.drop(1) + family.flat_map { |member| ancestors(member) }).uniq
      end

      private

      def children_of(definitions)
        children = Hash.new { |hash, name| hash[name] = [] }
        definitions.each do |child|
          child.parents.each do |constant, scopes|
            name = resolve(constant, scopes, child.name)
            children[name] << child if name
          end
        end
        children
      end

      def file_entry(path)
        mtime = self.class.mtime(@root, path)
        cached = @files[path]
        cached&.first == mtime ? cached : [mtime, parse(path)]
      end

      def mixins(node)
        body = node.body
        children = body&.begin_type? ? body.children : [body]
        children.compact.flat_map { |child| mixin_arguments(child) || [] }.select(&:const_type?)
      end

      def parse(path)
        ast = ProcessedSource.from_file(File.join(@root, path), @ruby_version, parser_engine: @parser_engine).ast
        ast ? ast.each_node(:class, :module).map { |node| definition(node) } : []
      rescue Errno::ENOENT
        []
      end

      # Looks the constant up the way Ruby would, from the innermost scope out, skipping the class that
      # names it so `class Operation < Operation` finds the outer one.
      def resolve(constant, scopes, skip)
        candidates = [*scopes.map { |scope| "#{scope}::#{constant}" }, constant]
        candidates = [constant.delete_prefix("::")] if constant.start_with?("::")
        candidates.find { |name| name != skip && @definitions.key?(name) }
      end
    end
  end
end
