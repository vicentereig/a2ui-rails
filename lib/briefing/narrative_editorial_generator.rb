# typed: strict
# frozen_string_literal: true

module Briefing
  # Generator for narrative editorial briefings
  # Uses structured narrative input types instead of raw string summaries
  class NarrativeEditorialGenerator < DSPy::Module
    extend T::Sig

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :token_usage

    around :track_tokens

    sig { void }
    def initialize
      super
      @predictor = T.let(
        DSPy::ChainOfThought.new(NarrativeEditorialBriefing),
        DSPy::ChainOfThought
      )
      @token_usage = T.let(
        { input_tokens: 0, output_tokens: 0, model: nil },
        T::Hash[Symbol, T.untyped]
      )
    end

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward_untyped(**input_values)
      @predictor.call(
        date: input_values.fetch(:date),
        health: input_values.fetch(:health),
        activity: input_values.fetch(:activity),
        performance: input_values.fetch(:performance),
        detected_patterns: input_values.fetch(:detected_patterns, [])
      )
    end

    private

    sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
    def track_tokens(*args, **kwargs, &block)
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
  end
end
