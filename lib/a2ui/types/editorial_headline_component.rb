# typed: strict
# frozen_string_literal: true

module A2UI
  # Editorial headline component - renders with .editorial-headline styling
  # Main headline for editorial briefings with serif font
  class EditorialHeadlineComponent < T::Struct
    const :id, String
    const :content, Value, description: 'Headline text (8-12 words, no numbers)'
  end
end
