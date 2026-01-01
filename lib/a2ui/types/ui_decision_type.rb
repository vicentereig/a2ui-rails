# typed: strict
# frozen_string_literal: true

module A2UI
  # Category of UI decision being made
  class UIDecisionType < T::Enum
    enums do
      ComponentChoice = new('component_choice')
      LayoutStructure = new('layout_structure')
      DataBinding = new('data_binding')
      Styling = new('styling')
      Interaction = new('interaction')
    end
  end
end
