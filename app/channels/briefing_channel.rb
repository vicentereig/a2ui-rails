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

  def request_briefing(data = {})
    user_id = params[:user_id]
    date_str = data['date'] || Time.zone.today.iso8601
    force_regenerate = data['force'] == true

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

  def request_editorial_briefing(data = {})
    user_id = params[:user_id]
    date_str = data['date'] || Time.zone.today.iso8601
    force_regenerate = data['force'] == true

    Rails.logger.info("[EditorialBriefing] data=#{data.inspect}, date_str=#{date_str}, force=#{force_regenerate}")

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

      # Build metrics for component
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

      # Signal completion
      broadcast_complete(user_id)
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
