# typed: strict
# frozen_string_literal: true

module A2UI
  # Coerces JSON/Hash values to typed T::Struct instances.
  # Uses DSPy's TypeCoercion under the hood.
  #
  # Example:
  #   class BookingContext < T::Struct
  #     const :guests, Integer
  #     const :date, String
  #   end
  #
  #   # HTTP params come as strings
  #   params[:context] # => { "guests" => "3", "date" => "2025-01-15" }
  #
  #   # Coerce to typed struct
  #   context = A2UI::TypeCoercion.coerce(params[:context], BookingContext)
  #   # => BookingContext.new(guests: 3, date: "2025-01-15")
  #
  module TypeCoercion
    extend T::Sig

    class Coercer
      include DSPy::Mixins::TypeCoercion

      extend T::Sig

      sig { params(value: T.untyped, type: T.untyped).returns(T.untyped) }
      def coerce(value, type)
        coerce_value_to_type(value, type)
      end
    end

    COERCER = T.let(Coercer.new, Coercer)

    sig { params(value: T.untyped, type: T.untyped).returns(T.untyped) }
    def self.coerce(value, type)
      COERCER.coerce(value, type)
    end
  end
end
