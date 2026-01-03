# typed: false
# frozen_string_literal: true

class BriefingsController < ApplicationController
  def today
    redirect_to daily_briefing_path(date_params_for(Date.today))
  end

  def show
    @user_id = 'demo_user'
    @user_name = 'Vicente'
    @date = parse_date_from_params

    # Check if briefing exists for this date
    @briefing = BriefingRecord.find_by(
      user_id: @user_id,
      date: @date,
      briefing_type: 'daily'
    )

    # Navigation dates
    @prev_date = @date - 1.day
    @next_date = @date + 1.day
    @can_go_next = @date < Date.today
  end

  # Editorial-style briefing view
  def editorial
    @user_id = 'demo_user'
    @user_name = 'Vicente'
    @date = parse_date_from_params

    # Check if editorial briefing exists for this date
    @briefing = BriefingRecord.find_by(
      user_id: @user_id,
      date: @date,
      briefing_type: 'editorial'
    )

    # Navigation dates
    @prev_date = @date - 1.day
    @next_date = @date + 1.day
    @can_go_next = @date < Date.today
  end

  def generate
    user_id = 'demo_user'
    date = parse_date_from_params.iso8601

    GenerateBriefingJob.perform_later(user_id: user_id, date: date)

    head :accepted
  end

  def generate_editorial
    user_id = 'demo_user'
    date = parse_date_from_params.iso8601

    GenerateEditorialBriefingJob.perform_later(user_id: user_id, date: date)

    head :accepted
  end

  private

  def parse_date_from_params
    Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
  rescue ArgumentError, TypeError
    Date.today
  end

  def date_params_for(date)
    {
      year: date.strftime('%Y'),
      month: date.strftime('%m'),
      day: date.strftime('%d')
    }
  end

  helper_method :date_params_for
end
