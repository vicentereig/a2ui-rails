# typed: strict
# frozen_string_literal: true

module A2UI
  class ExplicitChildren < T::Struct
    const :ids, T::Array[String], description: 'List of child component IDs'
  end
end
