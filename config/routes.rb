# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :a2ui do
    resources :surfaces, only: [:create, :show, :update, :destroy]
    resources :actions, only: [:create]
  end

  # Briefing routes with date-based URLs
  get 'briefings/today', to: 'briefings#today', as: :briefings_today
  get ':year/:month/:day/briefings', to: 'briefings#show', as: :daily_briefing,
      constraints: { year: /\d{4}/, month: /\d{2}/, day: /\d{2}/ }
  post ':year/:month/:day/briefings/generate', to: 'briefings#generate', as: :generate_briefing,
       constraints: { year: /\d{4}/, month: /\d{2}/, day: /\d{2}/ }

  # Editorial briefing routes (What/So What/Now What style)
  get ':year/:month/:day/editorial', to: 'briefings#editorial', as: :editorial_briefing,
      constraints: { year: /\d{4}/, month: /\d{2}/, day: /\d{2}/ }
  post ':year/:month/:day/editorial/generate', to: 'briefings#generate_editorial', as: :generate_editorial_briefing,
       constraints: { year: /\d{4}/, month: /\d{2}/, day: /\d{2}/ }

  # Root route - redirect to today's briefing
  root to: redirect('/briefings/today')

  # Mount ActionCable
  mount ActionCable.server => '/cable'
end
