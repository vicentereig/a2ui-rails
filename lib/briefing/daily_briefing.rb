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
