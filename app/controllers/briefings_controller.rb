# typed: false
# frozen_string_literal: true

class BriefingsController < ApplicationController
  def show
    @user_id = params[:id] || 'demo_user'
    @user_name = 'Vicente'
    @date = Date.today.iso8601
  end

  def generate
    user_id = params[:id] || 'demo_user'
    date = params[:date] || Date.today.iso8601

    GenerateBriefingJob.perform_later(user_id: user_id, date: date)

    head :accepted
  end
end
