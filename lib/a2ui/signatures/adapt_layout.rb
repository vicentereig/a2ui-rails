# typed: strict
# frozen_string_literal: true

module A2UI
  class AdaptLayout < DSPy::Signature
    description 'Adapt components for screen size.'

    input do
      const :components, T::Array[Component]
      const :root_id, String
      const :screen, ScreenSize
    end

    output do
      const :components, T::Array[Component], description: 'Adapted components'
      const :hidden_ids, T::Array[String], default: [], description: 'IDs to hide'
    end
  end
end
