# typed: strict
# frozen_string_literal: true

module A2UI
  class UserAction < T::Struct
    const :name, String, description: 'Action name from component'
    const :surface_id, String
    const :source_id, String, description: 'Component ID that triggered action'
    const :context, T::Hash[String, T.untyped], default: {}, description: 'Raw context from client, coerced by Surface'
  end
end
