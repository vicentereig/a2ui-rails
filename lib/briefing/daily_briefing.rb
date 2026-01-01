# typed: strict
# frozen_string_literal: true

module Briefing
  # Signature for generating a daily health briefing
  class DailyBriefing < DSPy::Signature
    description 'Generate a concise daily health briefing. Keep all text SHORT: headlines max 5 words, narratives max 1 sentence, suggestions max 1 sentence. Use metrics array to show key numbers instead of mentioning them in narrative.'

    input do
      const :user_name, String, description: 'Name of the user for personalization'
      const :date, String, description: 'Date of the briefing (YYYY-MM-DD)'
      const :health_context, String, description: 'Summary of sleep, HRV, stress, and recovery data'
      const :activity_context, String, description: 'Summary of recent activities and training'
      const :performance_context, String, description: 'Summary of fitness metrics and training status'
    end

    output do
      const :greeting, String, description: 'Personalized greeting for the user'
      const :insights, T::Array[InsightBlock], description: 'Array of insight blocks about health/fitness'
      const :suggestions, T::Array[Suggestion], description: 'Array of actionable suggestions'
    end
  end

  # Module that generates daily briefings using ChainOfThought
  class DailyBriefingGenerator < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(DailyBriefing)
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
  end
end
