# typed: strict
# frozen_string_literal: true

module A2UI
  class LayoutAdapter < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::Predict.new(AdaptLayout)
    end

    sig do
      params(input_values: T.untyped).returns(T.untyped)
    end
    def forward(**input_values)
      @predictor.call(
        components: input_values.fetch(:components),
        root_id: input_values.fetch(:root_id),
        screen: input_values.fetch(:screen)
      )
    end
  end
end
