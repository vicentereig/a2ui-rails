# typed: strict
# frozen_string_literal: true

module A2UI
  class InputType < T::Enum
    enums do
      Text = new('text')
      Number = new('number')
      Date = new('date')
      Longtext = new('longtext')
      Email = new('email')
      Tel = new('tel')
      Url = new('url')
    end
  end
end
