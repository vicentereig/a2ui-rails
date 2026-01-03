# typed: strict
# frozen_string_literal: true

require 'dspy'
require_relative 'types'

require_relative 'signatures/generate_ui'
require_relative 'signatures/update_ui'
require_relative 'signatures/handle_action'
require_relative 'signatures/validate_data'
require_relative 'signatures/parse_input'
require_relative 'signatures/adapt_layout'

# EditorialUI depends on Briefing types
# Require the main briefing module to ensure proper load order
require_relative '../briefing'
require_relative 'signatures/editorial_ui'
