# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :a2ui do
    resources :surfaces, only: [:create, :show, :update, :destroy]
    resources :actions, only: [:create]
  end

  # Mount ActionCable
  mount ActionCable.server => '/cable'
end
