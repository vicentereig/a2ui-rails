# typed: strict
# frozen_string_literal: true

module A2UI
  class ActionsController < ApplicationController
    extend T::Sig

    before_action :set_surface_manager

    # POST /a2ui/actions
    # Handle user actions from components
    sig { void }
    def create
      action = UserAction.new(
        name: params.require(:action_name),
        surface_id: params.require(:surface_id),
        source_id: params.require(:source_component_id),
        context: params[:context]&.to_unsafe_h || {}
      )

      result = @manager.handle_action(
        action: action,
        business_rules: params[:business_rules] || ''
      )

      respond_to do |format|
        format.turbo_stream { render_turbo_response(result) }
        format.json { render json: result }
      end
    end

    private

    sig { void }
    def set_surface_manager
      @manager = T.let(SurfaceManager.new, SurfaceManager)
    end

    sig { params(result: T.untyped).void }
    def render_turbo_response(result)
      case result.response_type
      when ActionResponseType::Navigate
        redirect_to result.redirect_url, allow_other_host: false
      when ActionResponseType::DeleteSurface
        render turbo_stream: turbo_stream.remove(params[:surface_id])
      when ActionResponseType::UpdateUI
        streams = build_turbo_streams(result)
        render turbo_stream: streams
      else
        head :no_content
      end
    end

    sig { params(result: T.untyped).returns(T::Array[T.untyped]) }
    def build_turbo_streams(result)
      surface = @manager.get(params[:surface_id])
      return [] unless surface

      # Apply data updates
      surface.apply_data_updates(result.data_updates) if result.data_updates.any?

      # Apply component updates
      result.components.each { |c| surface.components[c.id] = c }

      # Build turbo streams
      streams = result.streams.map { |stream_op| build_stream(stream_op, result.components, surface) }
      streams.unshift(turbo_stream.replace("#{surface.id}-data", render_data(surface))) if result.data_updates.any?
      streams
    end

    sig do
      params(
        stream_op: StreamOp,
        components: T::Array[Component],
        surface: Surface
      ).returns(T.untyped)
    end
    def build_stream(stream_op, components, surface)
      lookup = components.to_h { |c| [c.id, c] }.merge(surface.components)

      content = stream_op.component_ids.map do |id|
        component = lookup[id]
        next '' unless component

        render_to_string(
          Components::Renderer.for(
            component,
            surface_id: surface.id,
            components_lookup: lookup,
            data: surface.data
          )
        )
      end.join

      case stream_op.action
      when StreamAction::Remove then turbo_stream.remove(stream_op.target)
      when StreamAction::Append then turbo_stream.append(stream_op.target, content)
      when StreamAction::Prepend then turbo_stream.prepend(stream_op.target, content)
      when StreamAction::Replace then turbo_stream.replace(stream_op.target, content)
      when StreamAction::Before then turbo_stream.before(stream_op.target, content)
      when StreamAction::After then turbo_stream.after(stream_op.target, content)
      else turbo_stream.update(stream_op.target, content)
      end
    end

    sig { params(surface: Surface).returns(String) }
    def render_data(surface)
      render_to_string(partial: 'a2ui/data', locals: { surface: surface })
    end
  end
end
