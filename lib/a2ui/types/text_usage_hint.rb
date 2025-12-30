# typed: strict
# frozen_string_literal: true

module A2UI
  class TextUsageHint < T::Enum
    enums do
      H1 = new('h1')
      H2 = new('h2')
      H3 = new('h3')
      H4 = new('h4')
      H5 = new('h5')
      Body = new('body')
      Caption = new('caption')
    end
  end
end
