# typed: strict
# frozen_string_literal: true

module A2UI
  class Engine < ::Rails::Engine
    extend T::Sig

    isolate_namespace A2UI

    # Configure inflector for A2UI acronym
    initializer 'a2ui.inflections' do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym 'A2UI'
      end
    end

    # Add ViewComponent paths
    initializer 'a2ui.view_components' do
      if defined?(ViewComponent::Base)
        # Ensure A2UI components are found
        ActiveSupport.on_load(:view_component) do
          # Component paths are automatically handled by the engine
        end
      end
    end

    # Configure autoload paths for lib/a2ui
    initializer 'a2ui.autoload', before: :set_autoload_paths do |app|
      app.config.autoload_paths << root.join('lib').to_s
    end

    # Add engine assets to asset pipeline
    initializer 'a2ui.assets' do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[a2ui.css a2ui.js]
      end
    end

    # Configure generators
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
  end
end
