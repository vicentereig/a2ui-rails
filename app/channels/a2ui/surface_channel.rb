# typed: strict
# frozen_string_literal: true

module A2UI
  class SurfaceChannel < ApplicationCable::Channel
    extend T::Sig

    sig { void }
    def subscribed
      surface_id = params[:surface_id]
      stream_from "a2ui:#{surface_id}"
    end

    sig { void }
    def unsubscribed
      # Cleanup when channel is unsubscribed
    end

    # Receive action from client
    sig { params(data: T::Hash[String, T.untyped]).void }
    def action(data)
      action = UserAction.new(
        name: data['action_name'],
        surface_id: data['surface_id'],
        source_id: data['source_component_id'],
        context: data['context'] || {}
      )

      manager = surface_manager
      result = manager.handle_action(
        action: action,
        business_rules: data['business_rules'] || ''
      )

      broadcast_result(data['surface_id'], result, manager)
    end

    private

    sig { returns(SurfaceManager) }
    def surface_manager
      # In a real app, this would be scoped to the user/session
      @manager ||= T.let(SurfaceManager.new, T.nilable(SurfaceManager))
      T.must(@manager)
    end

    sig { params(surface_id: String, result: T.untyped, manager: SurfaceManager).void }
    def broadcast_result(surface_id, result, manager)
      surface = manager.get(surface_id)
      return unless surface

      # Apply updates
      surface.apply_data_updates(result.data_updates) if result.data_updates.any?
      result.components.each { |c| surface.components[c.id] = c }

      # Broadcast turbo streams
      streams = result.streams.map { |stream_op| render_stream(stream_op, result.components, surface) }
      if result.data_updates.any?
        streams.unshift(render_data_stream(surface))
      end
      streams_html = streams.join("\n")

      ActionCable.server.broadcast(
        "a2ui:#{surface_id}",
        { turbo_stream: streams_html }
      )
    end

    sig do
      params(
        stream_op: StreamOp,
        components: T::Array[Component],
        surface: Surface
      ).returns(String)
    end
    def render_stream(stream_op, components, surface)
      lookup = components.to_h { |c| [c.id, c] }.merge(surface.components)
      action = stream_op.action.serialize

      content = stream_op.component_ids.map do |id|
        component = lookup[id]
        next '' unless component

        ApplicationController.render(
          Components::Renderer.for(
            component,
            surface_id: surface.id,
            components_lookup: lookup,
            data: surface.data
          )
        )
      end.join

      <<~TURBO
        <turbo-stream action="#{action}" target="#{stream_op.target}">
          <template>#{content}</template>
        </turbo-stream>
      TURBO
    end

    sig { params(surface: Surface).returns(String) }
    def render_data_stream(surface)
      content = ApplicationController.render(
        partial: 'a2ui/data',
        locals: { surface: surface }
      )

      <<~TURBO
        <turbo-stream action="replace" target="#{surface.id}-data">
          <template>#{content}</template>
        </turbo-stream>
      TURBO
    end
  end
end
