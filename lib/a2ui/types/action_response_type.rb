# typed: strict
# frozen_string_literal: true

module A2UI
  class ActionResponseType < T::Enum
    enums do
      UpdateUI = new('update_ui')
      Navigate = new('navigate')
      DeleteSurface = new('delete_surface')
      NoOp = new('no_op')
    end
  end
end
