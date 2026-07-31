# frozen_string_literal: true

module Icalendar
  module Values
    class Text < Value
      UNESCAPE_GSUB_REGEX = /\\([\\,;nN])/.freeze

      def initialize(value, *args)
        # One left-to-right pass keeps unescape the exact inverse of value_ical; \n and \N are newline.
        value = value.gsub(UNESCAPE_GSUB_REGEX) { |_| %w[n N].include?($1) ? "\n" : $1 }
        super value, *args
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
