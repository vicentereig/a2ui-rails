# typed: strict
# frozen_string_literal: true

module A2UI
  # Editorial metrics row component - renders with .editorial-metrics styling
  # Container for 2-3 EditorialMetricComponents in a horizontal layout
  class EditorialMetricsRowComponent < T::Struct
    const :id, String
    const :children, Children, description: 'ExplicitChildren with EditorialMetricComponent IDs'
  end
end
