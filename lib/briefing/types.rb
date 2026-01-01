# typed: strict
# frozen_string_literal: true

module Briefing
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
  end

  # A suggestion or recommendation
  class Suggestion < T::Struct
    const :title, String, description: 'Pithy action title (3-5 words)'
    const :body, String, description: 'One sentence with specific action'
    const :suggestion_type, SuggestionType, description: 'Category of suggestion'
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
end
