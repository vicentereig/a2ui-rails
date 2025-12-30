# typed: strict
# frozen_string_literal: true

require 'dspy'
require_relative 'types'

module A2UI
  # =============================================================================
  # SIGNATURE: GENERATE UI
  # =============================================================================

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
    end
  end

  # =============================================================================
  # SIGNATURE: UPDATE UI
  # =============================================================================

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

  # =============================================================================
  # SIGNATURE: HANDLE ACTION
  # =============================================================================

  class HandleAction < DSPy::Signature
    description 'Process user action and generate response.'

    input do
      const :action, UserAction
      const :current_data, String, default: '{}', description: 'Surface data as JSON'
      const :business_rules, String, default: '', description: 'Domain constraints'
    end

    output do
      const :response_type, ActionResponseType
      const :streams, T::Array[StreamOp], default: []
      const :components, T::Array[Component], default: []
      const :data_updates, T::Array[DataUpdate], default: []
      const :redirect_url, String, default: '', description: 'URL if navigating'
      const :message, String, default: '', description: 'User-facing message'
    end
  end

  # =============================================================================
  # SIGNATURE: VALIDATE DATA
  # =============================================================================

  class ValidateData < DSPy::Signature
    description 'Validate data model against rules.'

    input do
      const :data, String, description: 'Data model as JSON'
      const :rules, String, description: 'Validation rules'
    end

    output do
      const :valid, T::Boolean
      const :issues, T::Array[ValidationIssue], default: []
    end
  end

  # =============================================================================
  # SIGNATURE: PARSE NATURAL INPUT
  # =============================================================================

  class ParseInput < DSPy::Signature
    description 'Convert natural language to data updates.'

    input do
      const :text, String, description: 'User natural language input'
      const :target_path, String, description: 'Path to update'
      const :expected_schema, String, default: '', description: 'Expected structure hint'
    end

    output do
      const :updates, T::Array[DataUpdate]
      const :confidence, Float, description: '0.0-1.0 confidence score'
      const :needs_clarification, T::Boolean
      const :question, String, default: '', description: 'Clarification question if needed'
    end
  end

  # =============================================================================
  # SIGNATURE: ADAPT LAYOUT
  # =============================================================================

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
