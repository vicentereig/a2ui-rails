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
    date = data['date'] || Time.zone.today.iso8601

    # Broadcast loading state
    ActionCable.server.broadcast(stream_name(user_id), {
      type: 'loading'
    })

    # Enqueue the background job
    GenerateBriefingJob.perform_later(user_id: user_id, date: date)
  end

  class << self
    def broadcast_insight(user_id, insight)
      component = Briefing::InsightBlockComponent.new(
        icon: insight.icon,
        headline: insight.headline,
        narrative: insight.narrative,
        sentiment: insight.sentiment.serialize.to_sym
      )
      html = render_component(component)

      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'insight',
        html: html
      })
    end

    def broadcast_suggestion(user_id, suggestion)
      component = Briefing::SuggestionComponent.new(
        title: suggestion.title,
        body: suggestion.body,
        icon: suggestion.icon,
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

    def broadcast_error(user_id, message)
      ActionCable.server.broadcast(stream_name(user_id), {
        type: 'error',
        message: message
      })
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
