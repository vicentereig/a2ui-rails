# typed: false
# frozen_string_literal: true

class BriefingRecord < ApplicationRecord
  self.table_name = 'briefings'

  # Associations for hierarchical briefings
  belongs_to :parent, class_name: 'BriefingRecord', optional: true
  has_many :children, class_name: 'BriefingRecord', foreign_key: :parent_id, dependent: :nullify

  # Validations
  validates :user_id, presence: true
  validates :date, presence: true
  validates :briefing_type, presence: true, inclusion: { in: %w[daily weekly editorial] }
  validates :user_id, uniqueness: { scope: [:date, :briefing_type] }

  # Scopes
  scope :daily, -> { where(briefing_type: 'daily') }
  scope :weekly, -> { where(briefing_type: 'weekly') }
  scope :editorial, -> { where(briefing_type: 'editorial') }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_date, ->(date) { where(date: date) }
  scope :recent, -> { order(date: :desc) }

  # Find or create a briefing for a specific user and date
  def self.find_or_initialize_for(user_id:, date:, briefing_type: 'daily')
    find_or_initialize_by(
      user_id: user_id,
      date: date,
      briefing_type: briefing_type
    )
  end

  # Check if this briefing has been generated
  def generated?
    generated_at.present? && output.present?
  end

  # Total tokens used
  def total_tokens
    (input_tokens || 0) + (output_tokens || 0)
  end

  # Get the week this daily briefing belongs to
  def week_start
    date.beginning_of_week(:monday)
  end

  # Find the weekly rollup for this daily briefing
  def weekly_briefing
    return nil unless briefing_type == 'daily'

    BriefingRecord.weekly.for_user(user_id).for_date(week_start).first
  end

  # Get all daily briefings for a week
  def daily_briefings
    return BriefingRecord.none unless briefing_type == 'weekly'

    children.daily.order(:date)
  end

  # Serialize output for broadcasting
  def output_for_broadcast
    return {} unless output.present?

    output.deep_symbolize_keys
  end
end
