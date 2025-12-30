# typed: strict
# frozen_string_literal: true

module A2UI
  class Action < T::Struct
    const :name, String, description: 'Action identifier sent to server'
    const :context, T::Array[ContextBinding], default: []
  end
end
