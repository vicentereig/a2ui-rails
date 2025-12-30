# typed: strict
# frozen_string_literal: true

module A2UI
  class StreamAction < T::Enum
    enums do
      Append = new('append')
      Prepend = new('prepend')
      Replace = new('replace')
      Update = new('update')
      Remove = new('remove')
      Before = new('before')
      After = new('after')
    end
  end
end
