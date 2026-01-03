# typed: strict
# frozen_string_literal: true

module Briefing
  # Detects anomalies and contradictions in health/performance data
  # Anomalies are signals that contradict expectations - patterns the data
  # doesn't obviously show but that are important to surface.
  class AnomalyDetector
    extend T::Sig

    sig do
      params(
        daily_health_7d: T::Array[T::Hash[Symbol, T.untyped]],
        sleep_trend: T.nilable(Garmin::SleepTrend),
        vo2max_trend: T.nilable(Garmin::VO2MaxTrend),
        training_status: T.nilable(String),
        training_readiness: T.nilable(Integer),
        week_stats: T.nilable(Garmin::ActivityStats)
      ).void
    end
    def initialize(
      daily_health_7d:,
      sleep_trend: nil,
      vo2max_trend: nil,
      training_status: nil,
      training_readiness: nil,
      week_stats: nil
    )
      @daily_health_7d = daily_health_7d
      @sleep_trend = sleep_trend
      @vo2max_trend = vo2max_trend
      @training_status = training_status
      @training_readiness = training_readiness
      @week_stats = week_stats
    end

    sig { returns(T::Array[Anomaly]) }
    def detect
      anomalies = []

      anomalies << detect_sleep_fitness_paradox
      anomalies << detect_hrv_performance_divergence
      anomalies << detect_recovery_debt
      anomalies << detect_unproductive_training
      anomalies << detect_consistency_gap

      anomalies.compact.sort_by { |a| severity_rank(a.severity) }.reverse
    end

    private

    # Good sleep but declining fitness - classic overreaching
    sig { returns(T.nilable(Anomaly)) }
    def detect_sleep_fitness_paradox
      return nil unless @sleep_trend && @vo2max_trend

      avg_score = @sleep_trend.avg_sleep_score
      return nil unless avg_score

      good_sleep = avg_score > 80
      declining_fitness = @vo2max_trend.direction == :declining

      return nil unless good_sleep && declining_fitness

      change = @vo2max_trend.change_30d.abs

      Anomaly.new(
        anomaly_type: AnomalyType::SleepFitnessParadox,
        severity: change > 2 ? AnomalySeverity::High : AnomalySeverity::Medium,
        headline: 'Fitness declining despite excellent sleep',
        detail: "Sleep score averaging #{avg_score.round}/100 but VO2 Max dropped #{change.round(1)} over 30 days",
        implication: 'Your body is recovering but not adapting—classic overreaching pattern',
        evidence: [
          EvidenceSpan.new(
            source: DataSource::Health,
            metric: 'Sleep Score',
            value: "#{avg_score.round}/100",
            influence: 'Recovery appears adequate'
          ),
          EvidenceSpan.new(
            source: DataSource::Performance,
            metric: 'VO2 Max',
            value: "#{@vo2max_trend.current} (↓#{change.round(1)})",
            influence: 'Fitness adaptation not occurring'
          )
        ]
      )
    end

    # HRV improving but performance declining (or vice versa)
    sig { returns(T.nilable(Anomaly)) }
    def detect_hrv_performance_divergence
      return nil unless @daily_health_7d.size >= 4 && @vo2max_trend

      hrv_values = @daily_health_7d.filter_map { |d| d[:hrv_last_night] }
      return nil if hrv_values.size < 4

      half = hrv_values.size / 2
      first_half_avg = hrv_values.first(half).sum.to_f / half
      second_half_avg = hrv_values.last(half).sum.to_f / half

      hrv_improving = second_half_avg > first_half_avg * 1.05
      performance_declining = @vo2max_trend.direction == :declining

      return nil unless hrv_improving && performance_declining

      Anomaly.new(
        anomaly_type: AnomalyType::HRVPerformanceDivergence,
        severity: AnomalySeverity::Medium,
        headline: 'HRV improving but fitness declining',
        detail: "HRV trending up (#{first_half_avg.round}→#{second_half_avg.round}ms) while VO2 Max declining",
        implication: 'Autonomic recovery good but training stimulus insufficient—possible detraining',
        evidence: []
      )
    end

    # Consecutive days of negative body battery balance
    sig { returns(T.nilable(Anomaly)) }
    def detect_recovery_debt
      return nil if @daily_health_7d.size < 3

      deficit_days = @daily_health_7d.count do |day|
        start_bb = day[:body_battery_start]
        end_bb = day[:body_battery_end]
        start_bb && end_bb && end_bb < start_bb
      end

      return nil if deficit_days < 3

      Anomaly.new(
        anomaly_type: AnomalyType::RecoveryDebt,
        severity: deficit_days >= 5 ? AnomalySeverity::High : AnomalySeverity::Medium,
        headline: 'Recovery debt accumulating',
        detail: "#{deficit_days}/#{@daily_health_7d.size} days ended with lower Body Battery than started",
        implication: 'Daily energy expenditure exceeding recovery capacity',
        evidence: []
      )
    end

    # Good readiness but unproductive training status
    sig { returns(T.nilable(Anomaly)) }
    def detect_unproductive_training
      return nil unless @training_status && @training_readiness

      unproductive = @training_status.to_s.downcase.include?('unproductive')
      decent_readiness = @training_readiness > 50

      return nil unless unproductive && decent_readiness

      Anomaly.new(
        anomaly_type: AnomalyType::UnproductiveTraining,
        severity: AnomalySeverity::Medium,
        headline: 'Training not producing adaptation',
        detail: "Training status: #{@training_status} despite #{@training_readiness}% readiness",
        implication: 'Training intensity or volume may need adjustment',
        evidence: []
      )
    end

    # High variance in sleep scores indicating inconsistent schedule
    sig { returns(T.nilable(Anomaly)) }
    def detect_consistency_gap
      return nil if @daily_health_7d.size < 5

      sleep_scores = @daily_health_7d.filter_map { |d| d[:sleep_score] }
      return nil if sleep_scores.size < 5

      avg = sleep_scores.sum.to_f / sleep_scores.size
      variance = sleep_scores.sum { |s| (s - avg)**2 } / sleep_scores.size.to_f
      std_dev = Math.sqrt(variance)

      return nil if std_dev <= 15

      Anomaly.new(
        anomaly_type: AnomalyType::ConsistencyGap,
        severity: AnomalySeverity::Low,
        headline: 'Sleep quality highly variable',
        detail: "Sleep scores ranging #{sleep_scores.min}-#{sleep_scores.max} (σ=#{std_dev.round})",
        implication: 'Inconsistent sleep undermines training adaptation',
        evidence: []
      )
    end

    sig { params(severity: AnomalySeverity).returns(Integer) }
    def severity_rank(severity)
      case severity
      when AnomalySeverity::High then 3
      when AnomalySeverity::Medium then 2
      when AnomalySeverity::Low then 1
      else 0
      end
    end
  end
end
