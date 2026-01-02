# typed: strict
# frozen_string_literal: true

module Briefing
  # Summary of a single day for weekly input
  class DailySummary < T::Struct
    const :date, String, description: 'Date (YYYY-MM-DD)'
    const :headline, String, description: 'The day status headline'
    const :sentiment, String, description: 'positive, neutral, or warning'
    const :key_metrics, String, description: 'Comma-separated key metrics (e.g., "Sleep: 7.5h, HRV: 52ms")'
  end

  # Weekly trend for a specific metric
  class WeeklyTrend < T::Struct
    const :metric, String, description: 'Metric name (e.g., "Sleep", "HRV", "Training Load")'
    const :direction, TrendDirection, description: 'Overall trend direction for the week'
    const :summary, String, description: 'One sentence describing the trend'
  end

  # Weekly status summary - higher level than daily
  class WeeklyStatusSummary < T::Struct
    const :headline, String, description: 'Week-level headline (3-5 words)'
    const :summary, String, description: '2-3 sentences summarizing the week patterns'
    const :sentiment, Sentiment, description: 'Overall week sentiment'
    const :trends, T::Array[WeeklyTrend], default: [], description: 'Top 3 metric trends for the week'
  end

  # Weekly suggestion - more strategic than daily
  class WeeklySuggestion < T::Struct
    const :title, String, description: 'Strategic action title (3-5 words)'
    const :body, String, description: 'One sentence with specific weekly focus'
    const :priority, Integer, description: '1-3 priority ranking'
  end

  # Complete weekly briefing output
  class WeeklyBriefingOutput < T::Struct
    const :week_range, String, description: 'Week range (e.g., "Dec 23-29, 2025")'
    const :status, WeeklyStatusSummary, description: 'Consolidated weekly status'
    const :suggestions, T::Array[WeeklySuggestion], default: [], description: 'Top 3 strategic suggestions'
  end

  # Signature for generating a weekly health briefing from daily summaries
  class WeeklyBriefing < DSPy::Signature
    description 'Generate a weekly health briefing summarizing patterns across multiple days.'

    input do
      const :user_name, String, description: 'Name of the user'
      const :week_start, String, description: 'Start of week (YYYY-MM-DD)'
      const :week_end, String, description: 'End of week (YYYY-MM-DD)'
      const :daily_summaries, T::Array[DailySummary], description: 'Summaries from each day'
    end

    output do
      const :week_range, String, description: 'Formatted week range'
      const :status, WeeklyStatusSummary, description: 'Weekly status summary with trends'
      const :suggestions, T::Array[WeeklySuggestion], description: 'Top 3 strategic suggestions'
    end
  end

  # Module that generates weekly briefings from daily summaries
  # Tracks token usage via lifecycle callbacks
  class WeeklyBriefingGenerator < DSPy::Module
    extend T::Sig

    # Token usage accumulated during forward
    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :token_usage

    around :track_tokens

    sig { void }
    def initialize
      super
      @predictor = T.let(DSPy::ChainOfThought.new(WeeklyBriefing), DSPy::ChainOfThought)
      @token_usage = T.let({ input_tokens: 0, output_tokens: 0, model: nil }, T::Hash[Symbol, T.untyped])
    end

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward_untyped(**input_values)
      @predictor.call(
        user_name: input_values.fetch(:user_name),
        week_start: input_values.fetch(:week_start),
        week_end: input_values.fetch(:week_end),
        daily_summaries: input_values.fetch(:daily_summaries)
      )
    end

    private

    sig { returns(T.untyped) }
    def track_tokens
      @token_usage = { input_tokens: 0, output_tokens: 0, model: nil }

      subscription_id = DSPy.events.subscribe('lm.tokens') do |_event_name, attrs|
        @token_usage[:input_tokens] += attrs[:input_tokens] || 0
        @token_usage[:output_tokens] += attrs[:output_tokens] || 0
        @token_usage[:model] ||= attrs['gen_ai.request.model']
      end

      begin
        yield
      ensure
        DSPy.events.unsubscribe(subscription_id) if subscription_id
      end
    end

    # Build daily summaries from BriefingRecord entries
    # @param records [Array<BriefingRecord>] Daily briefing records
    # @return [Array<DailySummary>] Summaries for weekly input
    sig { params(records: T::Array[T.untyped]).returns(T::Array[DailySummary]) }
    def self.build_daily_summaries(records)
      records.map do |record|
        output = record.output&.deep_symbolize_keys || {}
        status = output[:status] || {}
        metrics = (status[:metrics] || []).map { |m| "#{m[:label]}: #{m[:value]}" }.join(', ')

        DailySummary.new(
          date: record.date.iso8601,
          headline: status[:headline] || 'No data',
          sentiment: status[:sentiment]&.to_s || 'neutral',
          key_metrics: metrics.presence || 'No metrics'
        )
      end
    end
  end
end
