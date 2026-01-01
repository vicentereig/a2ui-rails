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

    sig { params(input_values: T.untyped).returns(T.untyped) }
    def forward_untyped(**input_values)
      @predictor.call(
        components: input_values.fetch(:components),
        root_id: input_values.fetch(:root_id),
        screen: input_values.fetch(:screen)
      )
    end
  end
end
