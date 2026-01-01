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

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward_untyped(**input_values)
      @predictor.call(
        action: input_values.fetch(:action),
        current_data: input_values.fetch(:current_data, '{}'),
        business_rules: input_values.fetch(:business_rules, '')
      )
    end
  end
end
