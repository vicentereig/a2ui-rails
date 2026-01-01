# typed: strict
# frozen_string_literal: true

module UserActivity
  class Error < StandardError; end
end

require_relative 'user_activity/signals'
