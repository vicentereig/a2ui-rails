# typed: strict
# frozen_string_literal: true

module Briefing
  # Signature for generating a daily health briefing
  class DailyBriefing < DSPy::Signature
    description 'Generate a concise daily health briefing from metrics.'

    input do
      const :user_name, String, description: 'Name of the user'
      const :date, String, description: 'Date (YYYY-MM-DD)'
      const :health_context, String, description: 'Sleep, HRV, stress, recovery data'
      const :activity_context, String, description: 'Recent activities and training'
      const :performance_context, String, description: 'Fitness metrics and training status'
    end

    output do
      const :greeting, String, description: 'Brief personalized greeting'
      const :status, StatusSummary, description: 'Single consolidated status block'
      const :suggestions, T::Array[Suggestion], description: 'Top 2 most actionable suggestions'
    end
  end

  # Module that generates daily briefings using ChainOfThought
  # Tracks token usage via lifecycle callbacks
  class DailyBriefingGenerator < DSPy::Module
    extend T::Sig

    # Token usage accumulated during forward
    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :token_usage

    around :track_tokens

    sig { void }
    def initialize
      super
      @predictor = T.let(DSPy::ChainOfThought.new(DailyBriefing), DSPy::ChainOfThought)
      @token_usage = T.let({ input_tokens: 0, output_tokens: 0, model: nil }, T::Hash[Symbol, T.untyped])
    end

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward_untyped(**input_values)
      @predictor.call(
        user_name: input_values.fetch(:user_name),
        date: input_values.fetch(:date),
        health_context: input_values.fetch(:health_context),
        activity_context: input_values.fetch(:activity_context),
        performance_context: input_values.fetch(:performance_context)
      )
    end

    private

    sig { returns(T.untyped) }
    def track_tokens
      # Reset for this call
      @token_usage = { input_tokens: 0, output_tokens: 0, model: nil }

      # Subscribe to token events during execution
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
  end
end
