# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :a2ui do
    resources :surfaces, only: [:create, :show, :update, :destroy]
    resources :actions, only: [:create]
  end

  # Briefing demo
  resources :briefings, only: [:show] do
    member do
      post :generate
    end
  end

  # Root route - redirect to demo briefing
  root to: redirect('/briefings/demo')

  # Mount ActionCable
  mount ActionCable.server => '/cable'
end
