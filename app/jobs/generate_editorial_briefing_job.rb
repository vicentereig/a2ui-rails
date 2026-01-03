# typed: false
# frozen_string_literal: true

require 'async'

# Generates editorial-style briefings using the What/So What/Now What framework
# This job fetches 7 days of data, detects anomalies, and produces a journalistic
# briefing that uncovers hidden patterns rather than just describing metrics.
class GenerateEditorialBriefingJob < ApplicationJob
  queue_as :default

  def perform(user_id:, date:)
    parsed_date = Date.parse(date)

    connection = connect_to_garmin
    unless connection
      BriefingChannel.broadcast_error(user_id, 'Could not connect to Garmin database')
      return
    end

    begin
      available = check_available_datasets(connection)
      warn_missing_datasets(user_id, connection, available)

      # Fetch 7-day data in parallel
      data = fetch_garmin_data_async(connection, available, parsed_date)

      # Convert DailyHealth structs to hashes for the context builder and anomaly detector
      daily_health_hashes = convert_health_to_hashes(data[:daily_health_7d])

      # Detect anomalies from the 7-day data
      anomalies = detect_anomalies_from_hashes(daily_health_hashes, data)

      # Build editorial context
      context_builder = Briefing::EditorialContextBuilder.new(
        daily_health_7d: daily_health_hashes,
        sleep_trend: data[:sleep_trend],
        activities_7d: data[:activities_7d],
        week_stats: data[:week_stats],
        performance_metrics: data[:performance_metrics],
        vo2max_trend: data[:vo2max_trend],
        training_status: data[:training_status],
        anomalies: anomalies
      )
      contexts = context_builder.build_all

      log_contexts(user_id, date, contexts)

      # Generate editorial briefing via DSPy
      generator = Briefing::EditorialBriefingGenerator.new
      result = generator.call(
        date: date,
        health_summary: contexts[:health_summary],
        activity_summary: contexts[:activity_summary],
        performance_summary: contexts[:performance_summary],
        detected_anomalies: contexts[:detected_anomalies]
      )

      token_usage = generator.token_usage
      Rails.logger.info("[TokenTracking] Editorial briefing: #{token_usage.inspect}")

      # Broadcast token usage to client
      BriefingChannel.broadcast_token_usage(user_id, token_usage)

      # Save to database
      save_briefing(
        user_id: user_id,
        date: parsed_date,
        contexts: contexts,
        result: result,
        token_usage: token_usage,
        anomalies: anomalies
      )

      # Broadcast the editorial briefing
      BriefingChannel.broadcast_editorial(user_id, result.briefing)

      # Signal completion
      BriefingChannel.broadcast_complete(user_id)
    rescue StandardError => e
      Rails.logger.error("GenerateEditorialBriefingJob error: #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
      BriefingChannel.broadcast_error(user_id, 'An error occurred while generating your briefing')
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

  def check_available_datasets(connection)
    {
      daily_health: connection.dataset_available?('daily_health'),
      activities: connection.dataset_available?('activities'),
      performance_metrics: connection.dataset_available?('performance_metrics')
    }
  end

  def warn_missing_datasets(user_id, connection, available)
    return unless connection.parquet?

    missing = available.select { |_key, value| !value }.keys
    return unless missing.any?

    BriefingChannel.broadcast_warning(
      user_id,
      "Missing Garmin data: #{missing.join(', ')}. Sync Garmin to generate these datasets."
    )
  end

  def fetch_garmin_data_async(connection, available, parsed_date)
    health_query = Garmin::Queries::DailyHealth.new(connection)
    activities_query = Garmin::Queries::Activities.new(connection)
    performance_query = Garmin::Queries::Performance.new(connection)

    results = {}

    Sync do
      barrier = Async::Barrier.new

      # Health queries - fetch 7 days of data
      if available[:daily_health]
        barrier.async { results[:daily_health_7d] = health_query.recent(days: 7, as_of: parsed_date) }
        barrier.async { results[:sleep_trend] = health_query.sleep_trend(days: 7, as_of: parsed_date) }
        barrier.async { results[:recovery_status] = health_query.recovery_status(parsed_date) }
      end

      # Activity queries - fetch 7 days of activities
      if available[:activities]
        barrier.async { results[:activities_7d] = activities_query.recent(limit: 20, as_of: parsed_date) }
        barrier.async { results[:week_stats] = activities_query.week_stats(parsed_date) }
      end

      # Performance queries
      if available[:performance_metrics]
        barrier.async { results[:performance_metrics] = performance_query.latest(as_of: parsed_date) }
        barrier.async { results[:training_status] = performance_query.training_status_summary(as_of: parsed_date) }
        barrier.async { results[:vo2max_trend] = performance_query.vo2max_trend(as_of: parsed_date) }
      end

      barrier.wait
    end

    # Set defaults
    results[:daily_health_7d] ||= []
    results[:sleep_trend] ||= nil
    results[:recovery_status] ||= nil
    results[:activities_7d] ||= []
    results[:week_stats] ||= nil
    results[:performance_metrics] ||= nil
    results[:training_status] ||= nil
    results[:vo2max_trend] ||= nil

    results
  end

  def convert_health_to_hashes(daily_health_7d)
    daily_health_7d.map do |health|
      {
        date: health.date,
        sleep_score: health.sleep_score,
        hrv_last_night: health.hrv_last_night,
        body_battery_start: health.body_battery_start,
        body_battery_end: health.body_battery_end,
        avg_stress: health.avg_stress,
        resting_hr: health.resting_hr
      }
    end
  end

  def detect_anomalies_from_hashes(daily_health_hashes, data)
    detector = Briefing::AnomalyDetector.new(
      daily_health_7d: daily_health_hashes,
      sleep_trend: data[:sleep_trend],
      vo2max_trend: data[:vo2max_trend],
      training_status: data[:training_status]&.training_status,
      training_readiness: data[:training_status]&.training_readiness,
      week_stats: data[:week_stats]
    )

    detector.detect
  end

  def log_contexts(user_id, date, contexts)
    Rails.logger.info(
      "Editorial briefing contexts for #{user_id} on #{date}:\n" \
      "health_summary:\n#{contexts[:health_summary]}\n" \
      "activity_summary:\n#{contexts[:activity_summary]}\n" \
      "performance_summary:\n#{contexts[:performance_summary]}\n" \
      "detected_anomalies:\n#{contexts[:detected_anomalies]}"
    )
  end

  def save_briefing(user_id:, date:, contexts:, result:, token_usage:, anomalies:)
    record = BriefingRecord.find_or_initialize_for(
      user_id: user_id,
      date: date,
      briefing_type: 'editorial'
    )

    record.update!(
      health_context: contexts[:health_summary],
      activity_context: contexts[:activity_summary],
      performance_context: contexts[:performance_summary],
      output: serialize_output(result, anomalies),
      model: token_usage[:model],
      input_tokens: token_usage[:input_tokens],
      output_tokens: token_usage[:output_tokens],
      generated_at: Time.current
    )

    Rails.logger.info("Saved editorial briefing #{record.id} for #{user_id} on #{date}")
    record
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to save briefing: #{e.message}")
    nil
  end

  def serialize_output(result, anomalies)
    briefing = result.briefing

    {
      headline: briefing.headline,
      insight: {
        what: briefing.insight.what,
        so_what: briefing.insight.so_what,
        now_what: briefing.insight.now_what
      },
      supporting_metrics: briefing.supporting_metrics.map do |m|
        {
          label: m.label,
          value: m.value,
          trend: m.trend&.serialize,
          context: m.context
        }
      end,
      tone: briefing.tone.serialize,
      anomalies: anomalies.map do |a|
        {
          type: a.anomaly_type.serialize,
          severity: a.severity.serialize,
          headline: a.headline,
          detail: a.detail,
          implication: a.implication
        }
      end
    }
  end
end
