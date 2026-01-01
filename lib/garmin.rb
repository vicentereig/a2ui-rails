# typed: strict
# frozen_string_literal: true

require 'duckdb'

module Garmin
  class Error < StandardError; end
  class ConnectionError < Error; end
end

require_relative 'garmin/connection'
require_relative 'garmin/models'
require_relative 'garmin/queries'
require_relative 'garmin/signals'
