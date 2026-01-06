# typed: strict
# frozen_string_literal: true

module A2UI
  # Empty data struct for surfaces that don't need initial data.
  # Usage: manager.create(surface_id: 'demo', request: '...', data: EmptyData.new)
  class EmptyData < T::Struct
  end
end
