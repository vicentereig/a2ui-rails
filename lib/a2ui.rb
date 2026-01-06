# typed: strict
# frozen_string_literal: true

require_relative 'a2ui/version'
require_relative 'a2ui/types'
require_relative 'a2ui/type_coercion'
require_relative 'a2ui/signatures'
require_relative 'a2ui/modules'
require_relative 'a2ui/configuration'

# Load Rails engine if Rails is present
require_relative 'a2ui/engine' if defined?(Rails::Engine)
