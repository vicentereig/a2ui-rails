# typed: strict
# frozen_string_literal: true

require 'async'

module A2UI
  class SurfaceManager
    extend T::Sig

    class << self
      extend T::Sig

      sig { params(scope: String).returns(T::Hash[String, Surface]) }
      def store_for(scope)
        @stores ||= {}
        @stores[scope] ||= {}
      end

      sig { params(scope: String).returns(SurfaceManager) }
      def for(scope:)
        new(store: store_for(scope))
      end
    end

    sig { params(store: T::Hash[String, Surface]).void }
    def initialize(store: self.class.store_for('global'))
      @surfaces = T.let(store, T::Hash[String, Surface])
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

    # Create multiple surfaces in parallel using Async.
    # Each request hash should have :surface_id, :request, and optionally :data keys.
    #
    # Example:
    #   manager.create_batch([
    #     { surface_id: 'header', request: 'Create a navigation header' },
    #     { surface_id: 'sidebar', request: 'Create a sidebar menu' },
    #     { surface_id: 'content', request: 'Create a content area', data: '{"items": []}' }
    #   ])
    sig { params(requests: T::Array[T::Hash[Symbol, String]]).returns(T::Array[Surface]) }
    def create_batch(requests)
      surfaces = T.let([], T::Array[Surface])
      mutex = Mutex.new

      Sync do
        barrier = Async::Barrier.new

        requests.each do |req|
          barrier.async do
            surface = create(
              surface_id: req.fetch(:surface_id),
              request: req.fetch(:request),
              data: req.fetch(:data, '{}')
            )
            mutex.synchronize { surfaces << surface }
          end
        end

        barrier.wait
      end

      surfaces
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
