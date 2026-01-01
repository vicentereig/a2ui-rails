# typed: strict
# frozen_string_literal: true

require 'dspy'

module Briefing
  class Error < StandardError; end
end

require_relative 'briefing/types'
require_relative 'briefing/daily_briefing'
require_relative 'briefing/context_builder'
