# typed: strict
# frozen_string_literal: true

module A2UI
  class ActionHandler < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(HandleAction)
    end

    sig do
      params(input_values: T.untyped).returns(T.untyped)
    end
    def forward(**input_values)
      @predictor.call(
        action: input_values.fetch(:action),
        current_data: input_values.fetch(:current_data, '{}'),
        business_rules: input_values.fetch(:business_rules, '')
      )
    end
  end
end
