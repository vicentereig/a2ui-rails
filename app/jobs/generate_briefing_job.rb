# typed: false
# frozen_string_literal: true

require 'async'

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
      available = {
        daily_health: connection.dataset_available?('daily_health'),
        activities: connection.dataset_available?('activities'),
        performance_metrics: connection.dataset_available?('performance_metrics')
      }

      if connection.parquet?
        missing = available.select { |_key, value| !value }.keys
        if missing.any?
          BriefingChannel.broadcast_warning(
            user_id,
            "Missing Garmin data: #{missing.join(', ')}. Sync Garmin to generate these datasets."
          )
        end
      end

      # Fetch all data in parallel using Async
      data = fetch_garmin_data_async(connection, available, parsed_date)

      daily_health = data[:daily_health]
      sleep_trend = data[:sleep_trend]
      recovery_status = data[:recovery_status]
      recent_activities = data[:recent_activities]
      week_stats = data[:week_stats]
      performance_metrics = data[:performance_metrics]
      training_load = data[:training_load]
      vo2max_trend = data[:vo2max_trend]
      race_predictions = data[:race_predictions]

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
      Rails.logger.info(
        "Briefing contexts for #{user_id} on #{date}:\n" \
        "health_context:\n#{contexts[:health_context]}\n" \
        "activity_context:\n#{contexts[:activity_context]}\n" \
        "performance_context:\n#{contexts[:performance_context]}"
      )

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

  def fetch_garmin_data_async(connection, available, parsed_date)
    health_query = Garmin::Queries::DailyHealth.new(connection)
    activities_query = Garmin::Queries::Activities.new(connection)
    performance_query = Garmin::Queries::Performance.new(connection)

    results = {}

    Sync do
      barrier = Async::Barrier.new

      # Health queries (3 parallel)
      if available[:daily_health]
        barrier.async { results[:daily_health] = health_query.for_date(parsed_date) }
        barrier.async { results[:sleep_trend] = health_query.sleep_trend(days: 7) }
        barrier.async { results[:recovery_status] = health_query.recovery_status(parsed_date) }
      end

      # Activity queries (2 parallel)
      if available[:activities]
        barrier.async { results[:recent_activities] = activities_query.recent(limit: 5) }
        barrier.async { results[:week_stats] = activities_query.week_stats(parsed_date) }
      end

      # Performance queries (4 parallel)
      if available[:performance_metrics]
        barrier.async { results[:performance_metrics] = performance_query.latest }
        barrier.async { results[:training_load] = performance_query.training_load_status }
        barrier.async { results[:vo2max_trend] = performance_query.vo2max_trend }
        barrier.async { results[:race_predictions] = performance_query.race_predictions }
      end

      barrier.wait
    end

    # Set defaults for unavailable data
    results[:daily_health] ||= nil
    results[:sleep_trend] ||= nil
    results[:recovery_status] ||= nil
    results[:recent_activities] ||= []
    results[:week_stats] ||= nil
    results[:performance_metrics] ||= nil
    results[:training_load] ||= nil
    results[:vo2max_trend] ||= nil
    results[:race_predictions] ||= nil

    results
  end
end
