# typed: false
# frozen_string_literal: true

module Briefing
  class SuggestionComponent < ViewComponent::Base
    SUGGESTION_TYPES = %i[general recovery intensity].freeze

    def initialize(title:, body:, icon: '💡', suggestion_type: :general)
      @title = title
      @body = body
      @icon = icon
      @suggestion_type = SUGGESTION_TYPES.include?(suggestion_type) ? suggestion_type : :general
    end

    attr_reader :title, :body, :icon, :suggestion_type
  end
end
