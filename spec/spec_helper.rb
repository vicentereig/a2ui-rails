# frozen_string_literal: true

require 'bundler/setup'
require 'vcr'
require 'webmock/rspec'
require 'dspy'

# Load A2UI
require_relative '../lib/a2ui/signatures'
require_relative '../lib/a2ui/modules'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<OPENAI_API_KEY>') { ENV['OPENAI_API_KEY'] }
  config.filter_sensitive_data('<ANTHROPIC_API_KEY>') { ENV['ANTHROPIC_API_KEY'] }
  config.filter_sensitive_data('<GEMINI_API_KEY>') { ENV['GEMINI_API_KEY'] }

  # Match requests by method, URI, and body
  config.default_cassette_options = {
    match_requests_on: [:method, :uri, :body],
    record: :new_episodes
  }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.order = :random
  Kernel.srand config.seed
end
