# frozen_string_literal: true

require 'dspy'
require 'dspy/anthropic'

DSPy.configure do |c|
  c.lm = DSPy::LM.new('anthropic/claude-haiku-4-5-20251001', api_key: ENV.fetch('ANTHROPIC_API_KEY'))
end
