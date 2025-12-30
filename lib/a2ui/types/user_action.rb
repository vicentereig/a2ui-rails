# typed: strict
# frozen_string_literal: true

module A2UI
  class UserAction < T::Struct
    const :name, String, description: 'Action name from component'
    const :surface_id, String
    const :source_id, String, description: 'Component ID that triggered action'
    const :context, T::Hash[String, String], default: {}, description: 'Resolved context values'
  end
end
