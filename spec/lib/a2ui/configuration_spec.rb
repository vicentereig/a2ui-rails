# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe A2UI::Configuration do
  after do
    A2UI.reset_configuration!
  end

  describe '#initialize' do
    it 'has default values' do
      config = A2UI::Configuration.new

      expect(config.default_model).to eq('anthropic/claude-sonnet-4-20250514')
      expect(config.cache_store).to be_nil
      expect(config.debug).to be false
      expect(config.component_prefix).to eq('a2ui')
    end
  end

  describe '.configuration' do
    it 'returns a configuration instance' do
      expect(A2UI.configuration).to be_a(A2UI::Configuration)
    end

    it 'returns the same instance on multiple calls' do
      config1 = A2UI.configuration
      config2 = A2UI.configuration

      expect(config1).to be(config2)
    end
  end

  describe '.configure' do
    it 'yields the configuration' do
      A2UI.configure do |config|
        config.default_model = 'openai/gpt-4o'
        config.debug = true
      end

      expect(A2UI.configuration.default_model).to eq('openai/gpt-4o')
      expect(A2UI.configuration.debug).to be true
    end
  end

  describe '.reset_configuration!' do
    it 'resets to default values' do
      A2UI.configure do |config|
        config.default_model = 'custom/model'
        config.debug = true
      end

      A2UI.reset_configuration!

      expect(A2UI.configuration.default_model).to eq('anthropic/claude-sonnet-4-20250514')
      expect(A2UI.configuration.debug).to be false
    end
  end
end
