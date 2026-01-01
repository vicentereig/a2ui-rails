# typed: strict
# frozen_string_literal: true

module A2UI
  class ModalSize < T::Enum
    enums do
      Small = new('small')
      Medium = new('medium')
      Large = new('large')
      FullScreen = new('fullscreen')
    end
  end
end
