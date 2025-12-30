# typed: strict
# frozen_string_literal: true

module A2UI
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
