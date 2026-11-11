# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks that each top-level `module` and `class` in a file under `slices/<name>/` opens the
      # slice's namespace. Zeitwerk expects `slices/admin/actions/users/index.rb` to define
      # `Admin::Actions::Users::Index`. A mismatch raises at load time, often far from the file at
      # fault.
      #
      # The cop camelizes the slice's directory the way Hanami does, word by word, so `admin_panel`
      # gives `AdminPanel`, and checks only the first segment of each name. It reads the acronyms in
      # `config/app.rb`, so `inflections.acronym "TMAS"` turns `tmas_gate_counts` into `TMASGateCounts`.
      # `Inflections` adds to them, keyed by word or by whole slice name. For nested slices, the
      # innermost one counts.
      #
      # @example
      #   # slices/admin/actions/users/index.rb
      #
      #   # bad
      #   module Backoffice
      #     module Actions
      #     end
      #   end
      #
      #   # good
      #   module Admin
      #     module Actions
      #     end
      #   end
      #
      # @example Inflections: { api: API }
      #   # slices/api/action.rb
      #
      #   # good
      #   class API::Action < MyApp::Action
      #   end
      class SliceNamespace < Base
        MSG = "Files in `slices/%<slice>s` belong in the `%<namespace>s` namespace."
        SLICE = %r{(?:\A|/)slices/([^/]+)(?=/)}

        def_node_search :acronyms, "(send _ :acronym $...)"

        # Lets RuboCop's result cache drop stale results when the app's inflections change.
        def external_dependency_checksum
          path = app_config_path
          Digest::SHA1.hexdigest(File.read(path)) if File.file?(path)
        end

        def on_new_investigation
          slice = slice_name
          return unless slice && processed_source.ast

          namespace = namespace_for(slice)
          top_level_definitions.each do |definition|
            next if root_name(definition.identifier) == namespace

            add_offense(definition.identifier, message: format(MSG, slice: slice, namespace: namespace))
          end
        end

        private

        # Hanami camelizes a slice's name with its parent's inflector. Only the app's is read, so a nested
        # slice ignores acronyms set in its parent slice.
        def app_acronyms
          ast = app_config_ast
          return {} unless ast

          words = acronyms(ast).to_a.flatten.select { |arg| arg.type?(:str, :sym) }
          words.to_h { |word| [word.value.to_s.downcase, word.value.to_s] }
        end

        def app_config_ast
          path = app_config_path
          return unless File.file?(path)

          source = processed_source
          ProcessedSource.from_file(path, source.ruby_version, parser_engine: source.parser_engine).ast
        end

        def app_config_path
          File.join(config.base_dir_for_path_parameters, "config", "app.rb")
        end

        def namespace_for(slice)
          rules = app_acronyms.merge(cop_config["Inflections"] || {})
          rules.fetch(slice) { slice.split("_").map { |word| rules.fetch(word) { word.capitalize } }.join }.to_s
        end

        def root_name(const)
          const = const.namespace while const.namespace&.const_type?
          const.short_name.to_s
        end

        def slice_name
          processed_source.file_path.to_s.scan(SLICE).last&.first
        end

        def top_level_definitions
          ast = processed_source.ast
          (ast.begin_type? ? ast.children : [ast]).select { |node| node.type?(:module, :class) }
        end
      end
    end
  end
end
