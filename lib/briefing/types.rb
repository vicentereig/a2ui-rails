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
    const :label, String, description: 'The numeric or text value (e.g., "7.5", "52")'
    const :value, String, description: 'The unit or description (e.g., "hours", "ms HRV")'
    const :trend, T.nilable(Symbol), default: nil # :up, :down, :stable
  end

  # An insight block with narrative and optional metrics
  class InsightBlock < T::Struct
    const :icon, String, description: 'Emoji icon representing the insight category'
    const :headline, String, description: 'Short headline summarizing the insight'
    const :narrative, String, description: 'Coach-style narrative explanation'
    const :sentiment, Sentiment, description: 'Overall sentiment of the insight'
    const :metrics, T::Array[MetricItem], default: [], description: 'Optional inline metrics'
  end

  # A suggestion or recommendation
  class Suggestion < T::Struct
    const :title, String, description: 'Short title for the suggestion'
    const :body, String, description: 'Detailed suggestion text'
    const :icon, String, default: '💡', description: 'Emoji icon for the suggestion'
    const :suggestion_type, SuggestionType, description: 'Category of suggestion'
  end

  # The complete briefing output
  class BriefingOutput < T::Struct
    const :greeting, String, description: 'Personalized greeting for the user'
    const :insights, T::Array[InsightBlock], default: [], description: 'Array of insight blocks'
    const :suggestions, T::Array[Suggestion], default: [], description: 'Array of suggestions'
  end
end
