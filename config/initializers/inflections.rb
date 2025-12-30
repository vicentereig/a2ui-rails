# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # A2UI should be loaded as A2UI, not A2ui
  inflect.acronym 'A2UI'
end
