# typed: strict
# frozen_string_literal: true

module A2UI
  class GenerateUI < DSPy::Signature
    description 'Generate UI components from natural language.'

    input do
      const :request, String, description: 'What UI to create'
      const :surface_id, String
      const :available_data, String, default: '{}', description: 'Available data model as JSON'
    end

    output do
      const :root_id, String, description: 'Root component ID'
      const :components, T::Array[Component], description: 'Component adjacency list'
      const :initial_data, T::Array[DataUpdate], default: [], description: 'Initial data values'
      const :decisions, T::Array[UIDecisionEvidence], default: [], description: 'Reasoning behind UI choices'
    end
  end
end
