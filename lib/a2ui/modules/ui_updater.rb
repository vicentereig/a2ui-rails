# typed: strict
# frozen_string_literal: true

module A2UI
  class UIUpdater < DSPy::Module
    extend T::Sig

    sig { void }
    def initialize
      super
      @predictor = DSPy::ChainOfThought.new(UpdateUI)
    end

    sig do
      params(input_values: T.untyped).returns(T.untyped)
    end
    def forward(**input_values)
      @predictor.call(
        request: input_values.fetch(:request),
        surface_id: input_values.fetch(:surface_id),
        current_components: input_values.fetch(:current_components, []),
        current_data: input_values.fetch(:current_data, '{}')
      )
    end
  end
end
