# typed: strict
# frozen_string_literal: true

module A2UI
  class UpdateUI < DSPy::Signature
    description 'Generate incremental Turbo Stream updates.'

    input do
      const :request, String, description: 'What to update'
      const :surface_id, String
      const :current_components, T::Array[Component], default: []
      const :current_data, String, default: '{}', description: 'Current data as JSON'
    end

    output do
      const :streams, T::Array[StreamOp], description: 'Turbo Stream operations'
      const :components, T::Array[Component], default: [], description: 'New/updated components'
      const :data_updates, T::Array[DataUpdate], default: []
    end
  end
end
