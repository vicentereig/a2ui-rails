# typed: false
# frozen_string_literal: true

class GenerateWeeklyBriefingJob < ApplicationJob
  queue_as :default

  # Generate a weekly briefing from existing daily briefings
  # @param user_id [String] User identifier
  # @param week_start [String] Start of week (YYYY-MM-DD), defaults to Monday
  def perform(user_id:, week_start:)
    start_date = Date.parse(week_start)
    end_date = start_date + 6.days

    # Fetch existing daily briefings for this week
    daily_records = BriefingRecord.daily
                                  .for_user(user_id)
                                  .where(date: start_date..end_date)
                                  .where.not(generated_at: nil)
                                  .order(:date)

    if daily_records.empty?
      BriefingChannel.broadcast_error(
        user_id,
        'No daily briefings found for this week. Generate some daily briefings first.'
      )
      return
    end

    # Build summaries from existing dailies
    daily_summaries = Briefing::WeeklyBriefingGenerator.build_daily_summaries(daily_records)

    # Generate briefing via DSPy
    # Token tracking happens inside the module via around callback
    generator = Briefing::WeeklyBriefingGenerator.new
    result = generator.call(
      user_name: fetch_user_name(user_id),
      week_start: start_date.iso8601,
      week_end: end_date.iso8601,
      daily_summaries: daily_summaries
    )

    # Get token usage from the module
    token_usage = generator.token_usage
    Rails.logger.info("[TokenTracking] Weekly usage: #{token_usage.inspect}")
    BriefingChannel.broadcast_token_usage(user_id, token_usage)

    # Save weekly briefing with parent-child relationships
    save_weekly_briefing(
      user_id: user_id,
      week_start: start_date,
      daily_records: daily_records,
      result: result,
      token_usage: token_usage
    )

    # Broadcast results (reuse daily channel for now)
    broadcast_weekly_results(user_id, result, daily_records.count, start_date..end_date)

    BriefingChannel.broadcast_complete(user_id)
  rescue StandardError => e
    Rails.logger.error("GenerateWeeklyBriefingJob error: #{e.class}: #{e.message}")
    BriefingChannel.broadcast_error(user_id, 'An error occurred while generating your weekly briefing')
  end

  private

  def fetch_user_name(user_id)
    'Runner'
  end

  def save_weekly_briefing(user_id:, week_start:, daily_records:, result:, token_usage:)
    record = BriefingRecord.find_or_initialize_for(
      user_id: user_id,
      date: week_start,
      briefing_type: 'weekly'
    )

    record.update!(
      output: serialize_weekly_output(result),
      model: token_usage[:model],
      input_tokens: token_usage[:input_tokens],
      output_tokens: token_usage[:output_tokens],
      generated_at: Time.current
    )

    # Link daily briefings as children
    daily_records.each do |daily|
      daily.update!(parent: record)
    end

    Rails.logger.info("Saved weekly briefing #{record.id} for #{user_id}, week of #{week_start}")
    record
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to save weekly briefing: #{e.message}")
    nil
  end

  def serialize_weekly_output(result)
    {
      week_range: result.week_range,
      status: {
        headline: result.status.headline,
        summary: result.status.summary,
        sentiment: result.status.sentiment.serialize,
        trends: result.status.trends.map do |t|
          {
            metric: t.metric,
            direction: t.direction.serialize,
            summary: t.summary
          }
        end
      },
      suggestions: result.suggestions.map do |s|
        {
          title: s.title,
          body: s.body,
          priority: s.priority
        }
      end
    }
  end

  def broadcast_weekly_results(user_id, result, days_count, date_range)
    # Create a status summary compatible with the daily channel
    # In future, we'd have dedicated weekly components
    status = Briefing::StatusSummary.new(
      headline: result.status.headline,
      summary: "#{result.week_range}: #{result.status.summary}",
      sentiment: result.status.sentiment,
      metrics: result.status.trends.first(3).map do |t|
        Briefing::MetricItem.new(
          label: t.metric,
          value: t.direction.serialize,
          trend: t.direction
        )
      end
    )

    BriefingChannel.broadcast_status(user_id, status)

    # Broadcast suggestions
    result.suggestions.each do |suggestion|
      sugg = Briefing::Suggestion.new(
        title: suggestion.title,
        body: suggestion.body,
        suggestion_type: Briefing::SuggestionType::General
      )
      BriefingChannel.broadcast_suggestion(user_id, sugg)
    end

    # Add info about coverage
    if days_count < 7
      BriefingChannel.broadcast_warning(
        user_id,
        "Weekly summary based on #{days_count}/7 days. Generate missing daily briefings for more complete insights."
      )
    end
  end
end
