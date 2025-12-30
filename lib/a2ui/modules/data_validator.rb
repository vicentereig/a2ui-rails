# typed: strict
# frozen_string_literal: true

module A2UI
  class DataValidator < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::Predict.new(ValidateData)
    end

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward(**input_values)
      @predictor.call(
        data: input_values.fetch(:data),
        rules: input_values.fetch(:rules)
      )
    end
  end
end
