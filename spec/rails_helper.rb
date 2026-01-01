# frozen_string_literal: true

require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Load Garmin module
require_relative '../lib/garmin'

# Load Briefing module (DSPy pipeline)
require_relative '../lib/briefing'

# Avoid double-defining :connection when RSpec mixes connection + channel behaviors.
require 'action_cable/test_helper'
require 'action_cable/channel/test_case'

channel_behavior = ActionCable::Channel::TestCase::Behavior
if channel_behavior.instance_variable_defined?(:@_included_block)
  channel_behavior.instance_variable_set(:@_included_block, proc do
    class_attribute :_channel_class

    unless method_defined?(:connection)
      attr_reader :connection, :subscription
    else
      attr_reader :subscription unless method_defined?(:subscription)
    end

    ActiveSupport.run_load_hooks(:action_cable_channel_test_case, self)
  end)
end

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'view_component/test_helpers'

# Load support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Use test queue adapter for ActiveJob
  config.before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  # ViewComponent test helpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  # Time helpers for travel_to
  config.include ActiveSupport::Testing::TimeHelpers
end
