# typed: strict
# frozen_string_literal: true

require 'async'

module A2UI
  class BatchRequest < T::Struct
    const :surface_id, String
    const :request, String
    const :data, T::Struct
    const :actions, ActionSchemas, default: {}
  end

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

    # Create a surface with typed data and action schemas.
    #
    # Example:
    #   manager.create(
    #     surface_id: 'booking',
    #     request: 'Create a booking form',
    #     data: BookingData.new(guests: 2),
    #     actions: {
    #       submit: SubmitContext,
    #       cancel: CancelContext
    #     }
    #   )
    sig do
      params(
        surface_id: String,
        request: String,
        data: T::Struct,
        actions: ActionSchemas
      ).returns(Surface)
    end
    def create(surface_id:, request:, data:, actions: {})
      result = @generator.call(
        request: request,
        surface_id: surface_id,
        available_data: data.serialize.to_json
      )

      surface = Surface.new(surface_id, action_schemas: actions)
      surface.set_components(result.root_id, result.components)
      surface.apply_data_updates(result.initial_data)

      @surfaces[surface_id] = surface
    end

    # Create multiple surfaces in parallel using Async.
    #
    # Example:
    #   manager.create_batch([
    #     BatchRequest.new(surface_id: 'header', request: 'Create a header', data: HeaderData.new),
    #     BatchRequest.new(surface_id: 'sidebar', request: 'Create a sidebar', data: SidebarData.new),
    #   ])
    sig { params(requests: T::Array[BatchRequest]).returns(T::Array[Surface]) }
    def create_batch(requests)
      surfaces = T.let([], T::Array[Surface])
      mutex = Mutex.new

      Sync do
        barrier = Async::Barrier.new

        requests.each do |req|
          barrier.async do
            surface = create(
              surface_id: req.surface_id,
              request: req.request,
              data: req.data,
              actions: req.actions
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

    # Handle a user action, coercing the raw context to the registered type.
    #
    # If the surface has a registered schema for the action, the raw context
    # hash is coerced to the typed struct before being passed to the handler.
    sig { params(action: UserAction, business_rules: String).returns(T.untyped) }
    def handle_action(action:, business_rules: '')
      surface = @surfaces.fetch(action.surface_id)

      # Coerce raw context to typed struct if schema is registered
      typed_context = if surface.action_schemas.key?(action.name.to_sym)
                        surface.coerce_context(action.name, action.context)
                      else
                        action.context
                      end

      # Create action with coerced context for the handler
      typed_action = UserAction.new(
        name: action.name,
        surface_id: action.surface_id,
        source_id: action.source_id,
        context: typed_context.is_a?(T::Struct) ? typed_context.serialize : typed_context
      )

      @action_handler.call(
        action: typed_action,
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
