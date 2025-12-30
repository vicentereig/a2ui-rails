# typed: strict
# frozen_string_literal: true

module A2UI
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
end
