module Icalendar
  module Values
    module ParsableDates
      def parsing(value, format, &block)
        yield ::DateTime.strptime(value, format)
      rescue ArgumentError => e
        raise FormatError.new("Failed to parse \"#{value}\" - #{e.message}")
      end

      class FormatError < ArgumentError
      end
    end
  end
end
