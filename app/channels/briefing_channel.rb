# typed: false
# frozen_string_literal: true

class BriefingChannel < ApplicationCable::Channel
  def subscribed
    user_id = params[:user_id]

    if user_id.blank?
      reject
      return
    end

    stream_from stream_name(user_id)
  end

  def unsubscribed
    stop_all_streams
  end

  def request_briefing(data)
    user_id = params[:user_id]
    data = (data || {}).with_indifferent_access
    date_str = data[:date] || Time.zone.today.iso8601
    # Handle boolean from JSON - could be true, "true", or 1
    force_regenerate = ActiveModel::Type::Boolean.new.cast(data[:force])

    # Check for cached briefing
    unless force_regenerate
      cached = BriefingRecord.find_by(
        user_id: user_id,
        date: Date.parse(date_str),
        briefing_type: 'daily'
      )

      if cached&.generated?
        self.class.broadcast_cached(user_id, cached)
        return
      end
    end

    # Broadcast loading state
    ActionCable.server.broadcast(stream_name(user_id), {
      type: 'loading'
    })

    # Enqueue the background job
    GenerateBriefingJob.perform_later(user_id: user_id, date: date_str)
  end

  def request_editorial_briefing(data)
    user_id = params[:user_id]
    data = (data || {}).with_indifferent_access
    date_str = data[:date] || Time.zone.today.iso8601
    # Handle boolean from JSON - could be true, "true", or 1
    force_regenerate = ActiveModel::Type::Boolean.new.cast(data[:force])

    Rails.logger.info("[EditorialBriefing] date_str=#{date_str}, force=#{force_regenerate}")

    # Check for cached editorial briefing
    unless force_regenerate
      cached = BriefingRecord.find_by(
        user_id: user_id,
        date: Date.parse(date_str),
        briefing_type: 'editorial'
      )

      if cached&.generated?
        self.class.broadcast_cached_editorial(user_id, cached)
        return
      end
    end

    # Broadcast loading state
    ActionCable.server.broadcast(stream_name(user_id), {
      type: 'loading'
    })

    # Enqueue the editorial briefing job
    GenerateEditorialBriefingJob.perform_later(user_id: user_id, date: date_str)
  end

  class << self
    def broadcast_status(user_id, status)
      metrics = status.metrics.map do |m|
        {
          label: m.label,
          value: m.value,
          trend: m.trend&.serialize&.to_sym
        }
      end

      component = Briefing::StatusSummaryComponent.new(
        headline: status.headline,
        summary: status.summary,
        sentiment: status.sentiment.serialize.to_sym,
        metrics: metrics
      )
      html = render_component(component)

      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'status',
        html: html
      })
    end

    def broadcast_suggestion(user_id, suggestion)
      component = Briefing::SuggestionComponent.new(
        title: suggestion.title,
        body: suggestion.body,
        suggestion_type: suggestion.suggestion_type.serialize.to_sym
      )
      html = render_component(component)

      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'suggestion',
        html: html
      })
    end

    def broadcast_complete(user_id)
      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'complete'
      })
    end

    def broadcast_warning(user_id, message)
      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'warning',
        message: message
      })
    end

    def broadcast_error(user_id, message)
      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'error',
        message: message
      })
    end

    def broadcast_token_usage(user_id, token_usage)
      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'token_usage',
        model: token_usage[:model],
        input_tokens: token_usage[:input_tokens],
        output_tokens: token_usage[:output_tokens],
        total_tokens: token_usage[:input_tokens] + token_usage[:output_tokens]
      })
    end

    def broadcast_editorial(user_id, briefing)
      metrics = briefing.supporting_metrics.map do |m|
        {
          label: m.label,
          value: m.value,
          trend: m.trend&.serialize&.to_sym,
          context: m.context
        }
      end

      component = Briefing::EditorialComponent.new(
        headline: briefing.headline,
        insight: {
          what: briefing.insight.what,
          so_what: briefing.insight.so_what,
          now_what: briefing.insight.now_what
        },
        metrics: metrics,
        tone: briefing.tone.serialize.to_sym
      )
      html = render_component(component)

      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'editorial',
        html: html
      })
    end

    def broadcast_a2ui_editorial(user_id, surface)
      # Render the A2UI surface to HTML using the component renderer
      root_component = A2UI::Components::Renderer.render_surface(surface)

      if root_component
        html = render_component(root_component)
      else
        # Debug: Log why rendering failed
        Rails.logger.warn(
          "[A2UI] Failed to render surface #{surface.id}. " \
          "root_id=#{surface.root_id}, " \
          "component_ids=#{surface.components.keys.first(5).join(', ')}..."
        )

        # Fallback: Try to find any root-like component
        fallback_root = surface.components.values.find do |c|
          c.is_a?(A2UI::ColumnComponent) || c.is_a?(A2UI::RowComponent)
        end

        if fallback_root
          Rails.logger.info("[A2UI] Using fallback root component: #{fallback_root.id}")
          html = render_component(
            A2UI::Components::Renderer.for(
              fallback_root,
              surface_id: surface.id,
              components_lookup: surface.components,
              data: surface.data
            )
          )
        else
          html = '<div class="text-gray-500">No content generated</div>'
        end
      end

      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'editorial',
        html: html
      })
    end

    def broadcast_cached(user_id, briefing_record)
      output = briefing_record.output.deep_symbolize_keys

      # Broadcast token usage first
      broadcast_token_usage(user_id, {
        model: briefing_record.model,
        input_tokens: briefing_record.input_tokens || 0,
        output_tokens: briefing_record.output_tokens || 0
      })

      # Broadcast status from cached output
      status = output[:status]
      metrics = (status[:metrics] || []).map do |m|
        {
          label: m[:label],
          value: m[:value],
          trend: m[:trend]&.to_sym
        }
      end

      component = Briefing::StatusSummaryComponent.new(
        headline: status[:headline],
        summary: status[:summary],
        sentiment: status[:sentiment].to_sym,
        metrics: metrics
      )
      html = render_component(component)

      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'status',
        html: html,
        cached: true
      })

      # Broadcast suggestions
      (output[:suggestions] || []).each do |suggestion|
        component = Briefing::SuggestionComponent.new(
          title: suggestion[:title],
          body: suggestion[:body],
          suggestion_type: suggestion[:suggestion_type].to_sym
        )
        html = render_component(component)

        ActionCable.server.broadcast(stream_name(user_id), {
          type: 'suggestion',
          html: html
        })
      end

      # Signal completion
      broadcast_complete(user_id)
    end

    def broadcast_cached_editorial(user_id, briefing_record)
      output = briefing_record.output.deep_symbolize_keys

      # Broadcast token usage first
      broadcast_token_usage(user_id, {
        model: briefing_record.model,
        input_tokens: briefing_record.input_tokens || 0,
        output_tokens: briefing_record.output_tokens || 0
      })

      # Check if this is an A2UI surface format or legacy format
      if output[:surface_id] && output[:components]
        # A2UI surface format - reconstruct and render
        surface = reconstruct_surface(output)
        broadcast_a2ui_editorial(user_id, surface)
      else
        # Legacy format - use old ViewComponent rendering
        metrics = (output[:supporting_metrics] || []).map do |m|
          {
            label: m[:label],
            value: m[:value],
            trend: m[:trend]&.to_sym,
            context: m[:context]
          }
        end

        component = Briefing::EditorialComponent.new(
          headline: output[:headline],
          insight: output[:insight] || {},
          metrics: metrics,
          tone: (output[:tone] || 'neutral').to_sym
        )
        html = render_component(component)

        ActionCable.server.broadcast(stream_name(user_id), {
          type: 'editorial',
          html: html,
          cached: true
        })
      end

      # Signal completion
      broadcast_complete(user_id)
    end

    def reconstruct_surface(output)
      surface = A2UI::Surface.new(output[:surface_id])
      components = output[:components].map { |c| deserialize_component(c) }
      surface.set_components(output[:root_id], components)
      surface
    end

    def deserialize_component(hash)
      hash = hash.deep_symbolize_keys
      type = hash[:type]

      case type
      when 'TextComponent'
        A2UI::TextComponent.new(
          id: hash[:id],
          content: deserialize_value(hash[:content]),
          usage_hint: A2UI::TextUsageHint.deserialize(hash[:usage_hint])
        )
      when 'ColumnComponent'
        A2UI::ColumnComponent.new(
          id: hash[:id],
          children: deserialize_children(hash[:children]),
          distribution: A2UI::Distribution.deserialize(hash[:distribution] || 'start'),
          alignment: A2UI::Alignment.deserialize(hash[:alignment] || 'stretch'),
          gap: hash[:gap] || 8
        )
      when 'RowComponent'
        A2UI::RowComponent.new(
          id: hash[:id],
          children: deserialize_children(hash[:children]),
          distribution: A2UI::Distribution.deserialize(hash[:distribution] || 'start'),
          alignment: A2UI::Alignment.deserialize(hash[:alignment] || 'center'),
          gap: hash[:gap] || 8
        )
      when 'CardComponent'
        A2UI::CardComponent.new(
          id: hash[:id],
          child_id: hash[:child_id],
          title: hash[:title] || '',
          elevation: hash[:elevation] || 1
        )
      when 'DividerComponent'
        A2UI::DividerComponent.new(
          id: hash[:id],
          orientation: A2UI::Orientation.deserialize(hash[:orientation] || 'horizontal')
        )
      else
        # Unknown component type, create a text placeholder
        A2UI::TextComponent.new(
          id: hash[:id],
          content: A2UI::LiteralValue.new(value: "[Unknown: #{type}]"),
          usage_hint: A2UI::TextUsageHint::Body
        )
      end
    end

    def deserialize_value(hash)
      return A2UI::LiteralValue.new(value: '') unless hash

      hash = hash.deep_symbolize_keys
      case hash[:type]
      when 'literal'
        A2UI::LiteralValue.new(value: hash[:value] || '')
      when 'path'
        A2UI::PathReference.new(path: hash[:path] || '/')
      else
        A2UI::LiteralValue.new(value: hash[:value].to_s)
      end
    end

    def deserialize_children(hash)
      return A2UI::ExplicitChildren.new(ids: []) unless hash

      hash = hash.deep_symbolize_keys
      case hash[:type]
      when 'explicit'
        A2UI::ExplicitChildren.new(ids: hash[:ids] || [])
      when 'data_driven'
        A2UI::DataDrivenChildren.new(
          path: hash[:path] || '/',
          template_id: hash[:template_id] || ''
        )
      else
        A2UI::ExplicitChildren.new(ids: hash[:ids] || [])
      end
    end

    def stream_name(user_id)
      "briefing:#{user_id}"
    end

    private

    def render_component(component)
      ApplicationController.render(component, layout: false)
    end
  end

  private

  def stream_name(user_id)
    self.class.stream_name(user_id)
  end
end
