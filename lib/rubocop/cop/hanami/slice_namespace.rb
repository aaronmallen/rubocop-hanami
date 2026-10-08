# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks that each top-level `module` and `class` in a file under `slices/<name>/` opens the
      # slice's namespace. Zeitwerk expects `slices/admin/actions/users/index.rb` to define
      # `Admin::Actions::Users::Index`. A mismatch raises at load time, often far from the file at
      # fault.
      #
      # The cop camelizes the slice's directory, so `admin_panel` gives `AdminPanel`, and checks only
      # the first segment of each name. Name slices that don't camelize plainly in `Inflections`. For
      # nested slices, the innermost one counts.
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

        def namespace_for(slice)
          (cop_config["Inflections"] || {}).fetch(slice) { slice.split("_").map(&:capitalize).join }.to_s
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
