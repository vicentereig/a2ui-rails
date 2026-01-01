# typed: strict
# frozen_string_literal: true

module A2UI
  class TabsComponent < T::Struct
    const :id, String
    const :tabs, T::Array[TabItem], description: 'List of tab definitions with labels and content IDs'
    const :active_index, Integer, default: 0, description: 'Currently active tab index (0-based)'
  end
end
