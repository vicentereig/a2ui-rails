# typed: false
# frozen_string_literal: true

module Briefing
  class BriefingComponent < ViewComponent::Base
    def initialize(name:, date:)
      @name = name
      @date = date
    end

    def greeting
      hour = Time.current.hour

      greeting_word = if hour < 12
                        'Good morning'
                      elsif hour < 17
                        'Good afternoon'
                      else
                        'Good evening'
                      end

      "#{greeting_word}, #{@name}"
    end

    def formatted_date
      @date.strftime('%A, %B %-d, %Y')
    end
  end
end
