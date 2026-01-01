# typed: false
# frozen_string_literal: true

class GenerateBriefingJob < ApplicationJob
  queue_as :default

  def perform(user_id:, date:)
    parsed_date = Date.parse(date)

    # Load Garmin data
    connection = connect_to_garmin
    unless connection
      BriefingChannel.broadcast_error(user_id, 'Could not connect to Garmin database')
      return
    end

    begin
      # Fetch data
      health_query = Garmin::Queries::DailyHealth.new(connection)
      activities_query = Garmin::Queries::Activities.new(connection)
      performance_query = Garmin::Queries::Performance.new(connection)

      daily_health = health_query.for_date(parsed_date)
      sleep_trend = health_query.sleep_trend(days: 7)
      recovery_status = health_query.recovery_status(parsed_date)

      recent_activities = activities_query.recent(limit: 5)
      week_stats = activities_query.week_stats(parsed_date)

      performance_metrics = performance_query.latest
      training_load = performance_query.training_load_status
      vo2max_trend = performance_query.vo2max_trend
      race_predictions = performance_query.race_predictions

      # Build context
      context_builder = Briefing::ContextBuilder.new(
        daily_health: daily_health,
        sleep_trend: sleep_trend,
        recovery_status: recovery_status,
        recent_activities: recent_activities,
        week_stats: week_stats,
        performance_metrics: performance_metrics,
        training_load: training_load,
        vo2max_trend: vo2max_trend,
        race_predictions: race_predictions
      )
      contexts = context_builder.build_all

      # Generate briefing via DSPy
      generator = Briefing::DailyBriefingGenerator.new
      result = generator.call(
        user_name: fetch_user_name(user_id),
        date: date,
        health_context: contexts[:health_context],
        activity_context: contexts[:activity_context],
        performance_context: contexts[:performance_context]
      )

      # Broadcast insights
      result.insights.each do |insight|
        BriefingChannel.broadcast_insight(user_id, insight)
      end

      # Broadcast suggestions
      result.suggestions.each do |suggestion|
        BriefingChannel.broadcast_suggestion(user_id, suggestion)
      end

      # Signal completion
      BriefingChannel.broadcast_complete(user_id)
    rescue StandardError => e
      Rails.logger.error("GenerateBriefingJob error: #{e.class}: #{e.message}")
      BriefingChannel.broadcast_error(user_id, "An error occurred while generating your briefing")
    ensure
      connection&.close
    end
  end

  private

  def connect_to_garmin
    path = ENV['GARMIN_DATA_PATH'] || ENV['GARMIN_DB_PATH'] || Garmin::Connection.default_path
    return nil unless path && (File.directory?(path) || File.exist?(path))

    Garmin::Connection.new(path)
  rescue Garmin::ConnectionError => e
    Rails.logger.error("Garmin connection error: #{e.message}")
    nil
  end

  def fetch_user_name(user_id)
    # For demo, just use a default name
    # In production, this would look up the user's name
    'Runner'
  end
end
