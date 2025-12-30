# typed: strict
# frozen_string_literal: true

module A2UI
  class SurfacesController < ApplicationController
    extend T::Sig

    before_action :set_surface_manager

    # POST /a2ui/surfaces
    # Create a new surface from natural language
    sig { void }
    def create
      surface = @manager.create(
        surface_id: params.require(:surface_id),
        request: params.require(:request),
        data: params[:data] || '{}'
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            surface.id,
            partial: 'a2ui/surface',
            locals: { surface: surface }
          )
        end
        format.json { render json: surface_json(surface) }
      end
    end

    # GET /a2ui/surfaces/:id
    sig { void }
    def show
      surface = @manager.get(params[:id])

      if surface
        respond_to do |format|
          format.html { render partial: 'a2ui/surface', locals: { surface: surface } }
          format.json { render json: surface_json(surface) }
        end
      else
        head :not_found
      end
    end

    # PATCH /a2ui/surfaces/:id
    # Update an existing surface
    sig { void }
    def update
      result = @manager.update(
        surface_id: params[:id],
        request: params.require(:request)
      )

      streams = result.streams.map do |stream_op|
        turbo_stream_for(stream_op, result.components)
      end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: streams }
        format.json { render json: result }
      end
    end

    # DELETE /a2ui/surfaces/:id
    sig { void }
    def destroy
      @manager.delete(params[:id])

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(params[:id]) }
        format.json { head :no_content }
      end
    end

    private

    sig { void }
    def set_surface_manager
      @manager = T.let(
        session[:a2ui_manager] ||= SurfaceManager.new,
        SurfaceManager
      )
    end

    sig { params(surface: Surface).returns(T::Hash[Symbol, T.untyped]) }
    def surface_json(surface)
      {
        id: surface.id,
        root_id: surface.root_id,
        components: surface.components.values.map { |c| component_json(c) },
        data: surface.data
      }
    end

    sig { params(component: Component).returns(T::Hash[Symbol, T.untyped]) }
    def component_json(component)
      { id: component.id, type: component.class.name }
    end

    sig do
      params(
        stream_op: StreamOp,
        components: T::Array[Component]
      ).returns(T.untyped)
    end
    def turbo_stream_for(stream_op, components)
      case stream_op.action
      when StreamAction::Remove
        turbo_stream.remove(stream_op.target)
      when StreamAction::Append
        turbo_stream.append(stream_op.target, render_components(stream_op, components))
      when StreamAction::Prepend
        turbo_stream.prepend(stream_op.target, render_components(stream_op, components))
      when StreamAction::Replace
        turbo_stream.replace(stream_op.target, render_components(stream_op, components))
      when StreamAction::Update
        turbo_stream.update(stream_op.target, render_components(stream_op, components))
      when StreamAction::Before
        turbo_stream.before(stream_op.target, render_components(stream_op, components))
      when StreamAction::After
        turbo_stream.after(stream_op.target, render_components(stream_op, components))
      else
        turbo_stream.update(stream_op.target, render_components(stream_op, components))
      end
    end

    sig { params(stream_op: StreamOp, components: T::Array[Component]).returns(String) }
    def render_components(stream_op, components)
      lookup = components.to_h { |c| [c.id, c] }
      surface = @manager.get(stream_op.target) || Surface.new(stream_op.target)

      stream_op.component_ids.map do |id|
        component = lookup[id]
        next '' unless component

        render_to_string(
          Components::Renderer.for(
            component,
            surface_id: surface.id,
            components_lookup: lookup.merge(surface.components),
            data: surface.data
          )
        )
      end.join
    end
  end
end
