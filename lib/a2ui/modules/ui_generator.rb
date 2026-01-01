# typed: strict
# frozen_string_literal: true

module A2UI
  class UIGenerator < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(GenerateUI)
    end

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward_untyped(**input_values)
      @predictor.call(
        request: input_values.fetch(:request),
        surface_id: input_values.fetch(:surface_id),
        available_data: input_values.fetch(:available_data, '{}')
      )
    end
  end
end
