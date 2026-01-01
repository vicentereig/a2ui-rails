# typed: strict
# frozen_string_literal: true

module Garmin
  # Activity model
  class Activity < T::Struct
    const :activity_id, Integer
    const :activity_name, T.nilable(String)
    const :activity_type, T.nilable(String)
    const :start_time_local, T.nilable(Time)
    const :duration_sec, T.nilable(Float)
    const :distance_m, T.nilable(Float)
    const :calories, T.nilable(Integer)
    const :avg_hr, T.nilable(Integer)
    const :max_hr, T.nilable(Integer)
    const :avg_speed, T.nilable(Float)
    const :elevation_gain, T.nilable(Float)
    const :avg_cadence, T.nilable(Float)
    const :location_name, T.nilable(String)
  end

  # Activity stats aggregate
  class ActivityStats < T::Struct
    const :total_distance_m, Float
    const :total_duration_sec, Float
    const :activity_count, Integer
    const :avg_pace_per_km, Float # minutes per km
  end

  # Daily health model
  class DailyHealth < T::Struct
    const :date, Date
    const :steps, T.nilable(Integer)
    const :step_goal, T.nilable(Integer)
    const :total_calories, T.nilable(Integer)
    const :active_calories, T.nilable(Integer)
    const :bmr_calories, T.nilable(Integer)
    const :resting_hr, T.nilable(Integer)
    const :sleep_seconds, T.nilable(Integer)
    const :deep_sleep_seconds, T.nilable(Integer)
    const :light_sleep_seconds, T.nilable(Integer)
    const :rem_sleep_seconds, T.nilable(Integer)
    const :sleep_score, T.nilable(Integer)
    const :avg_stress, T.nilable(Integer)
    const :max_stress, T.nilable(Integer)
    const :body_battery_start, T.nilable(Integer)
    const :body_battery_end, T.nilable(Integer)
    const :hrv_weekly_avg, T.nilable(Integer)
    const :hrv_last_night, T.nilable(Integer)
    const :hrv_status, T.nilable(String)
    const :avg_respiration, T.nilable(Float)
    const :avg_spo2, T.nilable(Integer)
    const :lowest_spo2, T.nilable(Integer)
    const :hydration_ml, T.nilable(Integer)
    const :moderate_intensity_min, T.nilable(Integer)
    const :vigorous_intensity_min, T.nilable(Integer)
  end

  # Sleep trend analysis
  class SleepTrend < T::Struct
    const :avg_sleep_score, Float
    const :avg_sleep_hours, Float
    const :trend_direction, Symbol # :improving, :stable, :declining
    const :consecutive_good_nights, Integer
  end

  # Recovery status
  class RecoveryStatus < T::Struct
    const :body_battery, Integer
    const :hrv_status, String
    const :resting_hr, Integer
    const :stress_level, Integer
    const :readiness, Symbol # :ready, :moderate, :low
  end

  # Baseline comparison
  class BaselineComparison < T::Struct
    const :sleep_vs_baseline, Float
    const :steps_vs_baseline, Float
    const :stress_vs_baseline, Float
  end

  # Performance metrics model
  class PerformanceMetrics < T::Struct
    const :date, Date
    const :vo2max, T.nilable(Float)
    const :fitness_age, T.nilable(Integer)
    const :training_readiness, T.nilable(Integer)
    const :training_status, T.nilable(String)
    const :lactate_threshold_hr, T.nilable(Integer)
    const :lactate_threshold_pace, T.nilable(Float)
    const :race_5k_sec, T.nilable(Integer)
    const :race_10k_sec, T.nilable(Integer)
    const :race_half_sec, T.nilable(Integer)
    const :race_marathon_sec, T.nilable(Integer)
    const :endurance_score, T.nilable(Integer)
    const :hill_score, T.nilable(Integer)
  end

  # Training status summary
  class TrainingStatusSummary < T::Struct
    const :training_status, String
    const :training_readiness, Integer
    const :endurance_score, T.nilable(Integer)
    const :hill_score, T.nilable(Integer)
  end

  # VO2 max trend
  class VO2MaxTrend < T::Struct
    const :current, Float
    const :change_30d, Float
    const :direction, Symbol # :improving, :stable, :declining
  end

  # Race predictions
  class RacePredictions < T::Struct
    const :five_k, String
    const :ten_k, String
    const :half_marathon, String
    const :marathon, String
  end

  # Training readiness
  class TrainingReadiness < T::Struct
    const :score, Integer
    const :level, String
    const :recommendation, String
  end
end
