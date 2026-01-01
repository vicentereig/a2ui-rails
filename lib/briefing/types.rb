# typed: strict
# frozen_string_literal: true

module Briefing
  # Sentiment for insight blocks
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

  # A single metric item (e.g., "7.5 hours", "52 ms HRV")
  class MetricItem < T::Struct
    const :label, String, description: 'Short label for the metric (e.g., "Sleep", "HRV", "Body Battery")'
    const :value, String, description: 'Value with unit (e.g., "7.5h", "52ms", "85%")'
    const :trend, T.nilable(TrendDirection), default: nil
  end

  # An insight block with narrative and optional metrics
  class InsightBlock < T::Struct
    const :icon, String, description: 'Single emoji icon for the insight category'
    const :headline, String, description: 'Punchy headline'
    const :narrative, String, description: 'Succinct explanation of the insight'
    const :sentiment, Sentiment, description: 'Overall sentiment of the insight'
    const :metrics, T::Array[MetricItem], default: [], description: 'Key metrics to display inline'
  end

  # A suggestion or recommendation
  class Suggestion < T::Struct
    const :title, String, description: 'Brief action-oriented title'
    const :body, String, description: 'Concise actionable advice'
    const :icon, String, default: '💡', description: 'Single emoji icon'
    const :suggestion_type, SuggestionType, description: 'Category of suggestion'
  end

  # The complete briefing output
  class BriefingOutput < T::Struct
    const :greeting, String, description: 'Personalized greeting for the user'
    const :insights, T::Array[InsightBlock], default: [], description: 'Array of insight blocks'
    const :suggestions, T::Array[Suggestion], default: [], description: 'Array of suggestions'
  end
end
