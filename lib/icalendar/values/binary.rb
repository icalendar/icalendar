require 'base64'

module Icalendar
  module Values

    class Binary < Value

      def params_ical
        ical_param :value, 'BINARY'
        ical_param :encoding, 'BASE64'
        super
      end

      def value_ical
        if base64?
          value
        else
          Base64.strict_encode64 value
        end
      end

      private

      BASE_64_REGEX = /\A(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{4}|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{2}==)\z/.freeze

      def base64?
        value.is_a?(String) &&
            value =~ BASE_64_REGEX
      end
    end

  end
end