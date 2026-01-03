# typed: strict
# frozen_string_literal: true

module Briefing
  # Data source category for evidence tracking
  class DataSource < T::Enum
    enums do
      Health = new('health')
      Activity = new('activity')
      Performance = new('performance')
    end
  end

  # Evidence span - tracks which data influenced a decision
  class EvidenceSpan < T::Struct
    const :source, DataSource, description: 'Data source category (health, activity, performance)'
    const :metric, String, description: 'Specific metric referenced (e.g., "HRV", "Sleep duration")'
    const :value, String, description: 'The actual value observed (e.g., "52ms", "5.2h")'
    const :influence, String, description: 'How this data influenced the insight (1 sentence)'
  end

  # Sentiment for status
  class Sentiment < T::Enum
    enums do
      Positive = new('positive')
      Neutral = new('neutral')
      Warning = new('warning')
    end
  end

  # Type of suggestion
  class SuggestionType < T::Enum
    enums do
      General = new('general')
      Recovery = new('recovery')
      Intensity = new('intensity')
    end
  end

  # Trend direction for metrics
  class TrendDirection < T::Enum
    enums do
      Up = new('up')
      Down = new('down')
      Stable = new('stable')
    end
  end

  # A single metric item
  class MetricItem < T::Struct
    const :label, String, description: 'Short label (e.g., "Sleep", "HRV")'
    const :value, String, description: 'Value with unit (e.g., "7.5h", "52ms")'
    const :trend, T.nilable(TrendDirection), default: nil
  end

  # Consolidated status summary - one block for all insights
  class StatusSummary < T::Struct
    const :headline, String, description: 'Pithy headline (3-5 words)'
    const :metrics, T::Array[MetricItem], default: [], description: 'Top 3 metrics to display'
    const :summary, String, description: 'One sentence interpreting all data holistically'
    const :sentiment, Sentiment, description: 'Overall sentiment'
    const :evidence, T::Array[EvidenceSpan], default: [], description: 'Data points that influenced this status'
  end

  # A suggestion or recommendation
  class Suggestion < T::Struct
    const :title, String, description: 'Pithy action title (3-5 words)'
    const :body, String, description: 'One sentence with specific action'
    const :suggestion_type, SuggestionType, description: 'Category of suggestion'
    const :evidence, T::Array[EvidenceSpan], default: [], description: 'Data points that led to this suggestion'
  end

  # Legacy InsightBlock for backward compatibility
  class InsightBlock < T::Struct
    const :icon, String, description: 'Single emoji icon for the insight category'
    const :headline, String, description: 'Compelling headline that captures attention'
    const :narrative, String, description: 'Succinct explanation connecting data to meaning'
    const :sentiment, Sentiment, description: 'Overall sentiment of the insight'
    const :metrics, T::Array[MetricItem], default: [], description: 'Key metrics to display inline'
  end

  # The complete briefing output
  class BriefingOutput < T::Struct
    const :greeting, String, description: 'Personalized greeting for the user'
    const :status, StatusSummary, description: 'Consolidated status summary'
    const :suggestions, T::Array[Suggestion], default: [], description: 'Array of suggestions'
  end

  # =============================================================================
  # Editorial Briefing Types (What / So What / Now What framework)
  # =============================================================================

  # Anomaly types - contradictions and hidden patterns in the data
  class AnomalyType < T::Enum
    enums do
      SleepFitnessParadox = new('sleep_fitness_paradox')
      HRVPerformanceDivergence = new('hrv_performance_divergence')
      RecoveryDebt = new('recovery_debt')
      UnproductiveTraining = new('unproductive_training')
      TrendBreak = new('trend_break')
      ConsistencyGap = new('consistency_gap')
    end
  end

  # Severity of detected anomaly
  class AnomalySeverity < T::Enum
    enums do
      Low = new('low')
      Medium = new('medium')
      High = new('high')
    end
  end

  # An anomaly is a signal that contradicts expectations
  class Anomaly < T::Struct
    const :anomaly_type, AnomalyType
    const :severity, AnomalySeverity
    const :headline, String, description: 'Short description (5-10 words)'
    const :detail, String, description: 'What the data shows'
    const :implication, String, description: 'Why this matters'
    const :evidence, T::Array[EvidenceSpan], default: []
  end

  # The What/So What/Now What insight structure
  class EditorialInsight < T::Struct
    const :what, String,
      description: 'Observable fact from the data (1-2 sentences)'
    const :so_what, String,
      description: 'Why this matters—the interpretation (1-2 sentences)'
    const :now_what, String,
      description: 'Recommended action (1 sentence)'
  end

  # A metric that supports the insight
  class SupportingMetric < T::Struct
    const :label, String, description: 'Short label (e.g., "VO2 Max", "Sleep")'
    const :value, String, description: 'Formatted value (e.g., "51 ml/kg/min", "92/100")'
    const :trend, T.nilable(TrendDirection), default: nil
    const :context, T.nilable(String), default: nil,
      description: 'Optional context (e.g., "down from 53 last month")'
  end

  # The complete editorial briefing output
  class EditorialBriefingOutput < T::Struct
    const :headline, String,
      description: 'Compelling headline that reveals the hidden insight (8-12 words)'
    const :insight, EditorialInsight,
      description: 'The What/So What/Now What analysis'
    const :supporting_metrics, T::Array[SupportingMetric],
      default: [],
      description: 'Top 2-3 metrics that support the insight'
    const :tone, Sentiment,
      description: 'Overall tone of the briefing'
  end

  # =============================================================================
  # Narrative Context Types (pre-interpreted data for LLM input)
  # =============================================================================

  # Overall health pattern for the week
  class HealthPattern < T::Enum
    enums do
      Excellent = new('excellent')       # All metrics strong
      Recovering = new('recovering')     # Coming back from strain
      Strained = new('strained')         # Under stress, not recovering
      Inconsistent = new('inconsistent') # Day-to-day variation
      Declining = new('declining')       # Trend moving wrong direction
    end
  end

  # Pre-interpreted health narrative (output of context builder, input to LLM)
  class HealthNarrative < T::Struct
    const :pattern, HealthPattern,
      description: 'Overall 7-day health pattern'
    const :sleep_quality, String,
      description: 'Narrative interpretation of sleep (NO NUMBERS)'
    const :recovery_state, String,
      description: 'Narrative interpretation of HRV/body battery (NO NUMBERS)'
    const :stress_context, String,
      description: 'Narrative interpretation of stress levels (NO NUMBERS)'
    const :notable_observation, T.nilable(String), default: nil,
      description: 'One surprising or noteworthy pattern, if any'
  end

  # Training load pattern for the week
  class TrainingPattern < T::Enum
    enums do
      Building = new('building')           # Progressive overload
      Maintaining = new('maintaining')     # Steady state
      Tapering = new('tapering')           # Reducing load
      Overreaching = new('overreaching')   # Possibly too much
      Undertraining = new('undertraining') # Not enough stimulus
    end
  end

  # Pre-interpreted activity narrative
  class ActivityNarrative < T::Struct
    const :pattern, TrainingPattern,
      description: 'Overall 7-day training pattern'
    const :volume_description, String,
      description: 'Narrative interpretation of training volume (NO NUMBERS)'
    const :intensity_description, String,
      description: 'Narrative interpretation of intensity (NO NUMBERS)'
    const :consistency_description, String,
      description: 'How regular/consistent training has been (NO NUMBERS)'
  end

  # Fitness trajectory over time
  class FitnessTrajectory < T::Enum
    enums do
      Improving = new('improving')
      Stable = new('stable')
      Plateauing = new('plateauing')
      Declining = new('declining')
    end
  end

  # Pre-interpreted performance narrative
  class PerformanceNarrative < T::Struct
    const :trajectory, FitnessTrajectory,
      description: 'Overall fitness trend direction'
    const :aerobic_state, String,
      description: 'Narrative interpretation of VO2 Max / aerobic fitness'
    const :training_readiness, String,
      description: 'How ready the body is for training'
    const :outlook, String,
      description: 'Short-term fitness outlook'
  end

  # Detected pattern (narrative version of anomaly for LLM input)
  class DetectedPattern < T::Struct
    const :pattern_type, AnomalyType
    const :severity, AnomalySeverity
    const :narrative, String,
      description: 'Plain-English description of the pattern (NO NUMBERS)'
    const :implication, String,
      description: 'What this means for the user'
  end

  # Updated insight struct with explicit no-numbers constraint
  class NarrativeInsight < T::Struct
    const :what, String,
      description: 'Observable pattern (1-2 sentences, NO NUMBERS - describe qualitatively)'
    const :so_what, String,
      description: 'Why this matters (1-2 sentences, interpret meaning, NO NUMBERS)'
    const :now_what, String,
      description: 'One actionable recommendation (NO NUMBERS)'
  end

  # Output for narrative editorial briefing
  class NarrativeEditorialOutput < T::Struct
    const :headline, String,
      description: 'Compelling headline revealing the insight (8-12 words, NO NUMBERS)'
    const :insight, NarrativeInsight,
      description: 'The What/So What/Now What analysis (all prose, NO NUMBERS)'
    const :supporting_metrics, T::Array[SupportingMetric],
      description: 'The 2-3 key numbers that support your narrative (numbers go HERE)'
    const :tone, Sentiment
  end
end
