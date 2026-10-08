# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/hanami/plugin"
require_relative "rubocop/cop/hanami/mixin/deps_keys"

require_relative "rubocop/cop/hanami/app_reference_in_slice"
require_relative "rubocop/cop/hanami/container_lookup"
require_relative "rubocop/cop/hanami/persistence_in_action"
require_relative "rubocop/cop/hanami/relation_outside_repo"
require_relative "rubocop/cop/hanami/slice_exports"
