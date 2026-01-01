# typed: false
# frozen_string_literal: true

class BriefingsController < ApplicationController
  def show
    @user_id = params[:id] || 'demo_user'
    @user_name = 'Vicente'
    @date = parse_date(params[:date])

    # Check if briefing exists for this date
    @briefing = BriefingRecord.find_by(
      user_id: @user_id,
      date: @date,
      briefing_type: 'daily'
    )

    # Navigation dates
    @prev_date = (@date - 1.day).iso8601
    @next_date = (@date + 1.day).iso8601
    @can_go_next = @date < Date.today
  end

  def generate
    user_id = params[:id] || 'demo_user'
    date = params[:date] || Date.today.iso8601

    GenerateBriefingJob.perform_later(user_id: user_id, date: date)

    head :accepted
  end

  private

  def parse_date(date_param)
    return Date.today unless date_param.present?

    Date.parse(date_param)
  rescue ArgumentError
    Date.today
  end
end
