# typed: strict
# frozen_string_literal: true

module A2UI
  class DataDrivenChildren < T::Struct
    const :path, String, description: 'JSON Pointer to array in data model'
    const :template_id, String, description: 'Component ID to use as template for each item'
  end
end
