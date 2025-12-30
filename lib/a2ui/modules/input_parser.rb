# typed: strict
# frozen_string_literal: true

module A2UI
  class InputParser < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::Predict.new(ParseInput)
    end

    sig do
      params(input_values: T.untyped).returns(T.untyped)
    end
    def forward(**input_values)
      @predictor.call(
        text: input_values.fetch(:text),
        target_path: input_values.fetch(:target_path),
        expected_schema: input_values.fetch(:expected_schema, '')
      )
    end
  end
end
