# typed: strict
# frozen_string_literal: true

module A2UI
  class SurfacesController < A2UI::ApplicationController
    extend T::Sig

    # POST /a2ui/surfaces
    # Create a new surface from natural language
    sig { void }
    def create
      surface = surface_manager.create(
        surface_id: params.require(:surface_id),
        request: params.require(:request),
        data: JsonData.new(json: params[:data] || '{}')
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
      surface = surface_manager.get(params[:id])

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
      surface = surface_manager.get(params[:id])
      return head :not_found unless surface

      result = surface_manager.update(
        surface_id: params[:id],
        request: params.require(:request)
      )

      surface.apply_data_updates(result.data_updates) if result.data_updates.any?
      result.components.each { |c| surface.components[c.id] = c }

      streams = result.streams.map { |stream_op| turbo_stream_for(stream_op, result.components) }
      streams.unshift(turbo_stream.replace("#{surface.id}-data", render_data(surface))) if result.data_updates.any?

      respond_to do |format|
        format.turbo_stream { render turbo_stream: streams }
        format.json { render json: result }
      end
    end

    # DELETE /a2ui/surfaces/:id
    sig { void }
    def destroy
      surface_manager.delete(params[:id])

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(params[:id]) }
        format.json { head :no_content }
      end
    end

    private

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
      surface = surface_manager.get(params[:id]) || Surface.new(params[:id])

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

    sig { params(surface: Surface).returns(String) }
    def render_data(surface)
      render_to_string(partial: 'a2ui/data', locals: { surface: surface })
    end
  end
end
