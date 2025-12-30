# typed: strict
# frozen_string_literal: true

require 'dspy'
require_relative 'signatures'

module A2UI
  # =============================================================================
  # UI GENERATOR
  # =============================================================================

  class UIGenerator < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(GenerateUI)
    end

    sig do
      params(
        request: String,
        surface_id: String,
        available_data: String
      ).returns(T.untyped)
    end
    def forward(request:, surface_id:, available_data: '{}')
      @predictor.call(
        request: request,
        surface_id: surface_id,
        available_data: available_data
      )
    end
  end

  # =============================================================================
  # UI UPDATER
  # =============================================================================

  class UIUpdater < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(UpdateUI)
    end

    sig do
      params(
        request: String,
        surface_id: String,
        current_components: T::Array[Component],
        current_data: String
      ).returns(T.untyped)
    end
    def forward(request:, surface_id:, current_components: [], current_data: '{}')
      @predictor.call(
        request: request,
        surface_id: surface_id,
        current_components: current_components,
        current_data: current_data
      )
    end
  end

  # =============================================================================
  # ACTION HANDLER
  # =============================================================================

  class ActionHandler < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(HandleAction)
    end

    sig do
      params(
        action: UserAction,
        current_data: String,
        business_rules: String
      ).returns(T.untyped)
    end
    def forward(action:, current_data: '{}', business_rules: '')
      @predictor.call(
        action: action,
        current_data: current_data,
        business_rules: business_rules
      )
    end
  end

  # =============================================================================
  # DATA VALIDATOR
  # =============================================================================

  class DataValidator < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::Predict.new(ValidateData)
    end

    sig { params(data: String, rules: String).returns(T.untyped) }
    def forward(data:, rules:)
      @predictor.call(data: data, rules: rules)
    end
  end

  # =============================================================================
  # INPUT PARSER
  # =============================================================================

  class InputParser < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::Predict.new(ParseInput)
    end

    sig do
      params(
        text: String,
        target_path: String,
        expected_schema: String
      ).returns(T.untyped)
    end
    def forward(text:, target_path:, expected_schema: '')
      @predictor.call(
        text: text,
        target_path: target_path,
        expected_schema: expected_schema
      )
    end
  end

  # =============================================================================
  # LAYOUT ADAPTER
  # =============================================================================

  class LayoutAdapter < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::Predict.new(AdaptLayout)
    end

    sig do
      params(
        components: T::Array[Component],
        root_id: String,
        screen: ScreenSize
      ).returns(T.untyped)
    end
    def forward(components:, root_id:, screen:)
      @predictor.call(
        components: components,
        root_id: root_id,
        screen: screen
      )
    end
  end

  # =============================================================================
  # SURFACE - State container for a UI surface
  # =============================================================================

  class Surface
    extend T::Sig

    sig { returns(String) }
    attr_reader :id

    sig { returns(T.nilable(String)) }
    attr_reader :root_id

    sig { returns(T::Hash[String, Component]) }
    attr_reader :components

    sig { returns(T::Hash[String, T.untyped]) }
    attr_reader :data

    sig { params(id: String).void }
    def initialize(id)
      @id = id
      @root_id = T.let(nil, T.nilable(String))
      @components = T.let({}, T::Hash[String, Component])
      @data = T.let({}, T::Hash[String, T.untyped])
    end

    sig { params(root_id: String, components: T::Array[Component]).void }
    def set_components(root_id, components)
      @root_id = root_id
      components.each { |c| @components[c.id] = c }
    end

    sig { params(updates: T::Array[DataUpdate]).void }
    def apply_data_updates(updates)
      updates.each do |update|
        @data[update.path] = entries_to_hash(update.entries)
      end
    end

    sig { params(path: String).returns(T.untyped) }
    def get_data(path)
      @data[path]
    end

    sig { returns(String) }
    def to_json
      @data.to_json
    end

    private

    sig { params(entries: T::Array[DataValue]).returns(T::Hash[String, T.untyped]) }
    def entries_to_hash(entries)
      entries.to_h do |entry|
        value = case entry
                when StringValue then entry.string
                when NumberValue then entry.number
                when BooleanValue then entry.boolean
                when ObjectValue then entries_to_hash(entry.entries)
                end
        [entry.key, value]
      end
    end
  end

  # =============================================================================
  # SURFACE MANAGER - Orchestrates surfaces with DSPy modules
  # =============================================================================

  class SurfaceManager
    extend T::Sig

    sig { void }
    def initialize
      @surfaces = T.let({}, T::Hash[String, Surface])
      @generator = T.let(UIGenerator.new, UIGenerator)
      @updater = T.let(UIUpdater.new, UIUpdater)
      @action_handler = T.let(ActionHandler.new, ActionHandler)
    end

    sig { params(surface_id: String, request: String, data: String).returns(Surface) }
    def create(surface_id:, request:, data: '{}')
      result = @generator.call(
        request: request,
        surface_id: surface_id,
        available_data: data
      )

      surface = Surface.new(surface_id)
      surface.set_components(result.root_id, result.components)
      surface.apply_data_updates(result.initial_data)

      @surfaces[surface_id] = surface
    end

    sig { params(surface_id: String, request: String).returns(T.untyped) }
    def update(surface_id:, request:)
      surface = @surfaces.fetch(surface_id)

      @updater.call(
        request: request,
        surface_id: surface_id,
        current_components: surface.components.values,
        current_data: surface.to_json
      )
    end

    sig { params(action: UserAction, business_rules: String).returns(T.untyped) }
    def handle_action(action:, business_rules: '')
      surface = @surfaces.fetch(action.surface_id)

      @action_handler.call(
        action: action,
        current_data: surface.to_json,
        business_rules: business_rules
      )
    end

    sig { params(surface_id: String).returns(T.nilable(Surface)) }
    def get(surface_id)
      @surfaces[surface_id]
    end

    sig { params(surface_id: String).void }
    def delete(surface_id)
      @surfaces.delete(surface_id)
    end
  end
end
