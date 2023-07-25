# frozen_string_literal: true

module Icalendar
  module Values
    class Text < Value
      def initialize(value, params = {})
        value = value.gsub('\n', "\n")
        value.gsub!('\,', ',')
        value.gsub!('\;', ';')
        value.gsub!('\\\\') { '\\' }
        super value, params
      end

      VALUE_ICAL_CARRIAGE_RETURN_GSUB_REGEX = /\r?\n/.freeze

      def value_ical
        value.dup.tap do |v|
          v.gsub!('\\') { '\\\\' }
          v.gsub!(';', '\;')
          v.gsub!(',', '\,')
          v.gsub!(VALUE_ICAL_CARRIAGE_RETURN_GSUB_REGEX, '\n')
        end
      end
    end
  end
end
