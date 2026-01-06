# typed: strict
# frozen_string_literal: true

module A2UI
  # Wraps raw JSON data from HTTP params.
  # Usage: manager.create(..., data: JsonData.new(json: params[:data]))
  class JsonData < T::Struct
    extend T::Sig

    const :json, String, default: '{}'

    sig { returns(T::Hash[String, T.untyped]) }
    def serialize
      JSON.parse(json)
    end
  end
end
