# typed: strict
# frozen_string_literal: true

module A2UI
  class PathReference < T::Struct
    const :path, String, description: 'JSON Pointer to data model (e.g., /user/name)'
  end
end
