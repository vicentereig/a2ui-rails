# typed: strict
# frozen_string_literal: true

module A2UI
  class CardComponent < T::Struct
    const :id, String
    const :child_id, String, description: 'ID of the child component'
    const :title, String, default: ''
    const :elevation, Integer, default: 1
  end
end
