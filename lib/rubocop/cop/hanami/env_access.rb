# frozen_string_literal: true

module RuboCop
  module Cop
    module Hanami
      # Checks for `ENV` outside settings and providers. Hanami settings give each value a name, a
      # type and a check at boot. A raw `ENV` read skips all three, and a missing variable shows up
      # at request time. Writes count too.
      #
      # @example
      #   # bad
      #   class Mailers::Welcome
      #     def from = ENV.fetch("MAIL_FROM")
      #   end
      #
      #   # good
      #   class Mailers::Welcome
      #     include Deps["settings"]
      #
      #     def from = settings.mail_from
      #   end
      class EnvAccess < Base
        MSG = "Read settings, not `ENV`."
        MSG_KEY = "Read `%<key>s` through settings, not `ENV`."

        def_node_matcher :env?, "(const {nil? cbase} :ENV)"
        def_node_matcher :env_key, "(send #env? _ (str $_) ...)"

        def on_const(node)
          return unless env?(node)

          parent = node.parent
          return add_offense(node, message: MSG) unless parent&.send_type? && parent.receiver.equal?(node)

          key = env_key(parent)
          add_offense(parent, message: key ? format(MSG_KEY, key: key) : MSG)
        end
      end
    end
  end
end
