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

      # Build narrative context (pre-interpreted prose, not raw numbers)
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
      narratives = context_builder.build_all

      log_narratives(user_id, date, narratives)

      # Generate A2UI components for the editorial briefing
      surface_id = "editorial-#{user_id}-#{date}"
      generator = A2UI::EditorialUIGenerator.new
      result = generator.call(
        surface_id: surface_id,
        date: date,
        health: narratives[:health],
        activity: narratives[:activity],
        performance: narratives[:performance],
        detected_patterns: narratives[:detected_patterns]
      )

      token_usage = generator.token_usage
      Rails.logger.info("[TokenTracking] Editorial A2UI: #{token_usage.inspect}")

      # Create A2UI Surface from the generated components
      surface = A2UI::Surface.new(surface_id)
      surface.set_components(result.root_id, result.components)
      surface.apply_data_updates(result.initial_data)

      Rails.logger.info(
        "[A2UI] Surface #{surface_id} created with #{result.components.size} components, " \
        "root_id: #{result.root_id}"
      )

      # Broadcast token usage to client
      BriefingChannel.broadcast_token_usage(user_id, token_usage)

      # Save to database
      save_briefing(
        user_id: user_id,
        date: parsed_date,
        narratives: narratives,
        surface: surface,
        token_usage: token_usage,
        anomalies: anomalies
      )

      # Broadcast the A2UI surface as rendered HTML
      BriefingChannel.broadcast_a2ui_editorial(user_id, surface)

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

  def log_narratives(user_id, date, narratives)
    health = narratives[:health]
    activity = narratives[:activity]
    performance = narratives[:performance]
    patterns = narratives[:detected_patterns]

    Rails.logger.info(
      "Editorial briefing narratives for #{user_id} on #{date}:\n" \
      "Health pattern: #{health.pattern.serialize}\n" \
      "  Sleep: #{health.sleep_quality}\n" \
      "  Recovery: #{health.recovery_state}\n" \
      "  Stress: #{health.stress_context}\n" \
      "Activity pattern: #{activity.pattern.serialize}\n" \
      "  Volume: #{activity.volume_description}\n" \
      "  Intensity: #{activity.intensity_description}\n" \
      "  Consistency: #{activity.consistency_description}\n" \
      "Performance trajectory: #{performance.trajectory.serialize}\n" \
      "  Aerobic: #{performance.aerobic_state}\n" \
      "  Readiness: #{performance.training_readiness}\n" \
      "Detected patterns: #{patterns.size}"
    )
  end

  def save_briefing(user_id:, date:, narratives:, surface:, token_usage:, anomalies:)
    record = BriefingRecord.find_or_initialize_for(
      user_id: user_id,
      date: date,
      briefing_type: 'editorial'
    )

    record.update!(
      health_context: serialize_narrative(narratives[:health]),
      activity_context: serialize_narrative(narratives[:activity]),
      performance_context: serialize_narrative(narratives[:performance]),
      output: serialize_surface_output(surface, anomalies),
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

  def serialize_narrative(narrative)
    # Convert T::Struct to hash for JSON storage
    narrative.serialize
  end

  def serialize_surface_output(surface, anomalies)
    # Store A2UI surface as serialized components
    {
      surface_id: surface.id,
      root_id: surface.root_id,
      components: surface.components.values.map { |c| serialize_component(c) },
      data: surface.data,
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

  def serialize_component(component)
    # Serialize A2UI component to hash for storage
    hash = { id: component.id, type: component.class.name.demodulize }

    case component
    when A2UI::TextComponent
      hash[:content] = serialize_value(component.content)
      hash[:usage_hint] = component.usage_hint.serialize
    when A2UI::ColumnComponent
      hash[:children] = serialize_children(component.children)
      hash[:distribution] = component.distribution.serialize
      hash[:alignment] = component.alignment.serialize
      hash[:gap] = component.gap
    when A2UI::RowComponent
      hash[:children] = serialize_children(component.children)
      hash[:distribution] = component.distribution.serialize
      hash[:alignment] = component.alignment.serialize
      hash[:gap] = component.gap
    when A2UI::CardComponent
      hash[:child_id] = component.child_id
      hash[:title] = component.title
      hash[:elevation] = component.elevation
    when A2UI::DividerComponent
      hash[:orientation] = component.orientation.serialize
    end

    hash
  end

  def serialize_value(value)
    case value
    when A2UI::LiteralValue
      { type: 'literal', value: value.value }
    when A2UI::PathReference
      { type: 'path', path: value.path }
    end
  end

  def serialize_children(children)
    case children
    when A2UI::ExplicitChildren
      { type: 'explicit', ids: children.ids }
    when A2UI::DataDrivenChildren
      { type: 'data_driven', path: children.path, template_id: children.template_id }
    end
  end
end
