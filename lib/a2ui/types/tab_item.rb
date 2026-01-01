# typed: strict
# frozen_string_literal: true

module A2UI
  # A single tab definition
  class TabItem < T::Struct
    const :label, String, description: 'Tab label text'
    const :child_id, String, description: 'ID of the content component for this tab'
  end
end
