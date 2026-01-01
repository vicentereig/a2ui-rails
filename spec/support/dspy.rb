# frozen_string_literal: true

require 'dspy'

# Try to load adapters if available
begin
  require 'dspy/anthropic'
rescue LoadError
  # Anthropic adapter not installed
end

begin
  require 'dspy/openai'
rescue LoadError
  # OpenAI adapter not installed
end

RSpec.configure do |config|
  # Configure DSPy for tests with :vcr tag
  config.before(:each, :vcr) do |example|
    anthropic_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    openai_key = ENV.fetch('OPENAI_API_KEY', nil)

    # Construct cassette path from example description
    cassette_name = example.full_description.gsub(/[^a-z0-9]+/i, '_').downcase
    cassette_path = Rails.root.join("spec/fixtures/vcr_cassettes/#{cassette_name}.yml")

    if anthropic_key && !anthropic_key.empty?
      DSPy.configure do |c|
        c.lm = DSPy::LM.new('anthropic/claude-sonnet-4-20250514', api_key: anthropic_key)
      end
    elsif openai_key && !openai_key.empty?
      DSPy.configure do |c|
        c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: openai_key)
      end
    elsif File.exist?(cassette_path)
      # Cassette exists, configure with placeholder (VCR will replay)
      DSPy.configure do |c|
        c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: 'vcr-recorded')
      end
    else
      skip "Skipping LLM test: no API key (ANTHROPIC_API_KEY or OPENAI_API_KEY) and no VCR cassette at #{cassette_path}"
    end
  end
end
