# typed: strict
# frozen_string_literal: true

module A2UI
  class DataUpdate < T::Struct
    const :path, String, description: 'JSON Pointer path (e.g., /reservation/guests)'
    const :entries, T::Array[DataValue], description: 'Values to set at this path'
  end
end
