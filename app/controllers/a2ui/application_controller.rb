# typed: strict
# frozen_string_literal: true

module A2UI
  class ApplicationController < ActionController::Base
    extend T::Sig

    protect_from_forgery with: :exception

    private

    sig { returns(SurfaceManager) }
    def surface_manager
      @surface_manager ||= T.let(
        SurfaceManager.for(scope: surface_scope),
        T.nilable(SurfaceManager)
      )
      T.must(@surface_manager)
    end

    sig { returns(String) }
    def surface_scope
      session.id.to_s
    end
  end
end
